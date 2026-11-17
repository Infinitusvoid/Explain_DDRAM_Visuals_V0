#!/usr/bin/env python3
"""Build the series intro card and the episode title cards poster."""

import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1920, 1080
FD = r"C:\Windows\Fonts"
F_LIGHT = FD + r"\segoeuil.ttf"
F_REG = FD + r"\segoeui.ttf"
F_SEMI = FD + r"\segoeuib.ttf"
F_MONO = FD + r"\consola.ttf"

ACCENT = (95, 220, 255)
INK = (232, 242, 255)
MUTED = (150, 175, 196)


def vertical_gradient(w, h, top, bottom):
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        px[0, y] = c
    return img.resize((w, h), Image.BILINEAR).convert("RGBA")


def tracked(draw, xy, text, fnt, fill, tracking=0, anchor="ls"):
    total = sum(draw.textlength(ch, font=fnt) + tracking for ch in text) - (tracking if text else 0)
    x, y = xy
    if anchor.startswith("m"):
        x -= total / 2
    elif anchor.startswith("r"):
        x -= total
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill, anchor="ls")
        x += draw.textlength(ch, font=fnt) + tracking
    return total


def glow(base, text, xy, fnt, fill, tracking=0, radius=26, strength=0.6, anchor="ms"):
    tmp = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(tmp)
    tracked(d, xy, text, fnt, (fill[0], fill[1], fill[2], 255), tracking, anchor)
    blur = tmp.filter(ImageFilter.GaussianBlur(radius))
    blur.putalpha(blur.getchannel("A").point(lambda v: int(v * strength)))
    base.alpha_composite(blur)
    base.alpha_composite(blur)
    tracked(ImageDraw.Draw(base), xy, text, fnt, fill + (255,), tracking, anchor)


def make_intro(path):
    img = vertical_gradient(W, H, (4, 7, 14), (10, 17, 30))
    d = ImageDraw.Draw(img, "RGBA")

    # drafting grid
    for x in range(0, W, 80):
        d.line([(x, 0), (x, H)], fill=(70, 130, 170, 8))
    for y in range(0, H, 80):
        d.line([(0, y), (W, y)], fill=(70, 130, 170, 8))

    # soft halo behind the title
    halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    hd.ellipse((W * 0.22, H * 0.28, W * 0.78, H * 0.72), fill=(40, 170, 220, 90))
    halo = halo.filter(ImageFilter.GaussianBlur(140))
    img.alpha_composite(halo)

    d = ImageDraw.Draw(img, "RGBA")
    tracked(d, (W // 2, H * 0.36), "A  V I S U A L  S E R I E S", ImageFont.truetype(F_MONO, 26), ACCENT + (255,), 6, "ms")
    glow(img, "HOW DRAM WORKS", (W // 2, H * 0.53), ImageFont.truetype(F_LIGHT, 128), INK, 3, 30, 0.55, "ms")
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle((W // 2 - 60, H * 0.575, W // 2 + 60, H * 0.578), fill=ACCENT + (200,))
    tracked(d, (W // 2, H * 0.645), "six short films about the memory in your computer", ImageFont.truetype(F_REG, 32), MUTED + (255,), 2, "ms")
    tracked(d, (W // 2, H * 0.845), "EPISODES 01 - 06", ImageFont.truetype(F_MONO, 22), (110, 140, 160, 220), 5, "ms")

    # corner marks
    m, ln = 64, 34
    for (cx, cy, dx, dy) in ((m, m, 1, 1), (W - m, m, -1, 1), (m, H - m, 1, -1), (W - m, H - m, -1, -1)):
        d.line([(cx, cy), (cx + ln * dx, cy)], fill=(90, 190, 230, 90), width=2)
        d.line([(cx, cy), (cx, cy + ln * dy)], fill=(90, 190, 230, 90), width=2)

    img.convert("RGB").save(path, "PNG")
    print("wrote", path)


if __name__ == "__main__":
    make_intro(sys.argv[1])
