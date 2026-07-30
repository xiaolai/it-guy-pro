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

Updated: YYYY-MM-DD by /mac-it-guy-pro:<command>
Summon: _it
IT guy: <his name, or omit the line entirely>

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
- Language: <the language to answer in, e.g. English, Chinese, Spanish> (you told me YYYY-MM-DD)
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

## Field labels are English — always

**Every heading and field label in this file stays in English, whatever language the user is answered in.** Values may be in their language; labels may not. This is a correctness requirement, not a style choice: the SessionStart digest greps for `^Summon: `, `^- Call me: ` and `^- Language: `, and a translated label silently disables the feature it names. The same holds for `history.md` event words and `ledger.jsonl` keys.

So a `- Call me:` line whose *value* is written in the user's own script is correct. Translating the `Call me` label itself is a bug that fails quietly — the digest stops finding it, and the user simply stops being addressed by name with no error anywhere.

## The `Language` line

`- Language: <language>` is how the user wants to be **answered** — reports, explanations, offers, and the prose of learning maps. It is a told-class fact: set at onboarding, changed only by `/mac-it-guy-pro:profile update`, never inferred over the top of what they chose.

When the line is absent, match the language the user is writing in. When it is present, it wins even if they type in another language, because a person may write a command in English and still want the explanation in their own language.

Technical terms stay in English with a short gloss in the user's language on first use, written as the translated phrase followed by the English term in parentheses. The user needs the English term to search for it later; hiding it behind a translation makes them dependent on you.

## The `IT guy` line

What the user calls him. Set at onboarding, changed only by `/mac-it-guy-pro:profile update`, and the line is omitted entirely when the user declines a name — an unnamed IT guy works identically.

**A name creates a second summon.** `IT guy: Alan` means `_alan` reaches him just as `_it` does, and both ignore capitalisation. The digest derives it from the first word of the name, ASCII-lowercased with spaces and punctuation dropped, so `Mary-Jane O'Brien` yields `_mary-jane`.

Both stay underscore-led on purpose: the trigger remains mechanical, so a sentence *about* someone of that name summons nothing and no judgement is involved. `_it` always works too, which is what lets the convention be taught in one sentence to every user regardless of the name they chose.

The summon word is always `_it` (or the profile's `Summon:` value) regardless of his name. That separation is deliberate: in an earlier design the name *was* the trigger, which meant a common name caused false summons and every user had a different one to remember. Decoupling them means he can be called anything, including a name shared with a real person, with no mechanical consequence.

When he has a name he introduces himself with it and signs off with it; he does not repeat it in every message.

## The `Summon` and `Call me` lines

`Summon: _it` is the word that calls the IT guy from any session; a different word must keep the leading underscore. The `Summon: ` prefix matters — the SessionStart digest greps for it. `- Call me:` in Owner is how the user is addressed. Both change only via `/mac-it-guy-pro:profile update`.

## The `Private Connection` section

Written only by `/mac-it-guy-pro:open-internet`; omit entirely when no server exists. `Status` is what other commands branch on: `working` means verified on the date in `Last verified`, `blocked` means diagnosed and unfixed, `needs setup` means started but unfinished. **A `working` status older than 60 days is stale, not evidence** — re-verify before relying on it.

**Never record here or anywhere in `~/ITGuy/`:** the share link, UUID, keys, shortId, server password, or SSH key.

## `~/ITGuy/visits.log`

Append-only, one line per command run, format in the `it-core` skill. Never edit or delete existing lines.

## Undo manifests — `~/ITGuy/undo/`

Before any batch move or rename, write `<YYYY-MM-DD-HHMM>-<command>-<mode>.csv` with header `moved_from,moved_to`, one row per file, absolute paths, **written before the first move executes**.

To undo: process rows in reverse, move `moved_to` back to `moved_from`, skip rows whose destination is gone, and report every skip. Keep the 20 most recent manifests; move older ones to the Trash during cleanup.
