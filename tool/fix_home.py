with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# difficulty 파라미터 제거
old = """        builder: (_) => GameScreen(
          puzzles: _puzzles,
          initialIndex: index,
          difficulty: difficulty,
        ),"""

new = """        builder: (_) => GameScreen(
          puzzles: _puzzles,
          initialIndex: index,
        ),"""

if old in content:
    content = content.replace(old, new)
    print("OK: removed difficulty param")
else:
    print("ERROR: pattern not found")

# 파일 끝에 } 없으면 추가
if not content.rstrip().endswith('}'):
    content = content.rstrip() + '\n}\n'
    print("OK: added closing brace")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
