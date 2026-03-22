# -*- coding: utf-8 -*-
import glob

files = (
    glob.glob('lib/screens/*.dart') +
    glob.glob('lib/services/*.dart') +
    glob.glob('lib/widgets/*.dart') +
    glob.glob('lib/models/*.dart') +
    glob.glob('lib/data/*.dart') +
    ['lib/main.dart']
)

for f in files:
    with open(f, encoding='utf-8') as fp:
        text = fp.read()
    # CJK Unified Ideographs (Chinese chars) = 0x4E00-0x9FFF
    # 한글 = 0xAC00-0xD7A3
    bad = [c for c in text if 0x4E00 <= ord(c) <= 0x9FFF]
    status = 'BAD' if bad else 'OK'
    sample = ''.join(bad[:3]) if bad else ''
    print(f'{status} {f} {sample}')
