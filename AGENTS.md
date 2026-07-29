# Working conventions for this repo

Shared by Claude, Codex, and any other agent working on it-guy-pro.

## Privacy discipline when testing against a real machine

This plugin's recipes can only be trusted if they are run, and running them means pointing diagnostic commands at a real person's Desktop, Downloads, Documents, network, and profile. That verification has caught real bugs and should continue. **The output of it is the hazard, not the act.**

Binding rules:

1. **Never print raw file names, paths, device names, addresses, or profile values from the operator's real directories.** Print counts, aggregates, pass/fail, or field labels with values suppressed. `wc -l` instead of the listing; `grep -c` instead of the match; "OK (value suppressed)" instead of the value.
2. **Never write a real person's name, employer, address, or file name into any tracked file** — not into documentation, not into an example, and above all not into a test fixture. Use placeholders: `Ada`, `Zoë`, `example.com`, `MacBook Air M2`. A placeholder tests exactly as well.
3. **Prefer synthetic fixtures over the live machine.** Build a temporary directory with the shape you need. Reach for the operator's real data only when the question is specifically "does this behave correctly against real-world mess," and then apply rule 1.
4. **Nothing personal in commit messages.** They are the hardest place to scrub, because removing them rewrites published history.
5. **Redact before quoting.** When a real value must be discussed to explain a finding, describe its shape ("a company name", "a 12-character prefix") rather than reproducing it.

Rule of thumb: this plugin instructs the IT guy to keep MAC addresses, private IPs, and device inventories out of the user's own profile. **Hold the development process to the same standard it imposes on the product.**

## English only

All tracked content is English: documentation, prompts, skills, commands, code, comments, test fixtures, and commit messages. Values a user supplies at runtime may be in any language; nothing checked in may be.

Non-ASCII characters are acceptable when they are typography, mathematics, currency, box drawing, or the functional status symbols used in reports. Natural-language characters from any other script are not. Audit by Unicode letter-class rather than by eye:

```bash
python3 -c "
import subprocess,unicodedata
fs=subprocess.run(['git','ls-files','-z'],capture_output=True,text=True).stdout.split('\0')
bad={(ch,f) for f in filter(None,fs) for ch in open(f,encoding='utf-8',errors='ignore').read()
     if ord(ch)>127 and unicodedata.category(ch).startswith('L')}
print(sorted(bad) or 'clean')"
```

Where a recipe genuinely depends on localized data — macOS names screenshots in the system language — solve it with a language-independent mechanism such as Spotlight metadata, never by hardcoding another language's strings. That is a correctness fix as well as a policy one: hardcoded English patterns silently return zero on a non-English system.

## Verification before release

Both suites must pass, and scripts must parse:

```bash
python3 tests/guard_test.py && python3 tests/memory_test.py
bash -n scripts/guard.sh && bash -n scripts/profile-digest.sh && bash -n scripts/lint-profile.sh
```

Claims in skills carry dates. Anything older than three months is re-verified before it is quoted to a user, and prices and provider policies are checked against the provider's own page rather than recalled.
