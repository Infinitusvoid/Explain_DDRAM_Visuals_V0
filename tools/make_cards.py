#!/usr/bin/env python3
"""Render typographic overlay cards for the DRAM series into a vertical atlas.

Usage:
    python make_cards.py spec.json

The spec is JSON:
{
  "out": "path/to/cards.png",
  "width": 1920, "height": 1080,
  "cards": [ { "layout": "title"|"beat"|"closing"|"caption"|"stack",
               "kicker": "...", "title": "...", "sub": "...", "tag": "...",
               "lines": ["...", "..."], "accent": "#5fdcff" }, ... ]
}

Cards are stacked vertically: card i occupies rows [i*height, (i+1)*height).
"""

import json
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

FONT_DIR = r"C:\Windows\Fonts"
F_LIGHT = FONT_DIR + r"\segoeuil.ttf"
F_REG = FONT_DIR + r"\segoeui.ttf"
F_SEMI = FONT_DIR + r"\segoeuib.ttf"
F_MONO = FONT_DIR + r"\consola.ttf"
F_MONO_B = FONT_DIR + r"\consolab.ttf"
F_DISPLAY = FONT_DIR + r"\bahnschrift.ttf"

INK = (232, 242, 255, 255)
MUTED = (150, 175, 196, 255)
ACCENT = (95, 220, 255, 255)
WARM = (255, 196, 120, 255)


def font(path, size):
    return ImageFont.truetype(path, size)


def hex_rgb(s, default=ACCENT):
    if not s:
        return default
    s = s.strip().lstrip("#")
    if len(s) == 6:
        return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)
    return default


def tracked(draw, xy, text, fnt, fill, tracking=0, anchor="ls"):
    """Draw text with letter spacing; returns total advance width."""
    x, y = xy
    total = 0.0
    for ch in text:
        total += draw.textlength(ch, font=fnt) + tracking
    total -= tracking if text else 0
    if anchor.startswith("m"):
        cx = x - total / 2
    elif anchor.startswith("r"):
        cx = x - total
    else:
        cx = x
    for ch in text:
        draw.text((cx, y), ch, font=fnt, fill=fill, anchor="ls")
        cx += draw.textlength(ch, font=fnt) + tracking
    return total


def scrim_bottom(img, height_frac=0.55, strength=235):
    w, h = img.size
    top = int(h * (1.0 - height_frac))
    grad = Image.new("RGBA", (1, h - top), (0, 0, 0, 0))
    px = grad.load()
    for y in range(h - top):
        t = y / max(1, (h - top - 1))
        a = int((t ** 1.7) * strength)
        px[0, y] = (2, 5, 10, a)
    grad = grad.resize((w, h - top), Image.BILINEAR)
    img.alpha_composite(grad, (0, top))


def scrim_center(img, strength=170):
    w, h = img.size
    small = Image.new("L", (64, 36), 0)
    d = ImageDraw.Draw(small)
    d.ellipse((-6, -6, 70, 42), fill=255)
    mask = small.resize((w, h), Image.BILINEAR).filter(ImageFilter.GaussianBlur(40))
    layer = Image.new("RGBA", (w, h), (2, 5, 10, 0))
    layer.putalpha(mask.point(lambda v: int(v * strength / 255)))
    img.alpha_composite(layer)


def glow_text(base, xy, text, fnt, fill, tracking=0, anchor="ls", radius=18, strength=0.85):
    """Draw a glowing copy of the text under the crisp copy."""
    w, h = base.size
    tmp = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    tracked(d, xy, text, fnt, (fill[0], fill[1], fill[2], 255), tracking, anchor)
    blur = tmp.filter(ImageFilter.GaussianBlur(radius))
    alpha = blur.getchannel("A").point(lambda v: int(v * strength))
    blur.putalpha(alpha)
    base.alpha_composite(blur)
    base.alpha_composite(blur)
    d2 = ImageDraw.Draw(base)
    tracked(d2, xy, text, fnt, fill, tracking, anchor)


def draw_card(w, h, card, index, total):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    accent = hex_rgb(card.get("accent"), ACCENT)
    layout = card.get("layout", "beat")
    kicker = card.get("kicker", "")
    title = card.get("title", "")
    sub = card.get("sub", "")
    tag = card.get("tag", "")
    margin = int(w * 0.0625)

    if layout == "title":
        scrim_center(img, 215)
        d = ImageDraw.Draw(img)
        cy = int(h * 0.50)
        if kicker:
            tracked(d, (w // 2, cy - 170), kicker, font(F_MONO, 26), accent, 8, anchor="ms")
        if title:
            f = font(F_LIGHT, 132)
            glow_text(img, (w // 2, cy + 10), title, f, INK, 2, anchor="ms", radius=26, strength=0.55)
        if sub:
            d = ImageDraw.Draw(img)
            tracked(d, (w // 2, cy + 105), sub, font(F_REG, 34), MUTED, 3, anchor="ms")
        # rule
        d2 = ImageDraw.Draw(img)
        d2.rectangle((w // 2 - 46, cy + 150, w // 2 + 46, cy + 152), fill=(accent[0], accent[1], accent[2], 200))
        if tag:
            tracked(d2, (w // 2, h - margin - 10), tag, font(F_MONO, 22), MUTED, 5, anchor="ms")

    elif layout == "closing":
        scrim_center(img, 200)
        d = ImageDraw.Draw(img)
        cy = int(h * 0.46)
        if kicker:
            tracked(d, (w // 2, cy - 150), kicker, font(F_MONO, 26), accent, 8, anchor="ms")
        if title:
            glow_text(img, (w // 2, cy + 20), title, font(F_LIGHT, 96), INK, 1, anchor="ms", radius=20, strength=0.5)
        d = ImageDraw.Draw(img)
        if sub:
            tracked(d, (w // 2, cy + 110), sub, font(F_REG, 30), MUTED, 2, anchor="ms")
        if tag:
            tracked(d, (w // 2, cy + 190), tag, font(F_MONO, 24), accent, 4, anchor="ms")

    elif layout == "stack":
        scrim_bottom(img, 0.52, 225)
        d = ImageDraw.Draw(img)
        lines = card.get("lines", [])
        y = h - margin - 30 - (len(lines) - 1) * 62
        for i, ln in enumerate(lines):
            small = (i > 0)
            f = font(F_LIGHT if not small else F_REG, 58 if not small else 34)
            tracked(d, (margin, y), ln, f, INK if not small else MUTED, 1 if not small else 2)
            y += 62

    else:  # beat / caption
        scrim_bottom(img, 0.58 if layout == "beat" else 0.30, 230 if layout == "beat" else 200)
        d = ImageDraw.Draw(img)
        base_y = h - margin - 86
        if layout == "caption":
            base_y = h - margin - 26
            if sub:
                tracked(d, (margin, base_y), sub, font(F_REG, 34), INK, 2)
            return img

        if kicker:
            tracked(d, (margin, base_y - (86 if sub else 0) - 58), kicker, font(F_MONO, 24), accent, 7)
        if title:
            glow_text(img, (margin, base_y), title, font(F_LIGHT, 84), INK, 0, radius=16, strength=0.4)
        d = ImageDraw.Draw(img)
        if sub:
            tracked(d, (margin, base_y + 52), sub, font(F_REG, 32), MUTED, 1)

    # progress dots + episode tag, bottom right
    d = ImageDraw.Draw(img)
    r = 4
    gap = 22
    x0 = w - margin - (total - 1) * gap
    y0 = h - margin + 6
    for i in range(total):
        cx = x0 + i * gap
        if i == index:
            d.ellipse((cx - r - 2, y0 - r - 2, cx + r + 2, y0 + r + 2), fill=(accent[0], accent[1], accent[2], 235))
        else:
            d.ellipse((cx - r, y0 - r, cx + r, y0 + r), fill=(120, 145, 165, 90))
    if card.get("series_tag", True):
        tracked(d, (w - margin, h - margin - 26), "DRAM / EXPLAINED", font(F_MONO, 18), (110, 135, 155, 190), 4, anchor="rs")
    return img


def main():
    spec = json.load(open(sys.argv[1], encoding="utf-8-sig"))
    w = spec.get("width", 1920)
    h = spec.get("height", 1080)
    cards = spec["cards"]
    total = len(cards)
    atlas = Image.new("RGBA", (w, h * total), (0, 0, 0, 0))
    for i, card in enumerate(cards):
        img = draw_card(w, h, card, i, total)
        atlas.alpha_composite(img, (0, i * h))
        if spec.get("previews"):
            img.save(spec["previews"].format(i=i), "PNG")
    atlas.save(spec["out"], "PNG")
    print("wrote", spec["out"], f"{w}x{h * total}", "cards:", total)


if __name__ == "__main__":
    main()


