#!/usr/bin/env bash
# Build every bitmap font the face uses, for every screen size.
#
# The row and small fonts carry the text, so they need the letters of every
# language a Garmin watch can be set to. The date comes from the system in the
# watch language, and a letter that is not in the atlas is drawn as nothing.
# The big font shows the time, so it only needs digits and a colon.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
py="$here/.venv/bin/python"
ttf=${TTF:-/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf}
icons="U+E34C,U+E34D,U+F240,U+E30D"

# ASCII, then the letters of the Latin, Greek and Cyrillic alphabets.
text_chars=$("$py" - <<'PY'
import sys, unicodedata
out = ["0123456789", "abcdefghijklmnopqrstuvwxyz",
       "ABCDEFGHIJKLMNOPQRSTUVWXYZ", " :=%.,-+/°"]
# Latin-1 Supplement, Latin Extended-A, Greek and Cyrillic: letters only.
ranges = [(0x00C0, 0x00FF), (0x0100, 0x017F), (0x0386, 0x03CE), (0x0400, 0x045F)]
extra = []
for lo, hi in ranges:
    for cp in range(lo, hi + 1):
        ch = chr(cp)
        if unicodedata.category(ch).startswith("L"):
            extra.append(ch)
sys.stdout.write("".join(out) + "".join(extra))
PY
)

gen() {  # gen <size-dir> <big> <row> <small>
    local dir="$repo/resources-round-${1}x${1}/fonts"
    "$py" "$here/mkfont.py" --ttf "$ttf" --size "$2" --out "$dir" --name jbmbig \
        --bold --chars "0123456789: "
    "$py" "$here/mkfont.py" --ttf "$ttf" --size "$3" --out "$dir" --name jbmrow \
        --chars "$text_chars" --extra-codepoints "$icons"
    "$py" "$here/mkfont.py" --ttf "$ttf" --size "$4" --out "$dir" --name jbmsmall \
        --chars "$text_chars" --extra-codepoints "$icons"
}

gen 360 78 16 12
gen 390 84 17 13
gen 416 90 18 14
gen 454 98 20 15
gen 466 100 20 16
