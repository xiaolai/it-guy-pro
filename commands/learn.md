---
name: learn
description: "Understand what just happened, or study a whole topic — mental models built from your own machine, not generic tutorials"
argument-hint: "[why|<topic>|list]"
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion, WebSearch, WebFetch
---

# Learn — the model, not the manual

Read `${CLAUDE_PLUGIN_ROOT}/skills/tutoring/SKILL.md` first — the two modes, the grounding rule, the ten-section structure, the dating rule, and the language rule are binding. Read `~/ITGuy/machine.md` if it exists, for the user's language preference and for real numbers to teach from.

The user does not need to memorise commands. **Build the model that lets them decide** — when to worry, what to check first, what to buy, what to ignore, what to automate next.

Resolve from `$ARGUMENTS`: `why` · a topic · `list` · empty.

## empty — offer what their machine has already taught them

Do not ask "what would you like to learn?" A user who could answer that does not need this command. Instead, derive candidates from what they have actually met:

1. Read `~/ITGuy/visits.log` (what was done), `ledger.jsonl` (what was believed and revised), the profile's Live Conclusions and Watch List, and `toolbox.json` (what they automated).
2. Turn each into a candidate phrased as *their* experience, not a subject name: "Why your Downloads folder keeps filling up" rather than "File system management." "What that Wi-Fi measurement actually meant" rather than "802.11 fundamentals."
3. Offer at most four with AskUserQuestion, plus an "something else" option that accepts a free-text topic.
4. Mark anything already in `~/ITGuy/learn/` as a re-read rather than a new map.

If there is no history at all, say so honestly and offer the three domains this plugin covers — keeping your Mac healthy, your home network, and automating chores — as a starting menu.

## why — just-in-time, the mode that matters most

Explain what just happened and why it was the fix. Scope is the current session and the last entries in `visits.log`.

- **One or two paragraphs. No sections, no diagrams, no reading assignment.**
- Ground it in the actual numbers that were measured, not in an abstraction.
- Say what the user should now recognise next time — the signal, not the procedure.
- Close with one offer at most: a full map on the topic, if one would genuinely add something.

If nothing notable happened recently, say so rather than manufacturing a lesson.

## &lt;topic&gt; — deliberate study

1. **Check for an existing map** at `~/ITGuy/learn/<topic>.md`. If present, re-read it, re-verify only the sections dated as changing knowledge, and report which parts you checked and what moved. Do not regenerate a map that is still sound.
2. **Gather the user's own evidence** for this topic from the profile, ledger, and visit log, so the map opens with their machine rather than an abstraction.
3. **Consult the plugin's own skills first** — they are verified and carry stated uncertainty. `home-network` for Wi-Fi and LAN, `open-internet` for access and protocols, `macos-recipes` and `it-core` for machine care, `toolbox-contract` for automation. Use the web only for what the skills do not cover, and prefer the authoritative sources those skills name over open search.
4. **Write the ten-section map** per the tutoring skill, with review-by dates on the changing-knowledge half and no dates on the principles.
5. **Save** to `~/ITGuy/learn/<topic>.md`, tell the user the path, and append a `learned` event to `ledger.jsonl` naming the topic.

Carry the source skills' uncertainty into the map. Where they say no credible measurement exists or that sources conflict, the map says so too.

## list

Show what is in `~/ITGuy/learn/` — topic, written date, and whether its changing-knowledge sections are past review. Offer to refresh anything overdue. If empty, point at the `empty` flow above rather than at a blank directory.

## Language

Respond in the user's `- Language:` preference from the profile, or match the language they are writing in if none is set. **Everything written to disk keeps English structure** — file names, headings, field labels, code — while the prose body is in their language. Keep technical terms in English with a gloss on first use, so the user can still search for them.

## All modes

Append the visit line to `~/ITGuy/visits.log`. Never write a lesson into `machine.md`; maps live in `~/ITGuy/learn/`, and the profile records only that a topic was studied.

## Errors

- Topic outside this plugin's domains (it is a Mac, network, and automation tutor, not a general encyclopedia) → say so, and offer the nearest thing it does cover.
- No profile yet → the map still works; it just opens with a generic example, and you should say that onboarding would let it use their real numbers.
- A requested re-verification needs the web and it is unavailable → deliver the map with the changing-knowledge sections marked unverified and dated, rather than silently presenting stale figures as current.
