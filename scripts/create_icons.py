from pathlib import Path
import json
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
icon = Image.new('RGB', (1024, 1024), '#171817')
draw = ImageDraw.Draw(icon)
draw.rounded_rectangle((180, 160, 844, 865), radius=100, fill='#272A28')
draw.rounded_rectangle((250, 220, 774, 380), radius=30, fill='#EEEAE1')
for x, y in [(250, 445), (535, 445), (250, 650), (535, 650)]:
    draw.rounded_rectangle((x, y, x + 235, y + 155), radius=32, fill='#D9AB62' if x > 400 else '#3A3F3C')
draw.line((305, 522, 430, 522), fill='#EEEAE1', width=18)
draw.line((367, 470, 367, 574), fill='#EEEAE1', width=18)
draw.line((591, 522, 715, 522), fill='#171817', width=18)
draw.line((325, 695, 410, 762), fill='#EEEAE1', width=18)
draw.line((325, 762, 410, 695), fill='#EEEAE1', width=18)
draw.line((591, 715, 715, 715), fill='#171817', width=16)
draw.line((591, 750, 715, 750), fill='#171817', width=16)
for size in [192, 512]:
    for prefix in ['Icon-', 'Icon-maskable-']:
        icon.resize((size, size), Image.Resampling.LANCZOS).save(root / 'web' / 'icons' / f'{prefix}{size}.png')
icon.resize((64, 64), Image.Resampling.LANCZOS).save(root / 'web' / 'favicon.png')
app_icons = root / 'ios' / 'Runner' / 'Assets.xcassets' / 'AppIcon.appiconset'
for item in json.loads((app_icons / 'Contents.json').read_text())['images']:
    if 'filename' in item:
        points = float(item['size'].split('x')[0])
        size = round(points * int(item['scale'].removesuffix('x')))
        icon.resize((size, size), Image.Resampling.LANCZOS).save(app_icons / item['filename'])
print('Ícones Calculadora criados para web e iOS.')
