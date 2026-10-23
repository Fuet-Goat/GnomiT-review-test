"""Compose Grok task-003 comparison sheets from actual Godot captures (no painting/retouching)."""
import sys
from PIL import Image, ImageDraw, ImageFont
IN, OUT = sys.argv[1], sys.argv[2]
try: F = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 16)
except Exception: F = ImageFont.load_default()
def L(n): return Image.open(f'{IN}/{n}.png').convert('RGB')
def sheet(panels, labels, path, head=36):
    w = sum(p.width for p in panels) + 8*(len(panels)-1); h = panels[0].height + head
    s = Image.new('RGB', (w, h), (30, 40, 38)); d = ImageDraw.Draw(s); x = 0
    for p, l in zip(panels, labels):
        s.paste(p, (x, head)); d.text((x+8, 9), l, fill=(240, 230, 200), font=F); x += p.width + 8
    s.save(path)
cur, grok = L('CUR_B_x1'), L('GROK_G1_x1')
sheet([cur, grok], ['CURRENT MAP (Profile B, as published)', 'GROK T003 (env + light G1)'], f'{OUT}/CURRENT_VS_GROK_432x960.png')
grok.save(f'{OUT}/GROK_FULL_FRAME_432x960.png')
sheet([L('CUR_B_x1'), L('CUR_G1_x1'), L('GROK_B_x1'), L('GROK_G1_x1')],
      ['CURRENT · B', 'CURRENT · G1', 'GROK · B', 'GROK · G1'], f'{OUT}/LIGHTING_EFFECT_B_vs_G1.png')
c3, g3 = L('CUR_B_x3'), L('GROK_G1_x3')
for name, (x0, y0, x1, y1) in {'TREES_DETAIL': (10, 260, 230, 620), 'GRASS_DETAIL': (230, 440, 432, 800),
                              'MINE_PATH_DETAIL': (110, 70, 410, 340)}.items():
    box = tuple(v*3 for v in (x0, y0, x1, y1))
    sheet([c3.crop(box), g3.crop(box)], ['CURRENT (3x same camera)', 'GROK T003 (3x same camera)'], f'{OUT}/{name}.png')
print('COMPOSED')
