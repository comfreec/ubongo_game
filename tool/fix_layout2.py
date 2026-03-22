# -*- coding: utf-8 -*-
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# _buildGameBody 전체를 찾아서 교체
start_marker = "  Widget _buildGameBody() {"
end_marker = "  Widget _buildResultOverlay() {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: markers not found")
    exit(1)

new_method = """  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 보드 영역 높이: 전체의 50%
        // 조각 영역 높이: 전체의 50%
        // 이 두 값은 항상 h를 초과하지 않음
        final boardAreaH = h * 0.50;
        final pieceAreaH = h * 0.50;

        // cellSize: 보드 영역 안에 딱 맞게 (너비/높이 중 작은 값)
        final cellByW = (w * 0.94) / _puzzle.cols;
        final cellByH = (boardAreaH - 20) / _puzzle.rows; // 20: 안내텍스트 여백
        final cellSize = cellByW < cellByH ? cellByW : cellByH;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // ── 보드 영역 (50%) ──────────────────────────────
            SizedBox(
              width: w,
              height: boardAreaH,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: boardW,
                    height: boardH,
                    child: BoardWidget(
                      puzzle: _state.puzzle,
                      placedPieces: _state.placedPieces,
                      cellSize: cellSize,
                      onDrop: _onDrop,
                      onRemove: (pp) {
                        if (_state.status != GameStatus.playing) return;
                        SoundService.playRemove();
                        setState(() {
                          final newPlaced = _state.placedPieces.where((p) => p != pp).toList();
                          final newAvailable = [..._state.availablePieces, pp.piece];
                          _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '\\uBCF4\\uB4DC\\uC758 \\uC870\\uAC01\\uC744 \\uD0ED\\uD558\\uBA74 \\uC81C\\uAC70\\uB429\\uB2C8\\uB2E4',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            // ── 조각 영역 (50%) ──────────────────────────────
            SizedBox(
              width: w,
              height: pieceAreaH,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      '\\uD0ED: \\uD68C\\uC804  |  \\uAE38\\uAC8C \\uD0ED: \\uBC18\\uC804  |  \\uB4DC\\uB798\\uADF8: \\uBC30\\uCE58',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _state.availablePieces.map((piece) {
                            final current = _transformedPieces[piece.instanceId] ?? piece;
                            return PieceWidget(
                              key: ValueKey(piece.instanceId),
                              piece: current,
                              cellSize: cellSize,
                              onTransform: (transformed) {
                                setState(() => _transformedPieces[piece.instanceId] = transformed);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

"""

# 유니코드 이스케이프를 실제 한글로 변환
import re
def unescape(m):
    return chr(int(m.group(1), 16))
new_method = re.sub(r'\\u([0-9A-Fa-f]{4})', unescape, new_method)

new_content = content[:start_idx] + new_method + content[end_idx:]

with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

# 검증
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
print(f"Lines: {len(c.splitlines())}")
print(f"Braces: open={c.count(chr(123))}, close={c.count(chr(125))}")
for i, line in enumerate(c.splitlines()):
    if 'boardAreaH' in line or 'pieceAreaH' in line or 'cellSize' in line and 'clamp' not in line and '=' in line:
        print(f"  {i+1}: {line.strip()}")
