#!/bin/bash
# it-guy-pro profile linter — mechanical half of /it-guy-pro:profile review.
#
# Checks ~/ITGuy state against the machine-profile schema. Everything here
# is a rule that was previously prose-only, meaning nothing enforced it.
#
# Usage:  bash lint-profile.sh [ITGuy-dir]     (default: ~/ITGuy)
# Output: one finding per line — SEVERITY|rule|location|message
# Exit:   0 clean · 1 findings · 2 no profile to check
#
# Bash only, no python/jq: this runs on a non-technical user's Mac where
# invoking python3 can trigger an Xcode Command Line Tools install prompt.

ROOT="${1:-$HOME/ITGuy}"
PROFILE="$ROOT/machine.md"
HISTORY="$ROOT/history.md"
LEDGER="$ROOT/ledger.jsonl"
TODAY="$(date +%Y-%m-%d)"
YEAR_AGO="$(date -v-1y +%Y-%m-%d 2>/dev/null || date -d '1 year ago' +%Y-%m-%d)"
DAYS60="$(date -v-60d +%Y-%m-%d 2>/dev/null || date -d '60 days ago' +%Y-%m-%d)"
DAYS180="$(date -v-180d +%Y-%m-%d 2>/dev/null || date -d '180 days ago' +%Y-%m-%d)"
# Finding count lives in a file, not a variable. Several checks emit from
# inside `while read` loops fed by pipes, which bash runs in a SUBSHELL —
# a variable incremented there never reaches the parent, so the script
# would print CRITICAL findings and still exit 0. That silent, selective
# failure hit exactly the six secret-detection rules: a profile holding a
# VPN share link reported "clean" to any caller branching on exit code.
COUNT="$(mktemp -t itg-lint)"
TMPOUT="$(mktemp -t itg-lint-out)"
trap 'rm -f "$COUNT" "$TMPOUT"' EXIT
printf '0' > "$COUNT"

bump() { printf 'x' >> "$COUNT"; }
findings() { c=$(wc -c < "$COUNT" | tr -d ' '); echo $((c - 1)); }

say() { printf '%s|%s|%s|%s\n' "$1" "$2" "$3" "$4"; bump; }

[ -f "$PROFILE" ] || { echo "INFO|no-profile|$PROFILE|No profile yet — run /it-guy-pro:onboard"; rm -f "$COUNT" "$TMPOUT"; exit 2; }
# Unverifiable is not the same as fine. Without this the awk passes fail, the
# comparisons error, and the script exits 0 on a profile it never read.
[ -r "$PROFILE" ] || { echo "ERROR|unreadable|machine.md|Profile exists but cannot be read, so nothing below was actually checked"; rm -f "$COUNT" "$TMPOUT"; exit 1; }
[ -L "$PROFILE" ] && echo "WARN|symlinked-profile|machine.md|Profile is a symlink; confirm it points where you expect" && bump

# ---------- Secrets that must never be stored (highest severity) ----------
# The schema forbids these; until now nothing verified it. Scans history too,
# since demotion moves text rather than sanitising it.
scan_secrets() {
  local f="$1" label="$2"
  [ -f "$f" ] || return 0
  grep -nE '(^|[^0-9])(192\.168\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say CRITICAL private-ip "$label:$ln" "Private IP address stored — remove it and redact from history"; done
  grep -nE '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say CRITICAL mac-address "$label:$ln" "MAC address stored — identifies hardware, remove it"; done
  grep -nE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say CRITICAL uuid "$label:$ln" "UUID stored — likely a connection credential, remove it"; done
  grep -nE '(vless|vmess|trojan|ss|ssh)://|BEGIN (OPENSSH|RSA|EC) PRIVATE KEY' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say CRITICAL credential "$label:$ln" "Connection link or private key stored — remove and rotate it"; done
  grep -niE '(password|passphrase|psk|secret|serial number)[[:space:]]*[:=][[:space:]]*[^[:space:]<]' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say CRITICAL secret-value "$label:$ln" "A secret appears to have a value assigned — remove it"; done
  grep -nE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$f" 2>/dev/null \
    | while IFS=: read -r ln _; do say WARN email "$label:$ln" "Email address stored — the schema forbids account identifiers"; done
}
scan_secrets "$PROFILE" "machine.md"
scan_secrets "$HISTORY" "history.md"

# ---------- Provenance: every fact bullet must say how it was learned ----
# Only the sections that hold facts; Watch List and prose lists are exempt.
awk -v today="$TODAY" '
  /^## / { sec=substr($0,4); next }
  sec ~ /^(Hardware|System|Owner|Conventions|Live Conclusions)$/ && /^- / {
    if ($0 !~ /\((measured|observed|you told me|concluded)[^)]*\)/)
      printf "WARN|untagged|machine.md:%d|Fact has no provenance tag (measured/observed/you told me/concluded) so it can never be retired\n", NR
  }
' "$PROFILE" > "$TMPOUT"
while IFS= read -r l; do [ -n "$l" ] && { echo "$l"; bump; }; done < "$TMPOUT"

# ---------- Conclusions: retest date and retest method are mandatory -----
awk '
  /\(concluded/ {
    if ($0 !~ /retest by [0-9]{4}-[0-9]{2}-[0-9]{2}/)
      printf "ERROR|no-retest-date|machine.md:%d|Conclusion has no \"retest by YYYY-MM-DD\" — it can never expire\n", NR
    else { pend=NR; line=$0 }
    next
  }
  pend && /^[[:space:]]*retest:/ { pend=0; next }
  pend && NF { printf "ERROR|no-retest-method|machine.md:%d|Conclusion is not followed by a \"retest:\" line saying how to confirm it\n", pend; pend=0 }
  END { if (pend) printf "ERROR|no-retest-method|machine.md:%d|Conclusion is not followed by a \"retest:\" line saying how to confirm it\n", pend }
' "$PROFILE" > "$TMPOUT"
while IFS= read -r l; do [ -n "$l" ] && { echo "$l"; bump; }; done < "$TMPOUT"

# ---------- Overdue retests ----------
for d in $(grep -oE 'retest by [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROFILE" 2>/dev/null | awk '{print $3}'); do
  [ "$d" \< "$TODAY" ] && say WARN overdue-retest "machine.md" "A conclusion was due for retest on $d — retest or demote it"
done

# ---------- Told-class facts older than a year ----------
for d in $(grep -oE 'you told me [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROFILE" 2>/dev/null | awk '{print $4}'); do
  [ "$d" \< "$YEAR_AGO" ] && say INFO ask-again "machine.md" "Something the user told you on $d is over a year old — ask once whether it still holds"
done

# ---------- Stale measurements ----------
for d in $(grep -oE 'measured [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROFILE" 2>/dev/null | awk '{print $2}'); do
  [ "$d" \< "$DAYS180" ] && say INFO stale-measurement "machine.md" "A measurement from $d is over 180 days old — re-read it rather than trusting it"
done

# ---------- Private Connection: "working" has a shelf life ----------
if grep -q 'Status: working' "$PROFILE" 2>/dev/null; then
  lv="$(grep -oE 'Last verified: [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PROFILE" | awk '{print $3}' | head -1)"
  if [ -z "$lv" ]; then
    say ERROR unverified-connection "machine.md" "Private Connection says working but has no Last verified date"
  elif [ "$lv" \< "$DAYS60" ]; then
    say WARN stale-connection "machine.md" "Private Connection last verified $lv — over 60 days is not evidence, re-verify"
  fi
fi

# ---------- Summon word must keep its leading underscore ----------
s="$(grep -m1 '^Summon: ' "$PROFILE" 2>/dev/null | sed 's/^Summon: //' | tr -d ' ')"
[ -n "$s" ] && case "$s" in _?*) ;; *) say ERROR bad-summon "machine.md" "Summon word '$s' lacks the leading underscore that prevents accidental triggering";; esac

# ---------- Structural labels must stay English ----------
# A profile answered in another language must still carry English labels:
# the digest greps for them, so a translated label fails silently. Detect
# the damage by its symptom — a section exists but its labels are gone.
for pair in "Owner:- Call me:|- Language:" "Hardware:- Model:" "System:- macOS:"; do
  sec="${pair%%:*}"; want="${pair#*:}"
  if grep -q "^## $sec" "$PROFILE" 2>/dev/null; then
    body="$(awk -v s="## $sec" '$0==s{f=1;next} /^## /{f=0} f' "$PROFILE")"
    hit=0
    IFS='|'; for lbl in $want; do printf '%s' "$body" | grep -q "^$lbl" && hit=1; done; unset IFS
    [ "$hit" -eq 0 ] && [ -n "$(printf '%s' "$body" | tr -d '[:space:]')" ] && \
      say ERROR translated-label "machine.md" "Section '$sec' has content but none of its English field labels ($want) — labels must stay English or the session digest cannot read them"
  fi
done

# Non-ASCII in a field label is the direct form of the same bug. LC_ALL=C
# makes the byte range literal; the \xNN form is not portable to BSD grep
# and silently matches nothing here.
#
# Scoped to field-bearing sections only, and to a short pre-colon run. The
# schema MANDATES a "·" separator in Live Conclusions, and any conclusion
# text containing a colon would otherwise be flagged — causing the agent to
# "repair" a correct line by deleting the separator the schema requires.
# A linter that mutates correct data is worse than no linter.
bad_labels="$(awk '
  /^## / { sec=substr($0,4); next }
  sec ~ /^(Hardware|System|Owner|Conventions|Private Connection)$/ && /^- [^:]{1,24}:/ { print NR ":" $0 }
' "$PROFILE" 2>/dev/null | LC_ALL=C grep '^[0-9]*:- [^:]*[^ -~][^:]*:' | cut -d: -f1)"
for ln in $bad_labels; do
  say ERROR non-ascii-label "machine.md:$ln" "Field label contains non-ASCII characters — values may be in any language, labels may not"
done

# ---------- Context cost ----------
lines=$(wc -l < "$PROFILE" | tr -d ' ')
[ "$lines" -gt 120 ] && say WARN over-cap "machine.md" "Profile is $lines lines (cap 120) — demote resolved items and expired conclusions to history.md"

# ---------- Ledger integrity ----------
if [ -f "$LEDGER" ]; then
  ln=0
  while IFS= read -r l || [ -n "$l" ]; do
    ln=$((ln+1)); [ -z "$l" ] && continue
    case "$l" in '{'*'}') ;; *) say ERROR bad-ledger-line "ledger.jsonl:$ln" "Not a JSON object"; continue;; esac
    for k in ts event subject; do
      case "$l" in *"\"$k\""*) ;; *) say ERROR ledger-missing-key "ledger.jsonl:$ln" "Missing required key: $k";; esac
    done
    ev="$(printf '%s' "$l" | sed -n 's/.*"event"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    case "$ev" in learned|confirmed|changed|retested|demoted|corrected|redacted|'') ;; *) say WARN ledger-unknown-event "ledger.jsonl:$ln" "Unrecognised event '$ev'";; esac
  done < "$LEDGER"

  # Demote-not-delete: anything the ledger says was demoted must be findable
  # in history.md, or the trail is broken.
  for subj in $(grep '"event"[[:space:]]*:[[:space:]]*"demoted"' "$LEDGER" 2>/dev/null | sed -n 's/.*"subject"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | sort -u); do
    if [ -f "$HISTORY" ]; then
      grep -qF "$subj" "$HISTORY" || say ERROR lost-history "history.md" "Ledger records '$subj' as demoted but it is absent from history.md — demoted beliefs must be kept, not deleted"
    else
      say ERROR lost-history "history.md" "Ledger records demotions but history.md does not exist — demoted beliefs must be kept, not deleted"
      break
    fi
  done
fi

[ "$(findings)" -gt 0 ] && exit 1
exit 0
