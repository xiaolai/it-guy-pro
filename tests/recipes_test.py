#!/usr/bin/env python3
"""Contract tests between the prose artifacts and the code that enforces them.

The commands, agents and skills are natural language and cannot be executed.
Their *mechanical claims* can be: that every shell recipe parses, that the
guard does not block the plugin's own documented commands, that the schema
the digest greps for is the schema the skill publishes, and that the plugin's
own cross-references resolve. Those couplings are where the silent failures
have actually been.
"""
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUARD = ROOT / "scripts" / "guard.sh"
DIGEST = ROOT / "scripts" / "profile-digest.sh"
LINT = ROOT / "scripts" / "lint-profile.sh"

MD = sorted(p for p in ROOT.rglob("*.md") if ".git" not in p.parts)
CASES = []


def case(fn):
    CASES.append((fn.__doc__ or fn.__name__, fn))
    return fn


def fenced(lang="bash"):
    """(file, code) for every fenced block tagged with `lang`."""
    out = []
    for p in MD:
        for m in re.finditer(rf"```{lang}\n(.*?)```", p.read_text(), re.S):
            out.append((p.relative_to(ROOT), m.group(1)))
    return out


def guard_verdict(cmd):
    payload = json.dumps({"tool_name": "Bash",
                          "tool_input": {"command": cmd, "description": "documented recipe"}})
    r = subprocess.run(["bash", str(GUARD)], input=payload,
                       capture_output=True, text=True, timeout=30)
    if r.returncode == 2:
        return "deny", r.stderr.strip()
    return ("ask" if "ask" in r.stdout else "allow"), ""


@case
def t_every_bash_fence_parses():
    """every documented bash block is syntactically valid shell"""
    bad = []
    for path, code in fenced("bash"):
        # Placeholder-bearing snippets are templates, not runnable commands.
        if re.search(r"<[a-z-]+>|YOUR_|\$P\b", code):
            continue
        r = subprocess.run(["bash", "-n"], input=code, capture_output=True, text=True)
        if r.returncode != 0:
            bad.append(f"{path}: {r.stderr.strip().splitlines()[0] if r.stderr else '?'}")
    assert not bad, "unparseable documented shell:\n  " + "\n  ".join(bad)


@case
def t_guard_does_not_block_our_own_recipes():
    """the guard and the skills are edited by different concerns and drift"""
    denied = []
    for path, code in fenced("bash"):
        for line in code.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or re.search(r"<[a-z-]+>|YOUR_", line):
                continue
            verdict, why = guard_verdict(line)
            if verdict == "deny":
                denied.append(f"{path}: {line[:70]}\n      -> {why[:90]}")
    assert not denied, (
        "the guard denies commands this plugin tells itself to run:\n  "
        + "\n  ".join(denied))


@case
def t_documented_schema_satisfies_its_own_linter():
    """the published profile template must pass the checks we ship"""
    skill = (ROOT / "skills/machine-profile/SKILL.md").read_text()
    block = re.search(r"```markdown\n(# This Machine.*?)```", skill, re.S)
    assert block, "the machine-profile skill no longer publishes a profile template"
    tpl = block.group(1)
    # Substitute the schema's placeholders with schema-valid values.
    tpl = re.sub(r"<[^>\n]+>", "Ada", tpl)
    tpl = tpl.replace("YYYY-MM-DD", "2026-01-15")
    d = Path(tempfile.mkdtemp()) / "ITGuy"
    d.mkdir(parents=True)
    (d / "machine.md").write_text(tpl)
    r = subprocess.run(["bash", str(LINT), str(d)], capture_output=True, text=True)
    critical = [l for l in r.stdout.splitlines() if l.startswith(("CRITICAL", "ERROR"))]
    assert not critical, (
        "the documented schema fails the linter we ship with it:\n  " + "\n  ".join(critical))


@case
def t_digest_reads_the_fields_the_schema_publishes():
    """the schema and the digest must agree on field labels, or features die silently"""
    skill = (ROOT / "skills/machine-profile/SKILL.md").read_text()
    block = re.search(r"```markdown\n(# This Machine.*?)```", skill, re.S)
    tpl = re.sub(r"<[^>\n]+>", "Ada", block.group(1)).replace("YYYY-MM-DD", "2026-01-15")
    tpl = tpl.replace("Summon: Ada", "Summon: _it")
    home = Path(tempfile.mkdtemp())
    d = home / "ITGuy"
    d.mkdir(parents=True)
    (d / "machine.md").write_text(tpl)
    (d / "visits.log").write_text("2026-01-15 10:00 | checkup | fine | -\n")
    r = subprocess.run(["bash", str(DIGEST)], capture_output=True, text=True,
                       env={"HOME": str(home), "PATH": "/usr/bin:/bin:/usr/sbin:/sbin"})
    for needed in ("Summon:", "Address the user as", "Answer this user in"):
        assert needed in r.stdout, (
            f"the digest produced no {needed!r} line from the schema's own template — "
            f"a label was renamed on one side only:\n{r.stdout}")


@case
def t_plugin_root_references_resolve():
    """every ${CLAUDE_PLUGIN_ROOT}/... path a command loads must exist"""
    missing = []
    for p in MD:
        for ref in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/([A-Za-z0-9_./-]+)", p.read_text()):
            if not (ROOT / ref).exists():
                missing.append(f"{p.relative_to(ROOT)} -> {ref}")
    assert not missing, "dangling plugin-root references:\n  " + "\n  ".join(missing)


@case
def t_declared_commands_and_skills_exist():
    """it-guy-pro:<name> must resolve to a real command, agent or skill"""
    names = {p.stem for p in (ROOT / "commands").glob("*.md")}
    names |= {p.stem for p in (ROOT / "agents").glob("*.md")}
    names |= {p.parent.name for p in ROOT.glob("skills/*/SKILL.md")}
    missing = set()
    for p in MD:
        for ref in re.findall(r"it-guy-pro:([a-z][a-z0-9-]*)", p.read_text()):
            if ref not in names:
                missing.add(ref)
    assert not missing, f"references to things that do not exist: {sorted(missing)}"


@case
def t_readme_test_counts_match_reality():
    """the section arguing checks must be executable must not itself be stale"""
    readme = (ROOT / "README.md").read_text()
    actual = {}
    for name, path in (("guard", "tests/guard_test.py"), ("memory", "tests/memory_test.py")):
        r = subprocess.run(["python3", str(ROOT / path)], capture_output=True, text=True)
        m = re.search(r"(\d+)/(\d+) passed", r.stdout)
        actual[name] = int(m.group(2))
    for name, n in actual.items():
        assert f"{n} cases" in readme or f"{n} test cases" in readme, (
            f"README does not state the real {name}-suite count of {n}")


@case
def t_documented_gotchas_are_still_true():
    """recipes claim specific failure behaviour; verify the checkable ones"""
    problems = []
    # macos-recipes says tmutil "errors" when the backup disk is absent.
    r = subprocess.run(["tmutil", "latestbackup"], capture_output=True, text=True)
    recipes = (ROOT / "skills/macos-recipes/SKILL.md").read_text()
    if r.returncode == 0 and re.search(r"`tmutil latestbackup` errors", recipes):
        problems.append(
            "macos-recipes says `tmutil latestbackup` errors when the disk is "
            f"disconnected, but it exited {r.returncode}; an agent branching on $? "
            "would report a healthy backup that does not exist")
    # The airport utility must stay absent, or the note steering away from it is wrong.
    airport = Path("/System/Library/PrivateFrameworks/Apple80211.framework/"
                   "Versions/Current/Resources/airport")
    if airport.exists():
        problems.append("the airport utility exists again; the recipes tell agents it was removed")
    assert not problems, "\n  ".join(problems)


def main():
    fails = 0
    for name, fn in CASES:
        try:
            fn()
            print(f"PASS  {name}")
        except AssertionError as e:
            fails += 1
            print(f"FAIL  {name}\n      {e}")
        except Exception as e:  # noqa: BLE001
            fails += 1
            print(f"ERROR {name}\n      {type(e).__name__}: {e}")
    print(f"\n{len(CASES) - fails}/{len(CASES)} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
