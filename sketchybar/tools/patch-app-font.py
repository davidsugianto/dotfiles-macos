#!/usr/bin/env python3
"""
patch-app-font.py — add custom app glyphs to sketchybar-app-font.

sketchybar-app-font maps an app to an icon through a ligature (":ghostty:" ->
glyph). Apps it doesn't ship (e.g. Herdr) can't be added without editing the
font, so this copies the cask's font, injects one glyph per --glyph NAME=SVG
and registers the ":NAME:" ligature, and saves it under a NEW family name. The
Homebrew-managed original is never touched.

Needs fontTools:  pip install fonttools   (setup.sh keeps it in a venv, version pinned)
Tests: sketchybar/tools/test-patch-app-font.sh

Usage:
  patch-app-font.py --base ~/Library/Fonts/sketchybar-app-font.ttf \
      --out ~/Library/Fonts/sketchybar-app-font-custom.ttf \
      --family sketchybar-app-font-custom \
      --glyph herdr=assets/herdr.svg

SVG support is deliberately narrow: single-colour <path d="..."> elements,
optionally inside <g transform="translate(..) scale(..)"> (the shape icon
sets like dashboard-icons ship). Colour comes from the bar at render time.
"""

import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.misc.transform import Transform
from fontTools.svgLib.path import parse_path
from fontTools.ttLib import TTFont
from fontTools.ttLib.tables import otTables

# Existing glyphs are drawn in a ~1000-unit box sitting on the baseline and
# advance 1411 units; match that so custom icons line up with the rest.
EM_BOX = 1000
ADVANCE = 1411
FIT = 0.96  # fraction of EM_BOX the longest side may fill


def svg_paths(svg_file):
    """Return a list of (d, Transform) for every <path> in the SVG."""
    root = ET.parse(svg_file).getroot()
    out = []

    def walk(node, xf):
        tag = node.tag.split("}")[-1]
        t = node.get("transform")
        if t:
            xf = xf.transform(parse_transform(t))
        if tag == "path" and node.get("d"):
            out.append((node.get("d"), xf))
        for child in node:
            walk(child, xf)

    walk(root, Transform())
    if not out:
        sys.exit(f"{svg_file}: no <path> elements found")
    return out


def parse_transform(text):
    xf = Transform()
    for name, args in re.findall(r"(\w+)\s*\(([^)]*)\)", text):
        nums = [float(n) for n in re.split(r"[\s,]+", args.strip()) if n]
        if name == "translate":
            xf = xf.translate(nums[0], nums[1] if len(nums) > 1 else 0)
        elif name == "scale":
            xf = xf.scale(nums[0], nums[1] if len(nums) > 1 else nums[0])
        elif name == "matrix":
            xf = xf.transform(tuple(nums))
        else:
            sys.exit(f"unsupported SVG transform: {name}")
    return xf


def build_glyph(svg_file):
    paths = svg_paths(svg_file)

    # Pass 1: bounds in SVG space (y down) to size and place the glyph.
    bp = BoundsPen(None)
    for d, xf in paths:
        parse_path(d, TransformPen(bp, xf))
    x0, y0, x1, y1 = bp.bounds
    scale = EM_BOX * FIT / max(x1 - x0, y1 - y0)

    # SVG y grows downward, font y grows upward: flip, then drop the glyph's
    # bottom edge onto the baseline and its left edge onto x=0.
    place = Transform(scale, 0, 0, -scale, -x0 * scale, y1 * scale)

    # Pass 2: draw as quadratic TrueType outlines (the font is glyf-based).
    pen = TTGlyphPen(None)
    qpen = Cu2QuPen(pen, max_err=1.0, reverse_direction=False)
    for d, xf in paths:
        # fontTools: a.transform(b) applies b first, then a.
        parse_path(d, TransformPen(qpen, place.transform(xf)))
    return pen.glyph()


def ligature_subtable(font):
    """The font's ligature table, or a clear exit if its layout is unexpected.

    sketchybar-app-font keeps every ':app:' ligature in the first subtable of
    its first GSUB lookup; a different release layout needs this script
    updated, which is clearer to say than an IndexError.
    """
    try:
        subtable = font["GSUB"].table.LookupList.Lookup[0].SubTable[0]
    except (KeyError, AttributeError, IndexError):
        subtable = None
    if not isinstance(subtable, otTables.LigatureSubst):
        sys.exit("unexpected GSUB layout in the base font (no ligature subtable "
                 "at lookup 0): update tools/patch-app-font.py for this font release")
    return subtable


def add_glyph(font, name, svg_file):
    glyph_name = f":{name}:"
    glyph = build_glyph(svg_file)
    order = font.getGlyphOrder()
    if glyph_name in order:
        sys.exit(f"font already has {glyph_name}; pick another name")
    order.append(glyph_name)
    font.setGlyphOrder(order)
    font["glyf"].glyphs[glyph_name] = glyph
    # Left side bearing must equal the glyph's xMin (existing glyphs do).
    glyph.recalcBounds(font["glyf"])
    font["hmtx"][glyph_name] = (ADVANCE, glyph.xMin)

    # Ligature: ':' n a m e ':' -> glyph. fontTools wants the first glyph as
    # the key and the rest as the component list.
    cmap = font.getBestCmap()
    missing = [c for c in glyph_name if ord(c) not in cmap]
    if missing:
        sys.exit(f"base font has no glyph for {''.join(missing)!r}, can't build {glyph_name}")
    seq = [cmap[ord(c)] for c in glyph_name]
    subtable = ligature_subtable(font)
    lig = otTables.Ligature()
    lig.LigGlyph = glyph_name
    lig.Component = seq[1:]
    lig.CompCount = len(seq)
    subtable.ligatures.setdefault(seq[0], []).append(lig)
    # Longest match first, or ":herdr:" would lose to a shorter ":her...:" rule.
    subtable.ligatures[seq[0]].sort(key=lambda l: -l.CompCount)


def rename(font, family):
    for rec in font["name"].names:
        if rec.nameID in (1, 16):
            rec.string = family
        elif rec.nameID == 4:
            rec.string = family
        elif rec.nameID == 6:
            rec.string = family.replace(" ", "")
        elif rec.nameID == 3:
            rec.string = f"{family};patched"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--base", required=True, help="original sketchybar-app-font.ttf")
    ap.add_argument("--out", required=True, help="patched font to write")
    ap.add_argument("--family", required=True, help="new font family name")
    ap.add_argument("--glyph", action="append", default=[], metavar="NAME=SVG",
                    help="add ':NAME:' from SVG (repeatable)")
    args = ap.parse_args()

    font = TTFont(args.base)
    for spec in args.glyph:
        name, _, svg = spec.partition("=")
        if not name or not svg:
            sys.exit(f"bad --glyph {spec!r}, expected NAME=SVG")
        add_glyph(font, name, svg)
    rename(font, args.family)

    # Build beside the destination, verify, then move into place, so a failed
    # save or verify never leaves a bad font where the bar would pick it up
    # (and where setup.sh would treat it as up to date).
    tmp = args.out + ".tmp"
    try:
        font.save(tmp)
        verify(tmp, [spec.partition("=")[0] for spec in args.glyph])
        os.replace(tmp, args.out)
    finally:
        if os.path.exists(tmp):
            os.remove(tmp)
    print(f"wrote {args.out} (+{len(args.glyph)} glyph(s))")


def verify(path, names):
    """Reload the saved font and confirm each glyph and its ligature survived."""
    font = TTFont(path)
    ligs = ligature_subtable(font).ligatures
    for name in names:
        glyph_name = f":{name}:"
        if glyph_name not in font["glyf"].glyphs:
            sys.exit(f"verify: {glyph_name} missing from {path}")
        if not any(l.LigGlyph == glyph_name for group in ligs.values() for l in group):
            sys.exit(f"verify: no ligature for {glyph_name} in {path}")


if __name__ == "__main__":
    main()
