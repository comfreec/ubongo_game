# -*- coding: utf-8 -*-
# 1. home_screen: _PuzzleCard 전체 클릭 가능하게 + 연습버튼 별도
# 2. game_screen: 힌트 관련 코드 전부 제거

# ── home_screen 수정 ──────────────────────────────────────────
with open('lib/screens/home_screen.dart', 'r', encoding='utf-8') as f:
    home = f.read()

# _PuzzleCard build 메서드 전체 교체
# 현재: 번호/정보/연습 각각 GestureDetector로 분리
# 변경: 전체를 InkWell로 감싸고, 연습버튼만 별도 GestureDetector

old_card = """  @override
  Widget build(BuildContext context) {
    final diffColor = isEasy ? Colors.greenAccent : Colors.orangeAccent;
    final diffLabel = isEasy ? '\\uC27D\\uC74C' : '\\uBCF4\\uD1B5';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          // 번호 + 완료 표시
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 72,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.blueAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCompleted)
                    const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20)
                  else
                    Text('$index',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // 퍼즐 정보
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('\\uD37C\\uC990 $index',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(diffLabel,
                              style: TextStyle(color: diffColor, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${puzzle.rows}x${puzzle.cols}  \\u00B7  \\uC870\\uAC01 ${puzzle.pieceIds.length}\\uAC1C'
                      '${bestSeconds != null ? "  \\u00B7  \\uBCA0\\uC2A4\\uD2B8: ${bestSeconds}\\uCD08" : ""}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 연습 모드 버튼
          GestureDetector(
            onTap: onPractice,
            child: Container(
              width: 48,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.self_improvement, color: Colors.greenAccent, size: 18),
                  SizedBox(height: 2),
                  Text('\\uC5F0\\uC2B5', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}"""

new_card = """  @override
  Widget build(BuildContext context) {
    final diffColor = isEasy ? Colors.greenAccent : Colors.orangeAccent;
    final diffLabel = isEasy ? '\\uC27D\\uC74C' : '\\uBCF4\\uD1B5';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Row(
            children: [
              // 번호 + 완료 표시
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.blueAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isCompleted)
                      const Icon(Icons.check_circle, color: Colors.blueAccent, size: 20)
                    else
                      Text('$index',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // 퍼즐 정보
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('\\uD37C\\uC990 $index',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(diffLabel,
                                style: TextStyle(color: diffColor, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${puzzle.rows}x${puzzle.cols}  \\u00B7  \\uC870\\uAC01 ${puzzle.pieceIds.length}\\uAC1C'
                        '${bestSeconds != null ? "  \\u00B7  \\uBCA0\\uC2A4\\uD2B8: ${bestSeconds}\\uCD08" : ""}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // 연습 모드 버튼 (별도 탭 영역)
              GestureDetector(
                onTap: onPractice,
                child: Container(
                  width: 48,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.self_improvement, color: Colors.greenAccent, size: 18),
                      SizedBox(height: 2),
                      Text('\\uC5F0\\uC2B5', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}"""

import re

def unescape(s):
    return re.sub(r'\\u([0-9A-Fa-f]{4})', lambda m: chr(int(m.group(1), 16)), s)

old_card_real = unescape(old_card)
new_card_real = unescape(new_card)

if old_card_real in home:
    home = home.replace(old_card_real, new_card_real)
    print("home_screen: OK")
else:
    print("home_screen: pattern not found, trying partial match...")
    # _PuzzleCard build 메서드 위치 찾기
    idx = home.find('class _PuzzleCard')
    print(f"  _PuzzleCard found at: {idx}")
    if idx > 0:
        print(f"  snippet: {home[idx:idx+100]}")

with open('lib/screens/home_screen.dart', 'w', encoding='utf-8') as f:
    f.write(home)

# ── game_screen 수정: 힌트 제거 ──────────────────────────────
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    game = f.read()

# 힌트 관련 제거할 것들:
# 1. _maxHints, _hintsUsed, _hintPieceId 필드
# 2. _useHint() 메서드
# 3. _initGame에서 힌트 초기화 코드
# 4. _onDrop에서 _hintPieceId = null
# 5. 힌트 버튼 UI
# 6. AnimatedContainer의 isHinted 관련

removals = [
    # 필드
    "\n  static const int _maxHints = 2;\n  int _hintsUsed = 0;\n  String? _hintPieceId; // 힌트로 강조할 조각 instanceId\n",
    # initGame 힌트 초기화
    "\n    _hintsUsed = 0;\n    _hintPieceId = null;\n",
    # onDrop 힌트 초기화
    "\n      _hintPieceId = null;\n",
    # _useHint 메서드 전체
]

for r in removals:
    if r in game:
        game = game.replace(r, '\n')
        print(f"game_screen: removed: {r[:40].strip()!r}")
    else:
        print(f"game_screen: NOT FOUND: {r[:40].strip()!r}")

# _useHint 메서드 제거 (패턴으로)
use_hint_pattern = re.compile(
    r'\n  void _useHint\(\) \{.*?\n  \}\n',
    re.DOTALL
)
if use_hint_pattern.search(game):
    game = use_hint_pattern.sub('\n', game)
    print("game_screen: removed _useHint method")
else:
    print("game_screen: _useHint method not found")

# 힌트 버튼 UI 제거
hint_btn_pattern = re.compile(
    r'\s*const SizedBox\(width: 12\),\s*// 힌트\s*_ActionBtn\(.*?color: Colors\.amber,\s*\),',
    re.DOTALL
)
if hint_btn_pattern.search(game):
    game = hint_btn_pattern.sub('', game)
    print("game_screen: removed hint button")
else:
    print("game_screen: hint button not found by pattern")
    # 직접 찾기
    idx = game.find('// 힌트')
    if idx > 0:
        print(f"  hint comment at {idx}: {game[idx:idx+150]}")

# AnimatedContainer isHinted 관련 제거 - 단순 Center로 교체
anim_pattern = re.compile(
    r'return AnimatedContainer\(.*?child: Center\(\s*child: PieceWidget\(',
    re.DOTALL
)
if anim_pattern.search(game):
    game = anim_pattern.sub('return Center(\n                          child: PieceWidget(', game)
    # 닫는 괄호 정리 (AnimatedContainer의 추가 닫는 괄호 제거)
    # AnimatedContainer 끝: ),\n                        );\n  → Center 끝: );\n
    game = re.sub(
        r'(PieceWidget\(.*?\),\s*\),\s*\),\s*\);)',
        lambda m: m.group(0).replace('),\n                        );', ');'),
        game, flags=re.DOTALL
    )
    print("game_screen: replaced AnimatedContainer with Center")
else:
    print("game_screen: AnimatedContainer not found")

with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(game)

# 검증
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    g = f.read()
print(f"\ngame_screen: Lines={len(g.splitlines())}, Braces={g.count(chr(123))}/{g.count(chr(125))}")
print(f"hint remaining: {'_useHint' in g or '_hintsUsed' in g or '_hintPieceId' in g}")
