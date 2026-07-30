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

payload="$(cat)"

# --- Extract tool_input.command precisely via JXA (ships on every Mac). ---
# Falls back to the raw payload on non-macOS or on parse failure, which
# widens matching to the description field — safe direction (over-blocking).
cmd=""
if command -v osascript >/dev/null 2>&1; then
  cmd="$(printf '%s' "$payload" | osascript -l JavaScript -e '
    ObjC.import("Foundation");
    var data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
    var str = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding).js;
    var out = "";
    try { var p = JSON.parse(str); out = (p.tool_input && p.tool_input.command) || ""; } catch (e) {}
    out' 2>/dev/null)"
fi
[ -n "$cmd" ] || cmd="$payload"

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
unq="$(printf '%s' "$cmd" | sed -e "s/'[^']*'//g" -e 's/"[^"]*"//g')"
hitu() { printf '%s' "$unq" | grep -qE "$1"; }

# A single-line command is required for the remote-ssh exemption below:
# grep matches per line, so any `ssh …` line anywhere would otherwise
# excuse a `sudo` on a completely different line of the same script.
newlines="$(printf '%s' "$cmd" | tr -dc '\n' | wc -c | tr -d ' ')"

deny() {
  echo "mac-it-guy-pro guard: $1" >&2
  exit 2
}

ask() {
  # Escape for embedding in JSON.
  reason="$(printf '%s' "mac-it-guy-pro guard: $1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
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
  hit '(^|[^a-zA-Z0-9_])sudo[[:space:]]' && ask \
    "This runs sudo on the remote server, not on this Mac. Confirm the target host with the user, and remember the guard cannot protect the far end."
fi

hit '(^|[^a-zA-Z0-9_])sudo[[:space:]]' && deny \
  "sudo is never run by the agent. Give the user the exact command to run themselves (tell them to type '! <command>' in the prompt) plus a one-sentence plain-language explanation of what it does."

hit '(^|[^a-zA-Z0-9_./-])dd[[:space:]]' && deny \
  "dd can silently destroy a disk. Use a purpose-specific tool instead and explain the goal to the user first."

hit '(^|[^a-zA-Z0-9_])(mkfs|newfs_[a-z]+)' && deny \
  "Filesystem formatting is out of bounds for the IT guy."

hit 'diskutil[[:space:]]+(erase[a-zA-Z]*|reformat|partitionDisk|zeroDisk|secureErase)|diskutil[[:space:]]+apfs[[:space:]]+(delete|erase)|asr[[:space:]]+restore' && deny \
  "Disk erase/partition/restore is out of bounds. If genuinely needed, walk the user through Disk Utility step by step instead."

hit '>+[[:space:]]*/dev/(disk|rdisk)' && deny \
  "Writing to raw disk devices is out of bounds."

hit '(^|[^a-zA-Z0-9_])(shred|srm)[[:space:]]' && deny \
  "Secure-erase tools are out of bounds — deletions go to the Trash so the user can undo them."

hit ':\(\)[[:space:]]*\{[[:space:]]*:\|:' && deny \
  "Fork bomb pattern."

hit '(chmod|chown)[[:space:]]+-[a-zA-Z]*R' && hit '(/System|/Library|/usr|/bin|/sbin|/etc|/var|[[:space:]]/[[:space:]"'\'']*$|[[:space:]]/$|[[:space:]]~[[:space:]]*$|\$HOME[[:space:]]*$)' && deny \
  "Recursive permission changes on system or home directories break macOS in ways that need a reinstall to fix."

hit 'launchctl[[:space:]]+(bootout[[:space:]]+system|unload[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(/System|/Library/LaunchDaemons))' && deny \
  "Unloading system daemons is out of bounds. For startup items, work only on the user's own LaunchAgents and explain each one first."

hit '(^|[^a-zA-Z0-9_])csrutil' && deny \
  "System Integrity Protection stays on. Whatever the goal is, find another way."

hit '(^|[^a-zA-Z0-9_])nvram[[:space:]]' && deny \
  "Firmware variables are out of bounds."

hit '(^|[^a-zA-Z0-9_])(shutdown|reboot|halt)([[:space:]]+(-[a-zA-Z]+|now)|[[:space:]]*$)' && deny \
  "Never restart or shut down the user's machine. If a restart is needed, tell the user why and let them do it when they are ready."

hit 'tmutil[[:space:]]+(delete|disable)' && deny \
  "Never delete or disable the user's backups. If old backups need thinning, show the user how in System Settings and let them decide."

hiti 'empty[[:space:]]+(the[[:space:]]+)?trash' && deny \
  "Only the user empties the Trash. Tell them what is in it, how much space it frees, and let them do it in Finder (Finder > Empty Trash)."

hit '\.Trash' && hit '(^|[^a-zA-Z0-9_])rm[[:space:]]' && deny \
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
  hit '\$\(|`' && ask \
    "This delete/permission change builds its target indirectly, so the guard cannot verify what it points at. Confirm with the user, or re-run with explicit absolute paths."
fi

# Wiping the home directory itself. Previously this fell to the recursive-rm
# ASK tier, one step *below* deleting a single file inside Documents.
hitn '(^|[^a-zA-Z0-9_])rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(~|/Users/[^/[:space:]]+)/?[[:space:]]*($|;|&)' && deny \
  "That deletes the entire home folder. There is no version of this that is the right fix."

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

hit '(^|[^a-zA-Z0-9_])rm[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)' && ask \
  "Recursive delete. Outside user-content folders this can be legitimate (build folders, caches), but it cannot be undone — confirm with the user."

hit '(^|[^a-zA-Z0-9_])find[[:space:]]' && hit '[[:space:]]-delete([[:space:]]|$)' && ask \
  "find -delete removes every match with no undo — confirm the scope with the user."

hit 'xargs[[:space:]]+(-[^[:space:]]+[[:space:]]+)*rm([[:space:]]|$)' && ask \
  "Piping a file list into rm has no undo — confirm the scope with the user."

hit '(curl|wget)[^|;&]*\|[^|]*(ba|z|da|k)?sh([[:space:]]|$)' && ask \
  "This pipes an installer from the internet straight into a shell. Download it first, tell the user in one sentence what it installs, then run the reviewed file."

hit '\|[[:space:]]*(sudo[[:space:]]+)?(ba|z|da|k)?sh([[:space:]]|$)' && ask \
  "This pipes generated content straight into a shell, so the guard cannot inspect what will actually run. Show the user the content first, or run the steps directly."

hit '<\([[:space:]]*(curl|wget)' && ask \
  "This runs a downloaded script through process substitution, which hides the content from inspection just like piping to a shell. Download it first, tell the user what it installs, then run the reviewed file."

hit '(^|[^a-zA-Z0-9_])eval[[:space:]]' && ask \
  "eval executes constructed text the guard cannot inspect. Run the steps directly instead, or confirm with the user."

hit 'do[[:space:]]+shell[[:space:]]+script' && ask \
  "AppleScript reaching back into the shell bypasses command inspection. Run the shell part directly so it can be checked."

hit '(python3?|perl|ruby|node)[[:space:]]+(-[a-zA-Z[:space:]]+)*-?-(c|e|eval)[[:space:]]' && hit '(os\.system|subprocess|popen|child_process|execSync|spawnSync)' && ask \
  "This inline script shells out from inside an interpreter, which bypasses command inspection. Run the shell command directly, or confirm with the user."

hit 'softwareupdate[[:space:]]+(-[a-zA-Z]*i[a-zA-Z]*|--install)' && ask \
  "System updates can restart the machine and take a long time — the user should explicitly approve this."

hit 'launchctl[[:space:]]+(bootout|unload)[[:space:]]' && ask \
  "Disabling a startup item. Explain to the user in plain language what this program does before switching it off."

hit '(^|[^a-zA-Z0-9_])defaults[[:space:]]+delete' && ask \
  "This erases an app's entire settings. Confirm with the user, and name the app in plain language."

exit 0
