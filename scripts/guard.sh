#!/bin/bash
# mac-it-guy-pro guard — PreToolUse hook for the Bash tool.
#
# Defense-in-depth for non-technical users: blocks catastrophic or
# irreversible shell commands regardless of the session's permission mode
# (pedestrian users click "always allow" or run in bypass mode — this
# guard is what stands between them and a wiped photo library).
#
# Enforces two rules from the it-core safety contract:
#   1. Deletions go to the Trash, never through rm.
#   2. Admin (sudo) work is handed to the user, never run by the agent.
#
# Three tiers:
#   DENY  (exit 2, reason on stderr)  — catastrophic, or rm on user content
#   ASK   (JSON on stdout, exit 0)    — risky but sometimes legitimate;
#                                       forces a user prompt even in bypass
#   ALLOW (exit 0, no output)         — everything else
#
# Pattern matching runs against the extracted `tool_input.command` field
# when osascript (every Mac) can parse the payload, and against the raw
# JSON payload as a fallback. Regexes cannot be perfect; the failure
# direction is safe — a false positive blocks, and Claude rephrases.
#
# Threat model: this guard protects against ACCIDENTAL destruction and
# coarse prompt-injection outcomes. It is text matching, not shell
# simulation — a deliberately obfuscated command (quote-splitting,
# encode-then-eval) can evade it. The layered defenses for that case are
# the it-core contract (untrusted-data rules), the indirection "ask"
# tiers below, and Claude Code's own permission system.

# Pathname expansion is never wanted here. The target-extraction loops below
# iterate over an unquoted word split, so a target of `/*` was expanded by the
# shell against the real filesystem before it could be inspected — the guard
# examined whatever happened to be in `/` instead of the literal target it was
# handed. No rule in this file globs on purpose.
set -f

# Every rule below is a `grep`, run through `sed`/`tr`/`awk` helpers. If any of
# them is missing, `hit` returns 127 — non-zero — and every rule silently
# decides "no match", so the guard allows everything while looking healthy.
# That is the one failure mode a guard may not have. Fail loud instead.
for _tool in grep sed tr awk wc; do
  command -v "$_tool" >/dev/null 2>&1 || {
    echo "mac-it-guy-pro guard: cannot run — '$_tool' is not on PATH, so no safety rule can be evaluated. Refusing rather than allowing every command unchecked." >&2
    exit 2
  }
done

payload="$(cat)"

# --- Extract tool_input.command precisely via JXA (ships on every Mac). ---
# Falls back to the raw payload on non-macOS or on parse failure. That is
# meant to widen matching to the description field and over-block, and
# `parsed` below is what makes it actually do so — see the note on the
# quoted-span carve-out.
cmd=""
parsed=1
if command -v osascript >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | osascript -l JavaScript -e '
    ObjC.import("Foundation");
    var data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    var str = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
    var out = "";
    try { var p = JSON.parse(str); out = (p.tool_input && p.tool_input.command) || ""; } catch (e) {}
    out' 2>/dev/null)"
fi
# On the fallback, JSON's own quotes sit exactly where these regexes expect a
# word boundary: the payload renders `find … -delete` as `-delete","description`
# so `-delete([[:space:]]|$)` never matched, and `xargs rm` likewise. Turning
# the structural quotes into spaces restores the boundaries without dropping
# any word. Deliberately not `tr -d` — deleting them would fuse adjacent
# tokens into one and lose boundaries the other way.
[ -n "$cmd" ] || { parsed=0; cmd="$(printf '%s' "$payload" | tr '"' ' ')"; }

# --- A heredoc body is data, not a command ---------------------------------
#
# `cat > notes.md <<'EOF' … EOF` writes a file. Its body is prose, but every
# rule here read it as command text, so documenting a dangerous command was
# denied as though it were being run. The quoted-span carve-out below does not
# help, because a heredoc body carries no quotes. This blocked writing an
# ordinary text file, and blocked this plugin's own release commit.
#
# Removing the body is only safe when nothing executes it, and plenty of things
# do: `bash <<EOF`, `python3 - <<PY`, `ssh host <<EOF`, `crontab <<EOF`, and
# `cat <<EOF | sh` all run what they read. So the body is removed FIRST, and
# the carve-out is then abandoned unless what REMAINS — the command itself plus
# anything after the terminator — names no interpreter, has no pipe, and has no
# command substitution. `cat <<EOF > f` followed by `bash f` keeps its body,
# because the `bash` survives the removal and re-arms the check.
#
# Note this grants nothing new: `echo "rm -rf ~/Documents" > f` is already
# allowed today by the quoted-span carve-out. Writing a dangerous string to a
# file was never the blocked step; executing it is, and that stays blocked.
HEREDOC_EXECUTES='(^|[^a-zA-Z0-9_])((ba|z|k|da)?sh|python3?|perl|ruby|node|deno|ssh|scp|osascript|env|xargs|eval|source|crontab|at|sudo|doas)([[:space:]]|$)|\||\$\(|`|(^|[^a-zA-Z0-9_])\.[[:space:]]'
case "$cmd" in
  *'<<'*)
    nohd="$(printf '%s\n' "$cmd" | awk '
      # A herestring is not a heredoc; hide it before scanning for openers.
      function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
      {
        if (delim != "") {                 # inside a body: drop the line
          if (trim($0) == delim) delim = ""
          next
        }
        det = $0
        gsub(/<<</, "\001", det)
        while (match(det, /<<-?[ \t]*[^ \t|;&<>()]+/)) {
          tok = substr(det, RSTART, RLENGTH)
          det = substr(det, RSTART + RLENGTH)
          d = tok
          sub(/^<<-?[ \t]*/, "", d)
          gsub("[\047\042]", "", d)
          if (d != "") delim = d
        }
        print
      }
      # An unterminated heredoc would swallow every following line, including a
      # real command. Refuse the carve-out rather than hide one.
      END { if (delim != "") exit 3 }
    ')"
    # Written as an explicit if, not `a && b || c`: with the short-circuit form,
    # awk exiting 3 for an unterminated heredoc skipped the grep and fell
    # straight into the `||` branch, applying the carve-out in exactly the case
    # it must not be applied.
    if [ $? -eq 0 ] && ! printf '%s' "$nohd" | grep -qE "$HEREDOC_EXECUTES"; then
      cmd="$nohd"
    fi
    ;;
esac

# Normalized copy, used ONLY for protected-path matching.
#
# Quoting, brace form, a named tilde, and redundant separators all defeat a
# literal path regex while meaning precisely the same thing to the shell.
# Worse, the quoted form is what every style guide demands and what a
# careful writer emits — so matching the raw string made the guard
# strongest against sloppy commands and weakest against deliberate ones,
# which is exactly backwards. `rm -f "$HOME"/Documents/*.pdf` passed while
# the unquoted twin was denied.
norm="$(printf '%s' "$cmd" \
  | tr -d '"\047\\' \
  | sed -e 's/\${HOME}/~/g' \
        -e 's/\$HOME/~/g' \
        -e 's|~[a-zA-Z_][a-zA-Z0-9_.-]*/|~/|g' \
        -e 's|/\./|/|g' \
        -e 's|///*|/|g')"

hitn() { printf '%s' "$norm" | grep -qE "$1"; }

# A second copy with quoted spans REMOVED, used to decide whether a
# destructive verb is really being invoked.
#
# `norm` deliberately strips quote characters so that `rm -f "$HOME"/Documents`
# still matches a protected path. The side effect is that prose describing a
# command reads exactly like the command: a commit message mentioning a
# recursive delete alongside a home path was denied as though it were one.
# Deleting the quoted spans instead answers the different question "is this
# verb in a command position, or is it inside a string?" — so `git commit -m
# "...deletes ~/Documents..."` carries no verb here, while
# `rm -f "$HOME"/Documents/x` still does.
# ...but a quoted span is only inert when nothing EXECUTES it.
#
# `bash -c "rm -rf ~/Documents"` puts a real command inside quotes. Stripping
# quoted spans there would hide the delete completely — trading a cosmetic
# false positive for a silent false negative, which is the wrong direction for
# a guard. So when the command hands a quoted string to a shell, to `eval`, or
# to an interpreter's `-c`/`-e`, the quotes are treated as code and nothing is
# stripped. Prose keeps its carve-out; executable strings do not get one.
# NOTE: a literal grep, not the hit() helper — this runs before hit() is
# defined, and calling it here failed with "command not found", which bash
# treats as non-zero, so the check silently took the strip-quotes branch. A
# guard that fails OPEN is worse than one that never had the check, so this
# stays independent of definition order.
# `osascript -e` is in this list for the same reason as `bash -c`: the quoted
# argument is a program. The legitimate argv-form Trash recipe also uses it,
# and still passes — it contains no destructive verb, so treating its text as
# code changes nothing about the verdict.
# `-c`/`-e` is not the only way to hand an interpreter a program. `python3 -`
# and `bash <<PY` read one from stdin, and the guard did not recognise either:
# a delete sitting inside quotes in such a program had its quoted span stripped
# like prose, so `python3 - <<PY … os.system('rm -rf ~/Documents') … PY` reached
# only the ask tier — and ask is off at the default level, so it was allowed.
# An interpreter followed by a bare `-` or a heredoc is executing what follows.
EXECUTES_QUOTES='(^|[^a-zA-Z0-9_])((ba|z|k|da)?sh|python3?|perl|ruby|node|deno)[[:space:]]+(-[a-zA-Z]*[[:space:]]+)*-[a-zA-Z]*[ce]([[:space:]]|$)|(^|[^a-zA-Z0-9_])((ba|z|k|da)?sh|python3?|perl|ruby|node|deno)[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(-([[:space:]]|$)|<<)|(^|[^a-zA-Z0-9_])eval([[:space:]]|$)|do[[:space:]]+shell[[:space:]]+script|(^|[^a-zA-Z0-9_])osascript[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*-e([[:space:]]|$)'
# ...and it must not be applied at all when extraction FAILED.
#
# On the fallback path `cmd` is the raw JSON payload, where the whole command
# lives inside a quoted value — so stripping quoted spans deleted the command
# itself and every rule using this copy matched nothing. Measured on the case
# table: 20 of 53 verdicts changed without JXA, and 14 of them moved toward
# LESS protection (deny -> allow), including rm on Documents, find -delete on
# Downloads, and tmutil delete. The comment above the extractor claimed the
# fallback over-blocks; it under-blocked, which is the one direction a guard
# must never fail in. Skipping the carve-out restores the documented
# behaviour: no extraction, no prose exemption.
# `ssh -o ProxyCommand='sudo nc %h %p'` belongs here for the same reason as
# `bash -c`: the quoted value is a program, and ProxyCommand/LocalCommand run
# it on THIS machine, so a sudo inside them is local escalation in an ssh
# costume. Matched case-insensitively because ssh accepts any casing for
# option names, and a guard that only recognised one spelling would be
# bypassed by typing another.
if [ "$parsed" -eq 0 ] \
  || printf '%s' "$cmd" | grep -qE "$EXECUTES_QUOTES" \
  || printf '%s' "$cmd" | grep -qiE '(proxy|local)command'; then
  unq="$cmd"
else
  # Joined onto one line first, because `sed` works per line and a quoted span
  # may not. A multi-line commit message — the ordinary way to write one — had
  # only its individual lines examined, so a body mentioning a recursive delete
  # was denied while the single-line form was allowed. Same string, same
  # meaning, opposite verdict.
  #
  # This does not widen the carve-out: `[^"]*` still cannot cross a quote, so
  # `echo "a"` / `rm -rf ~/Documents` / `echo "b"` on three lines strips the two
  # echoes and leaves the delete exposed, exactly as before.
  unq="$(printf '%s' "$cmd" | tr '\n' '\001' \
    | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g' | tr '\001' '\n')"
fi
hitu()  { printf '%s' "$unq" | grep -qE  "$1"; }
hitui() { printf '%s' "$unq" | grep -qiE "$1"; }

# A single-line command is required for the remote-ssh exemption below:
# grep matches per line, so any `ssh …` line anywhere would otherwise
# excuse a `sudo` on a completely different line of the same script.
newlines="$(printf '%s' "$cmd" | tr -dc '\n' | wc -c | tr -d ' ')"

# --- How much of this guard applies (ITGUY_GUARD) --------------------------
#
# A PreToolUse hook sees EVERY Bash command in the session and the payload
# carries no field naming the plugin that issued it, so this guard cannot
# scope itself to its own workflows even in principle. It is global or it is
# nothing. That is a real imposition: installing a Mac-maintenance helper
# should not silently enrol someone's unrelated development work in a
# system-wide command policy they never chose.
#
# So the rules are split by what they actually defend, and the level is the
# user's to pick:
#
#   data    (default) only what protects irreplaceable things — deletes inside
#                     user content, the Trash, backups, whole-disk and
#                     whole-tree destruction. System-policy rules (sudo,
#                     shutdown, SIP, firmware) and every confirmation prompt
#                     are skipped.
#   strict            everything below, including machine policy and prompts.
#   relaxed           all deny rules, no confirmation prompts.
#   off               nothing. Documented, not recommended, and the plugin
#                     says so out loud when it is set.
LEVEL="${ITGUY_GUARD:-data}"
# An unrecognised value is a typo, and a typo must never quietly weaken the
# guard: `ITGUY_GUARD=Data` or `=yes` would otherwise have dropped every
# machine-policy rule without saying anything. Note this lands on `strict`,
# which is now STRICTER than the default — deliberately. An unset variable
# means "I made no choice", and gets the shipped default; a malformed one
# means "I tried to choose and failed", and gets the loudest setting, so the
# mistake surfaces immediately instead of silently removing protection.
case "$LEVEL" in strict|relaxed|data|off) ;; *) LEVEL=strict ;; esac
data_on()   { [ "$LEVEL" != "off" ]; }
policy_on() { case "$LEVEL" in strict|relaxed) return 0 ;; *) return 1 ;; esac; }
ask_on()    { [ "$LEVEL" = "strict" ]; }

data_on || exit 0     # LEVEL=off — nothing below runs.

# Every block names the active level and the way out.
#
# Before this, exactly one of the 38 block messages mentioned ITGUY_GUARD at
# all. The other 37 said "no" and stopped, so a developer whose unrelated work
# was blocked had no way to learn a dial existed without reading the README —
# which made an adjustable guard feel like a non-negotiable one. A refusal that
# hides its own remedy is a worse refusal.
hint() {
  case "$LEVEL" in
    data)    printf ' [guard level: data — this rule protects irreplaceable files. ITGUY_GUARD=off removes the guard entirely.]' ;;
    strict)  printf ' [guard level: strict, the fullest setting. ITGUY_GUARD=data keeps your files protected while leaving the machine unpoliced and never prompting.]' ;;
    relaxed) printf ' [guard level: relaxed. ITGUY_GUARD=off removes the guard entirely.]' ;;
  esac
}

deny() {
  echo "mac-it-guy-pro guard: $1$(hint)" >&2
  exit 2
}

ask() {
  # Escape for embedding in JSON.
  reason="$(printf '%s' "mac-it-guy-pro guard: $1$(hint)" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

hit()  { printf '%s' "$cmd" | grep -qE  "$1"; }
hiti() { printf '%s' "$cmd" | grep -qiE "$1"; }

# Paths that hold user content (plus the IT Guy state itself). An rm that
# touches any of these is always denied — the Trash is the only exit.
PROT='(~|\$HOME|/Users/[^/[:space:]"'\'']+)/(Documents|Desktop|Downloads|Pictures|Movies|Music|Library|ITGuy)'

# ---------- Tier 1: always deny ----------

# Remote root over ssh is not local privilege escalation — administering a
# VPS legitimately needs it. Downgrade sudo to "ask" ONLY when the command
# starts with ssh and carries no locally-executed option: ProxyCommand and
# LocalCommand run on THIS machine, so a sudo there is local escalation in
# an ssh costume.
if [ "$newlines" -eq 0 ] && hit '^[[:space:]]*ssh[[:space:]]' && ! hiti '(proxycommand|localcommand)'; then
  ask_on && hit '(^|[^a-zA-Z0-9_])sudo[[:space:]]' && ask \
    "This runs sudo on the remote server, not on this Mac. Confirm the target host with the user, and remember the guard cannot protect the far end."
fi

policy_on && hitu '(^|[^a-zA-Z0-9_])sudo[[:space:]]' && deny \
  "sudo is never run by the agent. Give the user the exact command to run themselves (tell them to type '! <command>' in the prompt) plus a one-sentence plain-language explanation of what it does."

hitu '(^|[^a-zA-Z0-9_./-])dd[[:space:]]' && deny \
  "dd can silently destroy a disk. Use a purpose-specific tool instead and explain the goal to the user first."

hitu '(^|[^a-zA-Z0-9_])(mkfs|newfs_[a-z]+)' && deny \
  "Filesystem formatting is out of bounds for the IT guy."

hitu 'diskutil[[:space:]]+(erase[a-zA-Z]*|reformat|partitionDisk|zeroDisk|secureErase)|diskutil[[:space:]]+apfs[[:space:]]+(delete|erase)|asr[[:space:]]+restore' && deny \
  "Disk erase/partition/restore is out of bounds. If genuinely needed, walk the user through Disk Utility step by step instead."

hitu '>+[[:space:]]*/dev/(disk|rdisk)' && deny \
  "Writing to raw disk devices is out of bounds."

hitu '(^|[^a-zA-Z0-9_])(shred|srm)[[:space:]]' && deny \
  "Secure-erase tools are out of bounds — deletions go to the Trash so the user can undo them."

hitu ':\(\)[[:space:]]*\{[[:space:]]*:\|:' && deny \
  "Fork bomb pattern."

hitu '(chmod|chown)[[:space:]]+-[a-zA-Z]*R' && hitu '(/System|/Library|/usr|/bin|/sbin|/etc|/var|[[:space:]]/[[:space:]"'\'']*$|[[:space:]]/$|[[:space:]]~[[:space:]]*$|\$HOME[[:space:]]*$)' && deny \
  "Recursive permission changes on system or home directories break macOS in ways that need a reinstall to fix."

policy_on && hitu 'launchctl[[:space:]]+(bootout[[:space:]]+system|unload[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(/System|/Library/LaunchDaemons))' && deny \
  "Unloading system daemons is out of bounds. For startup items, work only on the user's own LaunchAgents and explain each one first."

policy_on && hitu '(^|[^a-zA-Z0-9_])csrutil' && deny \
  "System Integrity Protection stays on. Whatever the goal is, find another way."

policy_on && hitu '(^|[^a-zA-Z0-9_])nvram[[:space:]]' && deny \
  "Firmware variables are out of bounds."

policy_on && hitu '(^|[^a-zA-Z0-9_])(shutdown|reboot|halt)([[:space:]]+(-[a-zA-Z]+|now)|[[:space:]]*$)' && deny \
  "Never restart or shut down the user's machine. If a restart is needed, tell the user why and let them do it when they are ready."

hitu 'tmutil[[:space:]]+(delete|disable)' && deny \
  "Never delete or disable the user's backups. If old backups need thinning, show the user how in System Settings and let them decide."

hitui 'empty[[:space:]]+(the[[:space:]]+)?trash' && deny \
  "Only the user empties the Trash. Tell them what is in it, how much space it frees, and let them do it in Finder (Finder > Empty Trash)."

hitu '\.Trash' && hitu '(^|[^a-zA-Z0-9_])rm[[:space:]]' && deny \
  "Only the user empties the Trash. Tell them how much space it would free and let them do it in Finder."

# ---------- Tier 1.5: destructive commands with unresolvable targets ----------
# ".." segments and command substitution hide a command's real target from
# the path checks below (e.g. `rm ~/Downloads/../Documents/x` contains no
# literal `~/Documents`). When a destructive verb is present, refuse to
# guess what an indirect path resolves to.

DESTRUCTIVE='((^|[^a-zA-Z0-9_])(rm|unlink|truncate|shred|srm)[[:space:]]|[[:space:]]-delete([[:space:]]|$)|xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*rm([[:space:]]|$)|(chmod|chown)[[:space:]]+-[a-zA-Z]*R)'
if hitu "$DESTRUCTIVE"; then
  hitn '\.\.' && deny \
    "Paths containing .. hide their real target from safety checks. Re-run with the fully resolved absolute path — no .. segments, no brace ranges, no wildcards in the folder name."
  # Only braces that are part of a PATH. An awk or sed program body is full of
  # `{print $1, $2}` and is not brace expansion; requiring a `/` or `~` earlier
  # in the same token keeps the check on paths, where it belongs. Without this
  # the guard blocked ordinary text processing whenever a delete appeared
  # anywhere in the same command.
  hitn '(~|/)[^[:space:]"'"'"']*\{[^}]*,' && deny \
    "Brace expansion hides how many targets this really has. Re-run once per explicit path so each one can be checked."
  hitn '(~|/Users/[^/[:space:]]+)/[^/[:space:]]*[*?[][^/[:space:]]*/' && deny \
    "A wildcard in the folder name means the guard cannot tell which folders this hits. Name the folder explicitly."
  ask_on && hitu '\$\(|`' && ask \
    "This delete/permission change builds its target indirectly, so the guard cannot verify what it points at. Confirm with the user, or re-run with explicit absolute paths."
fi

# Wiping the home directory itself. Previously this fell to the recursive-rm
# ASK tier, one step *below* deleting a single file inside Documents.
hitn '(^|[^a-zA-Z0-9_])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(~|/Users/[^/[:space:]]+)/?[[:space:]]*($|;|&)' && deny \
  "That deletes the entire home folder. There is no version of this that is the right fix."

# Wiping the disk, a whole system tree, or everything inside the home folder.
#
# Measured gap, not a hypothetical: `rm -rf /` reached only the ASK tier, and
# ASK is skipped at every level below `strict` — so the most destructive
# command on the machine was ALLOWED outright at `data` and `relaxed`.
# `sudo rm -rf /` looked covered, but only incidentally, by the sudo policy
# rule, which `data` also drops. Deleting one file inside Documents was denied
# while deleting everything was not, and the rule above stopped `rm -rf ~` but
# not `rm -rf ~/*`, which destroys exactly the same files.
#
# Ungated on purpose: no level except `off` weakens this one.
#
# Bare roots only. `/usr/local/share/x` and `/opt/myapp/target` are ordinary
# paths and stay allowed; `/usr` and `/opt` themselves are not. /System/Volumes/Data
# is named explicitly because on current macOS it *is* the user's whole disk.
ROOTS='/(System|Library|Applications|Users|usr|bin|sbin|etc|var|private|opt|Volumes|cores|Network)'
if hitn '(^|[^a-zA-Z0-9_])rm[[:space:]]'; then
  # Truncate at the next command separator. Without this the target list ran
  # to end of line and swallowed the arguments of everything that followed:
  # `rm -rf /tmp/x && mkdir -p /tmp/x/bin; for d in /bin /usr/bin; …` was denied
  # for "deleting /bin", which appeared only as an argument to a later command.
  # The delete's targets end where the delete does.
  wipe_targets="$(printf '%s' "$norm" \
    | sed -E 's/(^|.*[;&|])[[:space:]]*rm[[:space:]]+(-[^[:space:]]+[[:space:]]+)*//' \
    | sed -E 's/[;&|<>].*$//')"
  for t in $wipe_targets; do
    case "$t" in -*) continue ;; esac
    printf '%s' "$t" | grep -qE "^(/|/\*|~/\*|/Users/[^/[:space:]]+/\*|/System/Volumes/Data/?\*?|${ROOTS}/?\*?)$" && deny \
      "That deletes an entire system or user tree ($t) — every file under it, with no Trash copy. Name the specific folder you mean instead."
  done
fi

# ---------- Tier 2: deny rm/find-delete/xargs-rm on user content ----------

if hitn "$PROT"; then
  # Destruction is an outcome, not a verb. Truncation and unlink leave no
  # Trash copy at all, so they are stricter than rm, not looser.
  hitu '(^|[^a-zA-Z0-9_])(truncate|unlink)[[:space:]]' && hitn '(truncate|unlink)' && deny \
    "That erases user content without leaving a Trash copy. Move it to the Trash instead — see the argv-form osascript recipe in the mac-it-guy-pro macos-recipes skill."
  hitn '(^|[^>])>[[:space:]]*(~|/Users/[^/[:space:]]+)/(Documents|Desktop|Downloads|Pictures|Movies|Music|Library|ITGuy)' && deny \
    "Redirecting over a file truncates it with no Trash copy and no undo. Write to a new name, or move the old file to the Trash first."
  hitu '(^|[^a-zA-Z0-9_])rm[[:space:]]' && deny \
    "Never rm user content. Move it to the Trash instead so the user can undo — use the argv-form osascript Trash recipe in the mac-it-guy-pro macos-recipes skill."
  hitu '(^|[^a-zA-Z0-9_])find[[:space:]]' && hitu '[[:space:]]-delete([[:space:]]|$)' && deny \
    "Never mass-delete user content with find. List the candidates, show them to the user, then move approved items to the Trash."
  hitu 'xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*rm([[:space:]]|$)' && deny \
    "Never pipe user-content paths into rm. List the candidates, show them to the user, then move approved items to the Trash."
fi

# ---------- Tier 3: ask (forces a user prompt even when allowlisted) ----------

# Regenerable build artefacts. Deleting these is routine developer work and
# the cost of being wrong is a rebuild, not lost data — so asking about them
# is friction with no safety benefit, and constant prompts train a user to
# approve without reading, which is worse than not prompting at all.
#
# Safe because the protected-path deny above has ALREADY run: `rm -rf
# ~/Documents/build` is denied before reaching here, so a directory named
# `build` only reaches this line when it sits outside user content.
ARTIFACT='(node_modules|target|build|dist|out|\.next|\.nuxt|\.turbo|\.parcel-cache|__pycache__|\.pytest_cache|\.mypy_cache|\.ruff_cache|venv|\.venv|\.tox|\.gradle|Pods|DerivedData|coverage|\.cache|vendor|bin/Debug|bin/Release|obj)'

if hitu '(^|[^a-zA-Z0-9_])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)'; then
  # Every target must be a known artefact; one unrecognised path re-arms it.
  # Same truncation as the whole-tree rule above: a target list that ran to end
  # of line pulled in the arguments of later commands, so `rm -rf node_modules
  # && ls ~/code` counted `~/code` as a delete target and re-armed the prompt.
  targets="$(printf '%s' "$norm" \
    | sed -E 's/(^|.*[;&|])[[:space:]]*rm[[:space:]]+(-[^[:space:]]+[[:space:]]+)*//' \
    | sed -E 's/[;&|<>].*$//')"
  unknown=0
  for t in $targets; do
    case "$t" in -*) continue ;; esac
    printf '%s' "$t" | grep -qE "(^|/)$ARTIFACT/?$" || unknown=1
  done
  # No second level check here: ask_on already means LEVEL=strict, and the
  # duplicate `!= relaxed` test that used to sit alongside it re-read the raw
  # environment variable, so it disagreed with the validated LEVEL whenever the
  # value was a typo.
  if [ "$unknown" -ne 0 ]; then
    ask_on && ask "Recursive delete, which leaves no Trash copy and cannot be undone. Build folders and caches are recognised and pass without asking; this target is not one of them, so confirm it is not real work."
  fi
fi

ask_on && hitu '(^|[^a-zA-Z0-9_])find[[:space:]]' && hitu '[[:space:]]-delete([[:space:]]|$)' && ask \
  "find -delete removes every match with no undo — confirm the scope with the user."

ask_on && hitu 'xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*rm([[:space:]]|$)' && ask \
  "Piping a file list into rm has no undo — confirm the scope with the user."

# The three pipe-an-installer-into-a-shell rules deliberately keep reading the
# RAW command, unlike every other ask rule. A pipeline inside quotes is almost
# always real — `ssh host 'bash <(curl …)'` runs an installer on a machine this
# guard cannot follow — whereas prose containing a literal pipe-to-shell is
# rare. Converting these to the prose-aware copy silently dropped the remote
# case. A spurious prompt on prose is noise; a missed prompt here is a machine
# installing unreviewed code.
ask_on && hit '(curl|wget)[^|;&]*\|[^|]*(ba|z|da|k)?sh([[:space:]]|$)' && ask \
  "This pipes an installer from the internet straight into a shell. Download it first, tell the user in one sentence what it installs, then run the reviewed file."

ask_on && hit '\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da|k)?sh([[:space:]]|$)' && ask \
  "This pipes generated content straight into a shell, so the guard cannot inspect what will actually run. Show the user the content first, or run the steps directly."

ask_on && hit '<\([[:space:]]*(curl|wget)' && ask \
  "This runs a downloaded script through process substitution, which hides the content from inspection just like piping to a shell. Download it first, tell the user what it installs, then run the reviewed file."

ask_on && hitu '(^|[^a-zA-Z0-9_])eval[[:space:]]' && ask \
  "eval executes constructed text the guard cannot inspect. Run the steps directly instead, or confirm with the user."

ask_on && hitu 'do[[:space:]]+shell[[:space:]]+script' && ask \
  "AppleScript reaching back into the shell bypasses command inspection. Run the shell part directly so it can be checked."

ask_on && hit '(python3?|perl|ruby|node)[[:space:]]+(-[a-zA-Z[:space:]]+)*-?-(c|e|eval)[[:space:]]' && hit '(os\.system|subprocess|popen|child_process|execSync|spawnSync)' && ask \
  "This inline script shells out from inside an interpreter, which bypasses command inspection. Run the shell command directly, or confirm with the user."

ask_on && hitu 'softwareupdate[[:space:]]+(-[a-zA-Z]*i[a-zA-Z]*|--install)' && ask \
  "System updates can restart the machine and take a long time — the user should explicitly approve this."

ask_on && hitu 'launchctl[[:space:]]+(bootout|unload)[[:space:]]' && ask \
  "Disabling a startup item. Explain to the user in plain language what this program does before switching it off."

ask_on && hitu '(^|[^a-zA-Z0-9_])defaults[[:space:]]+delete' && ask \
  "This erases an app's entire settings. Confirm with the user, and name the app in plain language."

exit 0
