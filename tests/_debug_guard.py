#!/usr/bin/env python3
"""Throwaway tracer: show what the guard computes for one command."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GUARD = ROOT / "scripts" / "guard.sh"

cmd = sys.argv[1] if len(sys.argv) > 1 else 'bash -c "rm -rf $HOME/Documents"'

payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd, "description": "x"}})
r = subprocess.run(["bash", str(GUARD)], input=payload, capture_output=True, text=True)
verdict = "DENY" if r.returncode == 2 else ("ASK" if "ask" in r.stdout else "ALLOW")
print(f"command : {cmd}")
print(f"verdict : {verdict}")
print(f"stderr  : {r.stderr.strip()[:160]}")

# Reproduce the guard's own intermediate values.
def sh(script):
    return subprocess.run(["bash", "-c", script], capture_output=True, text=True).stdout.rstrip("\n")

norm = sh(f'''printf '%s' {json.dumps(cmd)} | tr -d '"\\047\\\\' | sed -e 's/\\${{HOME}}/~/g' -e 's/\\$HOME/~/g' -e 's|~[a-zA-Z_][a-zA-Z0-9_.-]*/|~/|g' -e 's|/\\./|/|g' -e 's|///*|/|g' ''')
print(f"norm    : {norm}")

PROT = r"(~|\$HOME|/Users/[^/[:space:]\"']+)/(Documents|Desktop|Downloads|Pictures|Movies|Music|Library|ITGuy)"
hit = subprocess.run(["grep", "-qE", PROT], input=norm, capture_output=True, text=True).returncode
print(f"PROT matches norm? {'yes' if hit == 0 else 'NO  <-- this is why nothing fires'}")
