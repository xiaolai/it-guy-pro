---
name: machine-profile
description: How the IT guy remembers, refreshes, and retires what it knows about this machine — the profile schema, provenance classes, expiry by evidence, the belief ledger, demotion to history, the visit log, and undo manifests. Load when reading, writing, reviewing, or pruning anything in ~/ITGuy/.
---

# Machine Profile — memory that expires honestly

The profile is the IT guy's memory. It is plain Markdown the user can open, read, and edit — never a hidden database. Everything in it must be something they could verify themselves.

**The failure mode this schema exists to prevent:** ten commands write here and, without discipline, none retire anything. A profile that only grows becomes a landfill of half-true statements, and stale beliefs are worse than no beliefs — a conclusion drawn a year ago and never retested silently biases every future diagnosis toward a cause that may no longer exist.

## Provenance decides expiry — tag every fact

How a fact was learned determines how it dies. Tag each one inline; the tag is part of the line, not metadata elsewhere.

| Class | Written as | Lifecycle |
|---|---|---|
| **Measured** | `(measured 2026-07-29)` | **Never trusted as current.** Disk space, memory, macOS version, battery. The stored number is a *baseline to compare against*, not a fact — any command needing the value re-reads it. Refresh the date whenever re-read |
| **Observed** | `(observed 2026-07-29)` | Cheap to re-observe: file counts, folder habits, dominant file types. Refresh on the next command that looks |
| **Told** | `(you told me 2026-07-29)` | The user's own words: name, work, goals, preferences. **Only the user may invalidate these.** Never auto-expire, never quietly rewrite |
| **Concluded** | `(concluded 2026-07-29, retest by 2026-10-29)` | **The dangerous class.** A diagnosis, a quirk, a cause-and-effect the IT guy inferred. Every one carries a retest date and a way to retest — see below |
| **Resolved** | moves to `history.md` | No longer live. Demoted with the date and what closed it |

A fact with no tag is a bug. When you find one, tag it with what you can establish and today's date, or demote it.

## Conclusions must carry their own retest

This is the rule that keeps the profile honest. A conclusion without a retest is a rumour with a date on it.

```markdown
- 2026-07-29 · fan runs loud when Chrome has many tabs (concluded 2026-07-29, retest by 2026-10-29)
  retest: ps -Ao pcpu,comm -r | head -5 while the user reports the noise
```

When the retest date passes, the next checkup re-runs it and takes one of three actions, always recording the outcome in the ledger:

- **Reproduced** → re-date it, push the retest date out, keep it live.
- **Not reproduced** → demote to `history.md` as "no longer observed", and say so to the user. This is how stale information actually gets ripped out: by evidence, not by age.
- **Cannot retest** (hardware gone, user unavailable) → mark `unverifiable` and demote after a second attempt. Do not keep a belief alive that nothing can ever check.

## Demote, never delete

Pruning exists to control **context cost**, not to save disk. So stale facts move out of the live profile into `~/ITGuy/history.md`, which is never loaded into context by default and grows without limit.

Deleting is forbidden because it destroys the ability to explain a past decision — "why did the IT guy replace that router?" must remain answerable. The one exception is data that should never have been stored (a password, an address, a serial number): that is deleted outright, from history too, and the ledger records that a redaction happened without repeating the value.

**Cap: 120 lines for `machine.md` only.** When over, demote in this order: resolved items, then conclusions past retest, then observations older than 180 days, then the oldest measurements. **Never demote told-class facts to make room** — ask the user instead.

## `~/ITGuy/machine.md`

```markdown
# This Machine

Updated: YYYY-MM-DD by /it-guy-pro:<command>
Summon: _it

## Hardware
- Model: <e.g. MacBook Air M2, 2022> (measured YYYY-MM-DD)
- Memory: <e.g. 16 GB> (measured YYYY-MM-DD)
- Disk: <total, free> (measured YYYY-MM-DD)
- Battery: <cycles + condition, or "desktop"> (measured YYYY-MM-DD)

## System
- macOS: <version> (measured YYYY-MM-DD)
- Backups: <destination + last run, or "NONE — flagged"> (measured YYYY-MM-DD)

## Owner
- Call me: <name> (you told me YYYY-MM-DD)
- Work: <what they use it for> (you told me | observed YYYY-MM-DD)
- Comfort level: <beginner | comfortable | technical> (observed YYYY-MM-DD)

## Conventions
- <filing/naming habit> (observed YYYY-MM-DD)

## Private Connection
- Status / provider / architecture / client / renews / last verified   (see below)

## Live Conclusions
- YYYY-MM-DD · <quirk or diagnosis> (concluded YYYY-MM-DD, retest by YYYY-MM-DD)
  retest: <the command or observation that would confirm it>

## Watch List
- <thing to re-check next visit> (measured|observed YYYY-MM-DD, due YYYY-MM-DD)
```

Fill hardware and system fields from real commands, never guesses. Fill Owner and Conventions from what the user actually said or what was observed — and label which.

**Never store:** passwords, serial numbers, IP addresses, MAC addresses, Wi-Fi names, network topology, account emails, or any toolbox credential. If the user volunteers one, leave it out and say why in one sentence.

## `~/ITGuy/history.md`

Append-only, newest first, never loaded into context unless the user asks a "what did you used to think" question.

```markdown
- 2026-10-29 · demoted · fan loud with many Chrome tabs · not reproduced on retest
- 2026-09-02 · resolved · disk 92% full · cleanup freed 68 GB
```

## `~/ITGuy/ledger.jsonl` — tracing what changed and why

Append-only, one JSON object per belief event. This is distinct from `visits.log`, and the distinction matters: **the visit log records what was _done_; the ledger records what was _believed_.** Together they answer "why does the IT guy think this, and when did that change?"

```jsonl
{"ts":"2026-07-29","event":"learned","subject":"fan-loud-chrome","class":"concluded","by":"fix","note":"CPU 180% on Chrome during report"}
{"ts":"2026-10-29","event":"retested","subject":"fan-loud-chrome","result":"not reproduced","by":"checkup"}
{"ts":"2026-10-29","event":"demoted","subject":"fan-loud-chrome","to":"history.md"}
{"ts":"2026-11-02","event":"changed","subject":"disk-free","from":"41 GB","to":"180 GB","by":"cleanup"}
```

Events: `learned` · `confirmed` · `changed` · `retested` · `demoted` · `corrected` (the user fixed something) · `redacted`. Keep notes short and never put a secret in one.

**What this buys that the profile alone cannot:** the profile shows what is believed *now*; the ledger shows what was checked and found unchanged — most of the work, and otherwise invisible. It also exposes flip-flops: a belief that oscillates means the observation is unreliable, not that the machine keeps changing.

## Contradiction is the highest-value event

When a fresh observation conflicts with a stored belief, surface it rather than silently overwriting — that is the moment the memory earns its keep:

> "You told me in March this is mainly for writing, but most of what you've saved recently is photos. Should I update that?"

Record the outcome as `corrected` (user changed it) or `confirmed` (belief stands). Never resolve a contradiction against a told-class fact on your own authority.

## The `Summon` and `Call me` lines

`Summon: _it` is the word that calls the IT guy from any session; a different word must keep the leading underscore. The `Summon: ` prefix matters — the SessionStart digest greps for it. `- Call me:` in Owner is how the user is addressed. Both change only via `/it-guy-pro:profile update`.

## The `Private Connection` section

Written only by `/it-guy-pro:open-internet`; omit entirely when no server exists. `Status` is what other commands branch on: `working` means verified on the date in `Last verified`, `blocked` means diagnosed and unfixed, `needs setup` means started but unfinished. **A `working` status older than 60 days is stale, not evidence** — re-verify before relying on it.

**Never record here or anywhere in `~/ITGuy/`:** the share link, UUID, keys, shortId, server password, or SSH key.

## `~/ITGuy/visits.log`

Append-only, one line per command run, format in the `it-core` skill. Never edit or delete existing lines.

## Undo manifests — `~/ITGuy/undo/`

Before any batch move or rename, write `<YYYY-MM-DD-HHMM>-<command>-<mode>.csv` with header `moved_from,moved_to`, one row per file, absolute paths, **written before the first move executes**.

To undo: process rows in reverse, move `moved_to` back to `moved_from`, skip rows whose destination is gone, and report every skip. Keep the 20 most recent manifests; move older ones to the Trash during cleanup.
