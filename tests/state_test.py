#!/usr/bin/env python3
"""Tests for scripts/state.sh — the only sanctioned writer of ~/ITGuy.

The properties under test are the ones prose could never guarantee: mutual
exclusion, atomicity, all-or-nothing demotion, and refusal to commit a
profile the linter rejects.
"""
import json
import os
import subprocess
import sys
import tempfile
import threading
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STATE = ROOT / "scripts" / "state.sh"
TODAY = date.today().isoformat()
FUTURE = (date.today() + timedelta(days=90)).isoformat()

PROFILE = f"""# This Machine

Updated: {TODAY} by /mac-it-guy-pro:checkup
Summon: _it

## Owner
- Call me: Ada (you told me {TODAY})

## Live Conclusions
- {TODAY} · fan loud with many browser tabs (concluded {TODAY}, retest by {FUTURE})
  retest: ps -Ao pcpu,comm -r | head -5
- {TODAY} · wifi weak in back bedroom (concluded {TODAY}, retest by {FUTURE})
  retest: compare SNR at the router and at the desk
"""


def st(itguy, *args, **kw):
    env = dict(os.environ, ITGUY_ROOT=str(itguy))
    return subprocess.run(["bash", str(STATE), *args], capture_output=True,
                          text=True, env=env, timeout=kw.get("timeout", 60))


def fresh(with_profile=True):
    d = Path(tempfile.mkdtemp()) / "ITGuy"
    st(d, "init")
    if with_profile:
        (d / "machine.md").write_text(PROFILE)
    return d


CASES = []


def case(fn):
    CASES.append((fn.__doc__ or fn.__name__, fn))
    return fn


@case
def t_init_is_idempotent():
    """init creates the full layout and is safe to re-run"""
    d = fresh(with_profile=False)
    for sub in ("toolbox", "undo", "learn", "reports"):
        assert (d / sub).is_dir(), f"missing {sub}/"
    for f in ("toolbox.json", "visits.log", "ledger.jsonl", "history.md"):
        assert (d / f).exists(), f"missing {f}"
    reg = json.loads((d / "toolbox.json").read_text())
    assert reg == {"tools": [], "declined": []}, reg
    (d / "toolbox.json").write_text('{"tools":[{"name":"keep"}],"declined":["x"]}')
    st(d, "init")
    assert json.loads((d / "toolbox.json").read_text())["tools"][0]["name"] == "keep", \
        "re-running init destroyed existing state"


@case
def t_ledger_rejects_unknown_events():
    """ledger refuses an event outside the documented vocabulary"""
    d = fresh()
    assert st(d, "ledger", "learned", "x").returncode == 0
    r = st(d, "ledger", "DELETED_FOREVER", "x")
    assert r.returncode != 0, "unknown event accepted"


@case
def t_ledger_escapes_json():
    """a quote in a note cannot corrupt the append-only log"""
    d = fresh()
    st(d, "ledger", "learned", 'sub"ject', 'note with " quote and \\ backslash')
    for line in (d / "ledger.jsonl").read_text().splitlines():
        json.loads(line)  # raises if the log was corrupted


@case
def t_demote_is_all_or_nothing():
    """demote updates profile, history and ledger together"""
    d = fresh()
    r = st(d, "demote", "fan loud with many browser tabs", "not reproduced")
    assert r.returncode == 0, r.stderr
    prof = (d / "machine.md").read_text()
    assert "fan loud" not in prof, "belief still in the profile"
    assert "retest: ps -Ao" not in prof, "orphaned retest line left behind"
    assert "wifi weak in back bedroom" in prof, "demote removed an unrelated belief"
    assert "fan loud" in (d / "history.md").read_text(), "not recorded in history"
    events = [json.loads(l) for l in (d / "ledger.jsonl").read_text().splitlines()]
    assert any(e["event"] == "demoted" and "fan loud" in e["subject"] for e in events), events


@case
def t_demote_refuses_unknown_subject():
    """demote fails loudly rather than silently doing nothing"""
    d = fresh()
    before = (d / "machine.md").read_text()
    r = st(d, "demote", "no such belief", "x")
    assert r.returncode != 0, "silently accepted an unknown subject"
    assert (d / "machine.md").read_text() == before, "profile changed on a failed demote"
    assert not (d / "history.md").read_text().count("no such belief"), "history written on failure"


@case
def t_demote_refuses_to_commit_a_critical_profile():
    """validation runs BEFORE the commit, not after"""
    d = fresh()
    (d / "machine.md").write_text(PROFILE + "\n- leaked: vless://abc@203.0.113.9:443\n")
    r = st(d, "demote", "fan loud with many browser tabs", "x")
    assert r.returncode == 4, f"expected refusal (4), got {r.returncode}: {r.stderr}"
    assert "fan loud" in (d / "machine.md").read_text(), "profile mutated despite refusal"


@case
def t_toolbox_registry_survives_concurrent_writers():
    """the lost-update that made a user's 'no' silently reverse"""
    d = fresh()
    errs = []

    def add(i):
        r = st(d, "toolbox-add", f"tool-{i}", f"pattern-{i}", "purpose")
        if r.returncode not in (0, 3):
            errs.append(r.stderr)

    def decline(i):
        r = st(d, "toolbox-decline", f"declined-{i}")
        if r.returncode not in (0, 3):
            errs.append(r.stderr)

    threads = [threading.Thread(target=add if i % 2 else decline, args=(i,))
               for i in range(12)]
    for t in threads: t.start()
    for t in threads: t.join()
    assert not errs, errs
    reg = json.loads((d / "toolbox.json").read_text())   # must still parse
    assert len(reg["tools"]) == 6, f"lost tool writes: {len(reg['tools'])}/6"
    assert len(reg["declined"]) == 6, f"lost declines: {len(reg['declined'])}/6"


@case
def t_visits_log_survives_concurrent_appends():
    """every visit is recorded exactly once under concurrency"""
    d = fresh()
    threads = [threading.Thread(target=lambda i=i: st(d, "visit", "checkup", f"run {i}", "-"))
               for i in range(10)]
    for t in threads: t.start()
    for t in threads: t.join()
    lines = [l for l in (d / "visits.log").read_text().splitlines() if l.strip()]
    assert len(lines) == 10, f"expected 10 visit lines, got {len(lines)}"
    assert len({l.split("|")[2].strip() for l in lines}) == 10, "visits overwrote each other"


@case
def t_declined_is_queryable_and_reversible():
    """a decline is remembered, and asking for the tool clears it"""
    d = fresh()
    st(d, "toolbox-decline", "desktop-screenshots")
    assert st(d, "toolbox-declined", "desktop-screenshots").returncode == 0
    assert st(d, "toolbox-declined", "heic-photos").returncode != 0
    # Building the tool the user later asks for must clear the decline.
    st(d, "toolbox-add", "file-desktop-screenshots", "desktop-screenshots", "files them")
    assert st(d, "toolbox-declined", "desktop-screenshots").returncode != 0, \
        "decline survived the user explicitly asking for the tool"


@case
def t_tool_records_its_pattern():
    """the pattern field, not the tool name, marks a pattern handled"""
    d = fresh()
    st(d, "toolbox-add", "tidy-my-shots", "desktop-screenshots", "files screenshots")
    reg = json.loads((d / "toolbox.json").read_text())
    assert reg["tools"][0]["pattern"] == "desktop-screenshots", reg
    assert reg["tools"][0]["stage"] == "script", reg


@case
def t_stale_lock_is_reclaimed():
    """a lock left by a dead process does not wedge the plugin forever"""
    d = fresh()
    lock = d / ".lock"
    lock.mkdir()
    (lock / "pid").write_text("999999")   # a pid that cannot be alive
    r = st(d, "visit", "checkup", "after stale lock", "-", timeout=40)
    assert r.returncode == 0, f"stale lock not reclaimed: {r.stderr}"


@case
def t_atomic_write_leaves_no_temp_files():
    """no .tmp debris accumulates in the user's visible folder"""
    d = fresh()
    for i in range(5):
        st(d, "toolbox-add", f"t{i}", f"p{i}", "x")
    leftovers = [p.name for p in d.iterdir() if ".tmp." in p.name]
    assert not leftovers, f"temp files left behind: {leftovers}"


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
