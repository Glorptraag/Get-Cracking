"""Temporary: compare the Swift renders with the web's, print shares, ink coverage and heat maps."""
import os
import sys
from PIL import Image, ImageChops

sw, wb = sys.argv[1:3]


def px(img):
    return list(img.get_flattened_data() if hasattr(img, 'get_flattened_data') else img.getdata())


def ascii_art(img, cols=60):
    g = img.convert('L')
    rows = int(cols * g.height / g.width * 0.5)
    g = g.resize((cols, rows))
    ramp = '@%#*+=-:. '
    v = px(g)
    return '\n'.join('|' + ''.join(ramp[min(9, v[y * cols + x] * 10 // 256)] for x in range(cols)) + '|' for y in range(rows))


rows = []
for name in sorted(os.listdir(wb)):
    a = Image.open(os.path.join(sw, name)).convert('RGB')
    b = Image.open(os.path.join(wb, name)).convert('RGB').resize(a.size)
    diff = ImageChops.difference(a, b).convert('L')
    dv = px(diff)
    n = len(dv)
    ink_a = sum(1 for v in px(a.convert('L')) if v < 235) / n
    ink_b = sum(1 for v in px(b.convert('L')) if v < 235) / n
    s20 = sum(1 for v in dv if v > 20) / n
    s70 = sum(1 for v in dv if v > 70) / n
    mean = sum(dv) / n
    rows.append((s20, name, diff, a, b))
    print(f"{name:28s} ink swift {ink_a * 100:5.1f}% web {ink_b * 100:5.1f}%  diff>20 {s20 * 100:5.2f}%  diff>70 {s70 * 100:5.2f}%  mean {mean:5.2f}")

for s20, name, diff, a, b in sorted(rows, key=lambda r: -r[0])[:6]:
    d = diff.point(lambda v: 255 if v > 20 else 0)
    cw, ch = 15, 18 if 'friend' in name else 24
    print(f"\n{name}: where they differ (each cell {cw}x{ch}px; . <2%  - <8%  + <20%  # more)")
    dd = px(d)
    for y in range(0, d.height, ch):
        line = ''
        for x in range(0, d.width, cw):
            cnt = sum(1 for yy in range(y, min(y + ch, d.height)) for xx in range(x, min(x + cw, d.width)) if dd[yy * d.width + xx])
            f = cnt / (cw * ch)
            line += ' ' if f == 0 else '.' if f < 0.02 else '-' if f < 0.08 else '+' if f < 0.2 else '#'
        print('|' + line + '|')

for name in ['friend-galah.png', 'friend-sugarplum.png', 'world-xmasvillage.png']:
    if os.path.exists(os.path.join(sw, name)):
        print(f"\n{name}, swift:")
        print(ascii_art(Image.open(os.path.join(sw, name)).convert('RGB')))
        print(f"{name}, web:")
        print(ascii_art(Image.open(os.path.join(wb, name)).convert('RGB')))
