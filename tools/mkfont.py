#!/usr/bin/env python3
"""mkfont.py - Convert a TTF font into AngelCode BMFont format (.fnt + .png)
for the Garmin Connect IQ SDK's custom <font> resource.

RUNTIME: this machine has Pillow installed only in the project-local venv,
not for the system python3. Run this script with:

    /home/jasasonc/Personal/omarchy-watchface/tools/.venv/bin/python \
        tools/mkfont.py --ttf ... --size 18 --out DIR --name NAME

Do NOT `pip install pillow` system-wide or create another venv - use the
one that already exists at tools/.venv.

FORMAT NOTES (reverse-engineered from the Connect IQ 9.2.0 SDK docs and
from samples/Analog/resources/resource/fonts/blackdiamond.fnt, a real
BMFont export shipped with the SDK):

  - The .fnt is the plain-text AngelCode BMFont format (not XML/binary).
  - The referenced page PNG must be 8-bit GRAYSCALE with NO alpha channel
    (PIL mode "L"). Connect IQ only supports one color per custom font;
    the single gray channel is read as glyph coverage/intensity (0 =
    background, 255 = fully-drawn pixel), and the color drawn on screen is
    whatever dc.setColor() set before drawText(). This matches the SDK doc:
    "the font's PNG is a grayscale image and therefore has only one
    channel." So glyphs are rendered white-on-black here, not
    white-on-transparent RGBA - a 32-bit RGBA export also works with
    BMFont's own tool, but the file shipped in the SDK samples is plain 8-bit
    grayscale, so that's what this script produces to match SDK convention.
  - common line's alphaChnl=1 redChnl=0 greenChnl=0 blueChnl=0 and each
    char's chnl=15 are copied verbatim from the SDK sample; they are
    BMFont bookkeeping fields carried over from its internal channel model
    and are not meaningfully interpreted by the Connect IQ resource
    compiler for a single-channel grayscale PNG, but are included for
    format fidelity in case a stricter parser checks them.
  - No kernings section is emitted. Kerning pairs are optional in the
    AngelCode spec, the resource compiler does not require them, and the
    task's character set does not call for a hand-tuned kerning table.
  - The resource compiler resamples the source PNG into a 1-bit glyph
    bitmap by default (memory saving) unless the <font> tag in
    resources.xml sets antialias="true", in which case it keeps grayscale
    levels for anti-aliasing. That's an attribute of the resources.xml
    <font> element, not of this script's output.
"""
import argparse
import math
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print(
        "ERROR: Pillow (PIL) is not installed for this Python interpreter.\n"
        "Run this script with the project venv instead of system python3:\n"
        "  /home/jasasonc/Personal/omarchy-watchface/tools/.venv/bin/python "
        "tools/mkfont.py ...\n"
        "Do not install Pillow system-wide.",
        file=sys.stderr,
    )
    sys.exit(1)


DEFAULT_CHARS = (
    "0123456789"
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    " :=%.,-+/°"  # space : = % . , - + / degree-sign
)

MARGIN = 1  # px between packed glyphs in the atlas, matches BMFont's default spacing=1,1


def parse_args():
    p = argparse.ArgumentParser(
        description="Convert a TTF font into an AngelCode BMFont (.fnt + .png) "
        "pair for the Garmin Connect IQ SDK."
    )
    p.add_argument("--ttf", required=True, help="Path to the source .ttf file")
    p.add_argument("--size", required=True, type=int, help="Font size in pixels")
    p.add_argument("--out", required=True, help="Output directory")
    p.add_argument("--name", required=True, help="Base name for NAME.fnt / NAME.png")
    p.add_argument(
        "--chars",
        default=None,
        help="Exact character set to render (overrides the default set). "
        "The default is: digits, lowercase+uppercase letters, space, "
        "and : = %% . , - + / °",
    )
    p.add_argument(
        "--extra-codepoints",
        default=None,
        dest="extra_codepoints",
        help="Comma-separated Unicode codepoints to add, e.g. "
        "U+E34C,U+E34D,U+F240 (useful for Nerd Font private-use glyphs)",
    )
    p.add_argument(
        "--bold",
        action="store_true",
        help="Prefer a Bold sibling of --ttf if one exists next to it "
        "(e.g. swaps *-Regular.ttf for *-Bold.ttf); otherwise uses --ttf as given.",
    )
    return p.parse_args()


def parse_codepoints(spec):
    out = []
    for tok in spec.split(","):
        tok = tok.strip()
        if not tok:
            continue
        if tok.upper().startswith("U+"):
            tok = tok[2:]
        out.append(int(tok, 16))
    return out


def resolve_bold_path(ttf_path):
    """Best-effort: look for a Bold sibling of ttf_path next to it."""
    directory, filename = os.path.split(ttf_path)
    lower = filename.lower()
    if "bold" in lower:
        return ttf_path  # already a bold file
    candidates = []
    if "regular" in lower:
        candidates.append(filename[: lower.index("regular")] + "Bold" + filename[lower.index("regular") + len("regular") :])
    stem, ext = os.path.splitext(filename)
    candidates.append(stem + "-Bold" + ext)
    candidates.append(stem + "Bold" + ext)
    for cand in candidates:
        cand_path = os.path.join(directory, cand)
        if os.path.isfile(cand_path):
            return cand_path
    return None


def build_char_list(chars_arg, extra_codepoints_arg):
    """Returns an ordered list of (char_str, codepoint) with no duplicate codepoints."""
    base = chars_arg if chars_arg is not None else DEFAULT_CHARS
    seen = set()
    result = []
    for ch in base:
        cp = ord(ch)
        if cp in seen:
            continue
        seen.add(cp)
        result.append((ch, cp))
    if extra_codepoints_arg:
        for cp in parse_codepoints(extra_codepoints_arg):
            if cp in seen:
                continue
            seen.add(cp)
            result.append((chr(cp), cp))
    return result


def render_glyphs(font, char_list, pad):
    """Render each character to a tight-cropped 'L' mode glyph image plus metrics.

    pad is used both as the left/top margin of the scratch canvas (so left
    side-bearings and ascent-exceeding ink have room) and to size the scratch
    canvas generously (some Nerd Font PUA glyphs, e.g. battery/wifi icons,
    can extend well outside the normal ascent/descent box).
    """
    ascent, descent = font.getmetrics()
    canvas_w = pad * 2 + int(font.size * 2)
    canvas_h = pad * 2 + ascent + descent + pad * 2
    pen_x = pad
    pen_y = pad + ascent

    glyphs = []
    for ch, cp in char_list:
        try:
            advance = font.getlength(ch)
        except Exception:
            advance = 0

        canvas = Image.new("L", (canvas_w, canvas_h), 0)
        draw = ImageDraw.Draw(canvas)
        try:
            draw.text((pen_x, pen_y), ch, font=font, fill=255, anchor="ls")
        except Exception as exc:
            print(f"WARNING: failed to draw U+{cp:04X} ({ch!r}): {exc}", file=sys.stderr)
            glyphs.append(
                dict(cp=cp, img=None, w=0, h=0, xoff=0, yoff=0, xadv=round(advance))
            )
            continue

        bbox = canvas.getbbox()
        if bbox is None:
            if ch != " " and advance == 0:
                print(
                    f"WARNING: glyph for U+{cp:04X} ({ch!r}) rendered empty and has "
                    f"zero advance width; this codepoint is probably missing from "
                    f"the font",
                    file=sys.stderr,
                )
            glyphs.append(
                dict(cp=cp, img=None, w=0, h=0, xoff=0, yoff=0, xadv=round(advance))
            )
            continue

        left, top, right, bottom = bbox
        glyph_img = canvas.crop(bbox)
        xadv = round(advance) if advance else (right - left)
        # Nerd Font icons are wider than one monospace cell. Connect IQ cuts a
        # glyph at its advance, so give icons an advance that covers the ink.
        if 0xE000 <= cp <= 0xF8FF:
            xadv = max(xadv, (left - pen_x) + (right - left) + 1)
        glyphs.append(
            dict(
                cp=cp,
                img=glyph_img,
                w=right - left,
                h=bottom - top,
                xoff=left - pen_x,
                yoff=top - pad,
                xadv=xadv,
            )
        )

    return glyphs, ascent, ascent + descent


def pack_shelf(glyphs, max_width):
    """Simple shelf packer. Mutates glyphs in place with 'x'/'y' atlas positions."""
    x = MARGIN
    y = MARGIN
    shelf_h = 0
    used_w = MARGIN
    for g in glyphs:
        if g["img"] is None or g["w"] == 0 or g["h"] == 0:
            g["x"] = 0
            g["y"] = 0
            continue
        if x + g["w"] + MARGIN > max_width:
            x = MARGIN
            y += shelf_h + MARGIN
            shelf_h = 0
        g["x"] = x
        g["y"] = y
        x += g["w"] + MARGIN
        used_w = max(used_w, x)
        shelf_h = max(shelf_h, g["h"])
    total_h = y + shelf_h + MARGIN
    return used_w, total_h


def choose_atlas_width(glyphs):
    total_area = sum(g["w"] * g["h"] for g in glyphs if g["img"] is not None) or 1
    widest_glyph = max((g["w"] for g in glyphs if g["img"] is not None), default=1)
    ideal_side = int(math.ceil(math.sqrt(total_area * 1.15)))
    width = max(ideal_side, widest_glyph + 2 * MARGIN, 32)
    # round up to a multiple of 4
    width = (width + 3) // 4 * 4
    return width


def write_fnt(path, name, face, size, bold, line_height, base, atlas_w, atlas_h, glyphs):
    lines = []
    lines.append(
        f'info face="{face}" size={size} bold={1 if bold else 0} italic=0 '
        f'charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 '
        f'spacing=1,1 outline=0'
    )
    lines.append(
        f"common lineHeight={line_height} base={base} scaleW={atlas_w} "
        f"scaleH={atlas_h} pages=1 packed=0 alphaChnl=1 redChnl=0 greenChnl=0 "
        f"blueChnl=0"
    )
    lines.append(f'page id=0 file="{name}.png"')
    lines.append(f"chars count={len(glyphs)}")
    for g in glyphs:
        lines.append(
            f"char id={g['cp']} x={g.get('x', 0)} y={g.get('y', 0)} "
            f"width={g['w']} height={g['h']} xoffset={g['xoff']} "
            f"yoffset={g['yoff']} xadvance={g['xadv']} page=0 chnl=15"
        )
    with open(path, "w", encoding="ascii", newline="\n") as f:
        f.write("\n".join(lines) + "\n")


def main():
    args = parse_args()

    ttf_path = args.ttf
    bold_resolved = False
    if args.bold:
        candidate = resolve_bold_path(ttf_path)
        if candidate:
            ttf_path = candidate
            bold_resolved = True
        else:
            print(
                f"WARNING: --bold given but no Bold sibling found next to "
                f"{args.ttf!r}; using the font as given (info line will not "
                f"claim bold=1)",
                file=sys.stderr,
            )

    if not os.path.isfile(ttf_path):
        print(f"ERROR: TTF not found: {ttf_path}", file=sys.stderr)
        sys.exit(1)

    font = ImageFont.truetype(ttf_path, args.size)
    family, style = font.getname()
    is_bold = bold_resolved or "bold" in ttf_path.lower() or "bold" in style.lower()
    face = f"{family} {style}".strip()

    char_list = build_char_list(args.chars, args.extra_codepoints)
    if not char_list:
        print("ERROR: empty character set", file=sys.stderr)
        sys.exit(1)

    pad = max(args.size, 8)
    glyphs, ascent, line_height = render_glyphs(font, char_list, pad)

    atlas_w = choose_atlas_width(glyphs)
    atlas_w, atlas_h = pack_shelf(glyphs, atlas_w)

    atlas = Image.new("L", (atlas_w, atlas_h), 0)
    for g in glyphs:
        if g["img"] is not None:
            atlas.paste(g["img"], (g["x"], g["y"]))

    os.makedirs(args.out, exist_ok=True)
    png_path = os.path.join(args.out, f"{args.name}.png")
    fnt_path = os.path.join(args.out, f"{args.name}.fnt")

    atlas.save(png_path)
    write_fnt(
        fnt_path,
        args.name,
        face,
        args.size,
        is_bold,
        line_height,
        ascent,
        atlas_w,
        atlas_h,
        glyphs,
    )

    print(f"Wrote {fnt_path}")
    print(f"Wrote {png_path}  ({atlas_w}x{atlas_h}, {len(glyphs)} glyphs)")


if __name__ == "__main__":
    main()
