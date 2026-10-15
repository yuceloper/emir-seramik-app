"""Generate native PNG assets from the existing logo: python3 -m pip install Pillow."""
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'assets/brand/emir_seramik.png').convert('RGBA')
logo = Image.new('RGB', source.size, (11, 11, 13))
logo.paste(source, mask=source.getchannel('A'))


def save(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    logo.resize((size, size), Image.Resampling.LANCZOS).save(path, optimize=True)


icons = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for item in json.loads((icons / 'Contents.json').read_text())['images']:
    size = round(float(item['size'].split('x')[0]) * float(item['scale'][:-1]))
    save(icons / item['filename'], size)

launch = ROOT / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
for scale, suffix in [(1, ''), (2, '@2x'), (3, '@3x')]:
    save(launch / f'LaunchImage{suffix}.png', 160 * scale)

for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save(ROOT / f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)

print('Generated opaque iOS app icons, launch images, and Android launcher icons.')
