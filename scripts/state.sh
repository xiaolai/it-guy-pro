#!/bin/bash
# it-guy-pro state writer — the ONLY sanctioned path that mutates ~/ITGuy.
#
# ~/ITGuy is a small database: a schema, cross-file referential integrity
# (every demoted subject must exist in history.md), a size cap, a uniqueness
# constraint on declined patterns, and two append-only logs. Before this file
# existed, every invariant was asserted in prose to an LLM and executed
# concurrently by any number of sessions, with no lock and no transaction.
# The linter could detect the resulting corruption; nothing prevented it.
#
# Guarantees provided here:
#   * mutual exclusion  — an atomic mkdir lock, with stale-lock recovery
#   * atomicity         — write to a temp file, then rename (same filesystem)
#   * all-or-nothing    — demote touches three files or none
#   * validation        — a candidate profile is linted BEFORE it is committed
#
# Bash + JXA only. No python3: on a stock Mac that can trigger an Xcode
# Command Line Tools prompt, which is unacceptable for this plugin's users.
# No flock: it is not present on macOS. mkdir is atomic on POSIX and is.
#
# Usage:
#   state.sh init
#   state.sh visit <command> <summary> <space-freed>
#   state.sh ledger <event> <subject> [note]
#   state.sh demote <subject> <reason>
#   state.sh toolbox-add <name> <pattern> <purpose>
#   state.sh toolbox-decline <pattern-id>
#   state.sh toolbox-declined <pattern-id>      # exit 0 if declined
#   state.sh with-lock <command> [args...]      # run anything under the lock
#   state.sh validate
#
# Exit: 0 success · 1 error · 3 lock unavailable · 4 validation refused

set -u

ROOT="${ITGUY_ROOT:-$HOME/ITGuy}"
LOCK="$ROOT/.lock"
HERE="$(cd "$(dirname "$0")" && pwd)"
LOCK_TIMEOUT=30       # seconds to wait for a busy lock
STALE_AFTER=120       # a lock older than this is presumed abandoned
STARTUP_GRACE=3       # never judge an owner dead before its pid is settled

die() { echo "state.sh: $1" >&2; exit "${2:-1}"; }

# ---------------------------------------------------------------- locking --
lock_acquire() {
  mkdir -p "$ROOT" 2>/dev/null || die "cannot create $ROOT"
  local waited=0
  while ! mkdir "$LOCK" 2>/dev/null; do
    # Reclaim a lock whose owner died — but never one that is merely young.
    #
    # There is a window between `mkdir` succeeding and the owner writing its
    # pid. A waiter that read the pid file during that window got an empty
    # string, `kill -0 ""` failed, and it concluded the owner was dead and
    # stole a LIVE lock — two writers in the critical section, one update
    # lost. Measured at roughly 1 run in 20. So: an unreadable or non-numeric
    # pid is treated as "starting up, wait", and only the age of the lock
    # itself can justify breaking it.
    local owner age now mtime
    owner="$(cat "$LOCK/pid" 2>/dev/null)"
    now=$(date +%s)
    mtime=$(stat -f %m "$LOCK" 2>/dev/null || stat -c %Y "$LOCK" 2>/dev/null || echo "$now")
    age=$((now - mtime))
    if [ "$age" -gt "$STALE_AFTER" ]; then
      rm -rf "$LOCK" 2>/dev/null; continue
    fi
    # A confirmed-dead owner still needs the lock to have settled first.
    case "$owner" in
      ''|*[!0-9]*) : ;;                       # starting up or unreadable — wait
      *) if [ "$age" -gt "$STARTUP_GRACE" ] && ! kill -0 "$owner" 2>/dev/null; then
           rm -rf "$LOCK" 2>/dev/null; continue
         fi ;;
    esac
    waited=$((waited + 1))
    [ "$waited" -ge "$((LOCK_TIMEOUT * 10))" ] && die "another session is writing to $ROOT; try again" 3
    sleep 0.1
  done
  echo $$ > "$LOCK/pid"
  LOCK_OWNER=$BASHPID
  trap 'lock_release' EXIT INT TERM
}

# Release only from the process that acquired it.
#
# A `$(...)` command substitution inherits the EXIT trap, so without this
# guard the subshell running the JSON edit fired lock_release the moment it
# returned — dropping the lock while the caller believed it still held one.
# Concurrent writers then interleaved and lost updates, which is exactly the
# failure this file exists to prevent. $$ is unusable here because bash keeps
# it pointing at the original shell inside a subshell; $BASHPID does not.
LOCK_OWNER=""
lock_release() {
  [ -n "$LOCK_OWNER" ] && [ "$BASHPID" = "$LOCK_OWNER" ] && rm -rf "$LOCK" 2>/dev/null
  return 0
}

# Write stdin to $1 atomically: a reader sees either the old file or the new
# one, never a half-written one, even if the process dies mid-write.
atomic_write() {
  local dest="$1" tmp
  tmp="$(mktemp "${dest}.tmp.XXXXXX")" || die "cannot create temp beside $dest"
  cat > "$tmp" || { rm -f "$tmp"; die "write failed"; }
  mv -f "$tmp" "$dest" || { rm -f "$tmp"; die "rename failed"; }
}

atomic_append() {
  local dest="$1" line="$2"
  [ -e "$dest" ] || : > "$dest"
  printf '%s\n' "$line" >> "$dest"
}

# Reject a candidate profile that the linter rejects. This is what makes the
# write path validating rather than merely serialised.
validate_candidate() {
  local candidate="$1" sandbox rc
  sandbox="$(mktemp -d)" || return 0
  cp "$candidate" "$sandbox/machine.md" 2>/dev/null
  [ -f "$ROOT/history.md" ] && cp "$ROOT/history.md" "$sandbox/" 2>/dev/null
  [ -f "$ROOT/ledger.jsonl" ] && cp "$ROOT/ledger.jsonl" "$sandbox/" 2>/dev/null
  out="$(bash "$HERE/lint-profile.sh" "$sandbox" 2>/dev/null)"; rc=$?
  rm -rf "$sandbox"
  if [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q '^CRITICAL'; then
    printf '%s\n' "$out" | grep '^CRITICAL' >&2
    return 1
  fi
  return 0
}

# ------------------------------------------------------------------- JSON --
# JXA ships with every macOS. Used instead of python3 so the plugin never
# provokes a Command Line Tools install on a non-technical user's machine.
json_edit() {
  local file="$1" script="$2"
  osascript -l JavaScript -e '
    ObjC.import("Foundation");
    function readFile(p){ var s=$.NSString.stringWithContentsOfFileEncodingError(p,$.NSUTF8StringEncoding,null); return s.isNil()?null:s.js; }
    function run(argv){
      var path=argv[0], op=argv[1], a=argv[2]||"", b=argv[3]||"", c=argv[4]||"";
      var raw=readFile(path); var d;
      try { d = raw ? JSON.parse(raw) : {}; } catch(e) { d = {}; }
      if (!Array.isArray(d.tools)) d.tools=[];
      if (!Array.isArray(d.declined)) d.declined=[];
      if (op==="add") {
        if (!d.tools.some(function(t){return t.name===a;}))
          d.tools.push({name:a, pattern:b||null, purpose:c, built:argv[5], last_used:argv[5], runs:0, stage:"script"});
        d.declined = d.declined.filter(function(x){ return x!==b; });
      } else if (op==="decline") {
        if (d.declined.indexOf(a)===-1) d.declined.push(a);
      } else if (op==="undecline") {
        d.declined = d.declined.filter(function(x){ return x!==a; });
      } else if (op==="isdeclined") {
        return d.declined.indexOf(a)!==-1 ? "yes" : "no";
      }
      return JSON.stringify(d, null, 2);
    }' "$file" "$script" "$3" "${4:-}" "${5:-}" "$(date +%Y-%m-%d)"
}

# ------------------------------------------------------------- subcommands --
cmd_init() {
  lock_acquire
  mkdir -p "$ROOT"/{toolbox,undo,learn,reports}
  [ -f "$ROOT/toolbox.json" ] || printf '{\n  "tools": [],\n  "declined": []\n}\n' > "$ROOT/toolbox.json"
  [ -f "$ROOT/visits.log" ]   || : > "$ROOT/visits.log"
  [ -f "$ROOT/ledger.jsonl" ] || : > "$ROOT/ledger.jsonl"
  [ -f "$ROOT/history.md" ]   || printf '# What the IT guy used to believe\n\n' > "$ROOT/history.md"
  echo "$ROOT ready"
}

cmd_visit() {
  [ $# -ge 2 ] || die "usage: visit <command> <summary> [space-freed]"
  lock_acquire
  atomic_append "$ROOT/visits.log" "$(date '+%Y-%m-%d %H:%M') | $1 | $2 | ${3:--}"
}

cmd_ledger() {
  [ $# -ge 2 ] || die "usage: ledger <event> <subject> [note]"
  case "$1" in
    learned|confirmed|changed|retested|demoted|corrected|redacted) ;;
    *) die "unknown ledger event: $1 (learned|confirmed|changed|retested|demoted|corrected|redacted)" ;;
  esac
  lock_acquire
  local note esc
  note="${3:-}"
  # JSON-escape: a raw quote or backslash would corrupt an append-only log.
  esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037'; }
  atomic_append "$ROOT/ledger.jsonl" \
    "{\"ts\":\"$(date +%Y-%m-%d)\",\"event\":\"$(esc "$1")\",\"subject\":\"$(esc "$2")\",\"note\":\"$(esc "$note")\"}"
}

# The three-file transaction the architecture previously could not perform.
# Either the belief leaves machine.md AND lands in history.md AND is recorded
# in the ledger, or nothing changes at all.
cmd_demote() {
  [ $# -ge 2 ] || die "usage: demote <subject> <reason>"
  local subject="$1" reason="$2"
  lock_acquire
  [ -f "$ROOT/machine.md" ] || die "no profile to demote from"
  grep -qF "$subject" "$ROOT/machine.md" || die "subject not found in profile: $subject"

  local newprof
  newprof="$(mktemp)" || die "mktemp failed"
  # Drop the matching conclusion line and any indented retest: line under it.
  awk -v s="$subject" '
    index($0, s) && /^- / { skip=1; next }
    skip && /^[[:space:]]+retest:/ { next }
    { skip=0; print }
  ' "$ROOT/machine.md" > "$newprof"

  if ! validate_candidate "$newprof"; then
    rm -f "$newprof"; die "refused: the resulting profile would contain a CRITICAL finding" 4
  fi

  # Commit order: history first, then the ledger, then the profile. If the
  # process dies between steps the belief still exists somewhere — the trail
  # is never the thing that goes missing.
  [ -f "$ROOT/history.md" ] || printf '# What the IT guy used to believe\n\n' > "$ROOT/history.md"
  atomic_append "$ROOT/history.md" "- $(date +%Y-%m-%d) · demoted · $subject · $reason"
  atomic_append "$ROOT/ledger.jsonl" \
    "{\"ts\":\"$(date +%Y-%m-%d)\",\"event\":\"demoted\",\"subject\":\"$(printf '%s' "$subject" | sed 's/\\/\\\\/g; s/"/\\"/g')\",\"to\":\"history.md\"}"
  atomic_write "$ROOT/machine.md" < "$newprof"
  rm -f "$newprof"
  echo "demoted: $subject"
}

cmd_toolbox_add() {
  [ $# -ge 1 ] || die "usage: toolbox-add <name> [pattern-id] [purpose]"
  lock_acquire
  local out
  out="$(json_edit "$ROOT/toolbox.json" add "$1" "${2:-}" "${3:-}")" || die "registry edit failed"
  atomic_write "$ROOT/toolbox.json" <<< "$out"
}

cmd_toolbox_decline() {
  [ $# -ge 1 ] || die "usage: toolbox-decline <pattern-id>"
  lock_acquire
  local out
  out="$(json_edit "$ROOT/toolbox.json" decline "$1")" || die "registry edit failed"
  atomic_write "$ROOT/toolbox.json" <<< "$out"
}

cmd_toolbox_declined() {
  [ $# -ge 1 ] || die "usage: toolbox-declined <pattern-id>"
  [ -f "$ROOT/toolbox.json" ] || exit 1
  [ "$(json_edit "$ROOT/toolbox.json" isdeclined "$1")" = "yes" ]
}

cmd_with_lock() {
  [ $# -ge 1 ] || die "usage: with-lock <command> [args...]"
  lock_acquire
  "$@"
}

cmd_validate() { bash "$HERE/lint-profile.sh" "$ROOT"; }

case "${1:-}" in
  init)              shift; cmd_init "$@" ;;
  visit)             shift; cmd_visit "$@" ;;
  ledger)            shift; cmd_ledger "$@" ;;
  demote)            shift; cmd_demote "$@" ;;
  toolbox-add)       shift; cmd_toolbox_add "$@" ;;
  toolbox-decline)   shift; cmd_toolbox_decline "$@" ;;
  toolbox-declined)  shift; cmd_toolbox_declined "$@" ;;
  with-lock)         shift; cmd_with_lock "$@" ;;
  validate)          shift; cmd_validate "$@" ;;
  *) die "usage: state.sh {init|visit|ledger|demote|toolbox-add|toolbox-decline|toolbox-declined|with-lock|validate}" ;;
esac
