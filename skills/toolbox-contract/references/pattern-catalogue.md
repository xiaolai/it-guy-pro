# Pattern Catalogue — offering tools the user didn't know to ask for

The gap this closes: **nobody asks for an automation they don't know exists.** `/it-guy-pro:automate` waits to be told about a chore, which works for users who already think in terms of automatable work and fails for everyone else. This catalogue lets the IT guy notice the chore first and offer it, using a number from the user's own machine.

Each pattern has an **id** (recorded on decline), a **signal** (command plus threshold), an **offer** (one sentence containing the real number), and a **recipe** (what to build, and the gotchas). Verified on macOS 29 July 2026.

## How many offers, and when — by context

The limits differ by command because the contexts differ, and a rule that ignores that produces either spam or silence in the wrong place.

| Command | Offers allowed | Health interaction |
|---|---|---|
| `checkup` | **At most one**, appended below the single recommended next step | **None at all if any 🔴 is open.** A full disk or missing backup must not compete with a convenience |
| `onboard` | **At most one**, occupying at most one of the three ranked slots | Allowed alongside 🔴 items, but **always ranked below them.** A ranked list of three does not bury anything; a menu is what the user expects on a first visit |
| `toolbox` | **Up to three**, highest count first | Skip if a 🔴 was just reported in the same session |
| `automate` | None unsolicited — the user is already describing a chore | — |

## The rules that keep this from becoming nagging

Binding everywhere. A suggestion engine that ignores them is spam, and a user who feels sold to stops trusting the diagnosis too.

1. **Quote their number, never a pitch.** "I noticed 213 screenshots piled up on your Desktop — want me to file those automatically?" Not "I can help automate your file management!" The number makes it recognition rather than a sales line.
2. **A decline is permanent.** Append the pattern's **id** — the code in backticks, not the recipe name — to `declined` in `~/ITGuy/toolbox.json`. **If that file does not exist, create it as `{"tools": [], "declined": []}` before writing.** Never raise a declined pattern again. Remove the entry only if the user later asks for that tool themselves.
3. **Never offer what exists.** Skip a pattern if any registry entry has a matching `pattern` field. Because `/automate` lets users name tools freely, the `pattern` field — not the tool's name — is what marks a pattern as handled; always set it when building from a catalogue recipe.
4. **When several offers are shown at once** (toolbox only), a decline is recorded **only for patterns the user explicitly rejects** — choosing "none of these" declines all shown; picking one records nothing about the others, which stay eligible next time.
5. **Below threshold means silence.** Thresholds mark where a chore becomes genuinely recurring.
6. **Recent, not historical.** Every signal below pairs a total count with a 30-day count. **If the 30-day count is zero the chore is not recurring** — it is a one-time tidy-up, so point at `/it-guy-pro:organize` instead and offer no tool.
7. **Check for an existing system.** If the destination folders already exist and are organised, someone has a system; offering to automate it is an insult dressed as help. Ask whether they want it faster, or say nothing.
8. **Profile Conventions win.** Where `~/ITGuy/machine.md` records the user's filing habits, those destinations override the defaults below — same precedence the `librarian` agent uses.

## The patterns

All signals are read-only and need no admin rights. Run them only where scanning is already justified (a checkup, onboarding, or a toolbox review), never speculatively.

### `desktop-screenshots`

```bash
find ~/Desktop -maxdepth 1 -type f \( -iname 'screenshot*' -o -iname 'screen shot*' -o -name 'SCREENSHOT*' -o -name 'SCREENCAP*' \) 2>/dev/null | wc -l
find ~/Desktop -maxdepth 1 -type f \( -iname 'screenshot*' -o -iname 'screen shot*' -o -name 'SCREENSHOT*' -o -name 'SCREENCAP*' \) -mtime -30 2>/dev/null | wc -l
```

**Threshold:** 20 total, and the 30-day count above zero. **Offer:** "I found N screenshots sitting on your Desktop — want me to build something that files them into Pictures by month, so they stop collecting there?"

**Recipe — `file-desktop-screenshots`:** move to `~/Pictures/Screenshots/<YYYY>/<YYYY-MM>/`, matching the `librarian` agent's scheme so the tool and `/it-guy-pro:organize desktop` never fight over the same files. Write an undo manifest first. Dates come from `mdls` — see the two date gotchas below. A strong candidate for the scheduled stage later; this chore recurs daily.

### `heic-photos`

```bash
find ~/Pictures ~/Downloads ~/Desktop -maxdepth 2 -type f -iname '*.heic' 2>/dev/null | wc -l
find ~/Pictures ~/Downloads ~/Desktop -maxdepth 2 -type f -iname '*.heic' -mtime -30 2>/dev/null | wc -l
```

**Threshold:** 10 total, 30-day count above zero. **Offer:** "You have N iPhone photos in a format Windows and older software can't open — want a tool that makes shareable JPG copies on demand?"

**Recipe — `convert-heic-to-jpg`:** keep the original `.heic` always; this makes copies and never converts in place.

**⚠️ `sips --out` overwrites an existing file silently and exits 0.** A camera that saved `IMG_1234.HEIC` alongside `IMG_1234.JPG`, or a second run of this tool, destroys the existing JPG with no warning. **Collision-check before every call:**

```bash
out="${f%.*}.jpg"; n=2
while [ -e "$out" ]; do out="${f%.*} ($n).jpg"; n=$((n+1)); done
sips -s format jpeg "$f" --out "$out"
```

### `camera-named-photos`

```bash
find ~/Pictures ~/Desktop ~/Downloads -maxdepth 2 -type f \( -iname 'IMG_*.jp*g' -o -iname 'DSC*.jp*g' -o -iname 'PXL_*.jp*g' \) 2>/dev/null | wc -l
find ~/Pictures ~/Desktop ~/Downloads -maxdepth 2 -type f \( -iname 'IMG_*.jp*g' -o -iname 'DSC*.jp*g' -o -iname 'PXL_*.jp*g' \) -mtime -30 2>/dev/null | wc -l
```

**Threshold:** 50 total, 30-day count above zero. **Offer:** "N of your photos are still named things like IMG_4032, which makes them impossible to find later — want them renamed by the date they were taken?"

**Recipe — `rename-photos-by-date`:** rename in place to `YYYY-MM-DD-<original>.jpg`. Undo manifest first. Never overwrite; append ` (2)` on collision. Renaming in place is deliberate — moving these is `/it-guy-pro:organize photos`, and two tools must not both claim the move.

### `oversized-images`

```bash
find ~/Desktop ~/Downloads ~/Documents -maxdepth 3 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -size +5M 2>/dev/null | wc -l
find ~/Desktop ~/Downloads ~/Documents -maxdepth 3 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -size +5M -mtime -30 2>/dev/null | wc -l
```

**Threshold:** 10 total, 30-day count above zero. **Offer:** "N of your images are over 5 MB, which is why some of them bounce back from email — want a tool that makes small shareable copies?"

**Recipe — `shrink-images-for-sharing`:** write `-web.jpg` copies; originals untouched.

**⚠️ Two sips traps, both verified.** `--setProperty formatOptions` is a JPEG quality control and is **ignored when the output stays PNG** — so always force JPEG for the shareable copy rather than preserving the input format. And **`-Z` upscales as well as downscales**: a 400 px image becomes 2048 px and grows an order of magnitude. Skip any file already within the target box:

```bash
w=$(sips -g pixelWidth  "$f" | awk 'END{print $2}')
h=$(sips -g pixelHeight "$f" | awk 'END{print $2}')
[ "$w" -le 2048 ] && [ "$h" -le 2048 ] && continue     # already small enough
sips -s format jpeg -Z 2048 --setProperty formatOptions 70 "$f" --out "${f%.*}-web.jpg"
```

### `downloads-sprawl`

```bash
find ~/Downloads -mindepth 1 -maxdepth 1 -type f 2>/dev/null | wc -l
find ~/Downloads -mindepth 1 -maxdepth 1 -type f -mtime +90 2>/dev/null | wc -l
```

**Threshold:** 200 files, or 50+ unmodified for 90 days. **Offer:** "Your Downloads folder has N files, M of them older than three months — want me to build something that files new downloads by type and year automatically?"

**Note the deliberate use of `-mtime`, not `-atime`.** Access time is bumped by Spotlight indexing, backup scans, antivirus, QuickLook and cloud-sync agents, so an `-atime` count is unstable between runs and cannot honestly be described to the user as "files you haven't opened." Do not promise that phrasing.

**Recipe — `file-downloads-by-type`:** sort into `~/Downloads/<Year>/<Installers|Documents|Images|Archives|Media|Other>/`, matching the `librarian` scheme. Undo manifest first. **Never delete** — clearing old downloads is a `/it-guy-pro:cleanup` decision the user makes explicitly.

### `duplicate-copies`

```bash
find ~/Desktop ~/Downloads ~/Documents -maxdepth 3 -type f \( -name '* copy*' -o -name '*([0-9])*' \) 2>/dev/null | wc -l
```

**Threshold:** 20. No recency companion — duplicates are worth clearing whenever they accumulate.

**⚠️ Do not widen this glob to `* [0-9].*`.** That form matches the `" 4."` inside `Screenshot 2026-07-28 at 4.20.03 AM.png`, plus every version number and audio-channel count (`MetroCity 2.0.rar`, `… 5.1 BONE.mkv`). Measured on a real machine it produced 74 false positives against 2 genuine hits — and since offers are ranked by count, the least accurate pattern would win the single available slot every time, quoting a fabricated number at the user. The two branches kept here cover Finder's ` copy` and browsers' `(1)` forms; measured on the same machine they reach **64% precision** (30 of 47 matches had a real same-name sibling), which is an acceptable prefilter given the checksum pass makes the final call.

**Offer:** "I found N files with names like 'report copy.pdf' — want a tool that checks which are genuinely identical and shows you the extras?"

**Recipe — `find-duplicate-copies`:** the filename is only a cheap prefilter. **Confirm by size then `md5 -q` before calling anything a duplicate** — "report (2).pdf" is very often a different document. Present confirmed groups and let the user choose what to keep; move only approved extras to the Trash, never `rm`. **This tool stays at the script stage permanently — never schedule it**, since unattended duplicate deletion is how people lose work.

### `loose-pdfs`

```bash
find ~/Desktop ~/Downloads -maxdepth 1 -type f -iname '*.pdf' 2>/dev/null | wc -l
find ~/Desktop ~/Downloads -maxdepth 1 -type f -iname '*.pdf' -mtime -30 2>/dev/null | wc -l
```

**Threshold:** 30 total, 30-day count above zero. **Offer:** "You have N PDFs loose in Downloads and on the Desktop — want them sorted into invoices, contracts and papers? I'll leave anything I'm unsure about in an Unsorted folder rather than guessing."

**Recipe — `sort-pdfs-by-content`:** classify on first-page text, never the filename. Undo manifest first.

**⚠️ Extraction mechanism matters, because the obvious choices silently fail.** `mdls -name kMDItemTextContent` returns `(null)` per-file (it is a Spotlight query attribute, not readable this way), `textutil` cannot read PDFs, and the standard library has no PDF parser. The working built-in is PDFKit through JXA:

```bash
osascript -l JavaScript -e 'ObjC.import("Quartz"); function run(a){
  var u=$.NSURL.fileURLWithString(a[0]); var d=$.PDFDocument.alloc.initWithURL(u);
  return d.isNil()?"":d.pageAtIndex(0).string.js.substring(0,2000);}' "$pdf"
```

**Scanned-image PDFs have no text layer at all**, so this returns empty for exactly the files a scanner produces. That is why the offer promises an Unsorted folder up front — say it before building, not after the user discovers half their files went there.

### `desktop-sprawl`

```bash
find ~/Desktop -mindepth 1 -maxdepth 1 2>/dev/null | wc -l
```

**Threshold:** 60 items, **and** `desktop-screenshots` below its own threshold — otherwise offer that one, which is the more specific diagnosis.

**Offer:** "There are N items on your Desktop, which slows Finder down and makes things hard to find — want a tool that files them by type into a Filed folder?"

**Recipe — `file-desktop-by-type`:** same destination scheme as the downloads tool, under `~/Desktop/Filed/`. Undo manifest first. Leave aliases, user-created folders, and anything modified today where they are — an active workspace is not clutter.

## Two date gotchas every photo recipe hits

Both verified, both silent when wrong:

- **`mdls` returns the literal string `(null)`**, not an empty string, when an attribute is missing. A naive `[ -z "$d" ]` check passes it straight through into a filename. String-compare against `(null)` explicitly.
- **`mdls` reports UTC.** A screenshot taken 2026-07-28 04:20 local reads `2026-07-27 20:20:08 +0000`, so filing on the raw string misfiles anything captured near a day or month boundary. Convert to local time before using it as a folder or filename.

Where a capture date is genuinely unavailable, fall back to file creation date **and label that fallback in the preview** — a copy date presented as a shoot date is a quiet lie the user will not catch.

## Adding a pattern

A new entry earns its place only with: an `id`; a signal that is a real command with a defensible threshold and a recency companion; an offer sentence containing the observed number; a recipe buildable from macOS built-ins with no new dependencies, **with its failure modes tested rather than assumed**; and a clear statement of when *not* to build it. A pattern that cannot state its own counter-indication is a sales pitch, not a diagnosis.
