"""Temporary: compare the Swift renders with the web's, print a share and a coarse heat map."""
import os
import sys
from PIL import Image, ImageChops

sw, wb = sys.argv[1:3]
rows = []
for name in sorted(os.listdir(wb)):
    a = Image.open(os.path.join(sw, name)).convert('RGB')
    b = Image.open(os.path.join(wb, name)).convert('RGB').resize(a.size)
    d = ImageChops.difference(a, b).convert('L').point(lambda v: 255 if v > 70 else 0)
    share = sum(1 for v in d.getdata() if v) / (a.width * a.height)
    rows.append((share, name, d))
for share, name, d in sorted(rows, key=lambda r: -r[0]):
    print(f"{share * 100:6.2f}%  {name}")
for share, name, d in sorted(rows, key=lambda r: -r[0]):
    if share < 0.004:
        continue
    cw, ch = 15, 18 if 'friend' in name else 24
    print(f"\n{name}  (each cell {cw}x{ch}px; . <2%  - <8%  + <20%  # more)")
    for y in range(0, d.height, ch):
        line = ''
        for x in range(0, d.width, cw):
            box = d.crop((x, y, x + cw, y + ch))
            f = sum(1 for v in box.getdata() if v) / (cw * ch)
            line += ' ' if f == 0 else '.' if f < 0.02 else '-' if f < 0.08 else '+' if f < 0.2 else '#'
        print('|' + line + '|')
