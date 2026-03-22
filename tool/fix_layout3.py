# -*- coding: utf-8 -*-
import re

with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  Widget _buildGameBody() {"
end_marker = "  Widget _buildResultOverlay() {"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: markers not found")
    exit(1)

# 한글 문자열 (유니코드 이스케이프 없이 직접)
txt_remove = '보드의 조각을 탭하면 제거됩니다'
txt_hint   = '탭: 회전  |  길게 탭: 반전  |  드래그: 배치'

new_method = f"""  Widget _buildGameBody() {{
    return LayoutBuilder(
      builder: (context, constraints) {{
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 현재 퍼즐의 조각 중 가장 큰 조각 크기 계산
        int maxPieceRows = 1;
        int maxPieceCols = 1;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          final pr = p.maxRow + 1;
          final pc = p.maxCol + 1;
          if (pr > maxPieceRows) maxPieceRows = pr;
          if (pc > maxPieceCols) maxPieceCols = pc;
        }}

        // 보드 영역: 전체의 52%
        final boardAreaH = h * 0.52;
        // 조각 영역: 전체의 48% - 고정 UI(텍스트+패딩 약 40px)
        final pieceAreaH = h * 0.48;
        final pieceGridH = pieceAreaH - 40; // 텍스트+패딩 제외

        // cellSize 3가지 제약 중 가장 작은 값
        final cellByBoardW = (w * 0.94) / _puzzle.cols;
        final cellByBoardH = boardAreaH / _puzzle.rows;
        // 조각 영역에서: 가장 큰 조각 1개 + 버튼(32px) + 여백이 들어가야 함
        final cellByPieceH = (pieceGridH - 36) / maxPieceRows;
        final cellByPieceW = (w * 0.94) / (maxPieceCols * 2); // 조각 2개 나란히 기준

        double cellSize = cellByBoardW;
        if (cellByBoardH < cellSize) cellSize = cellByBoardH;
        if (cellByPieceH < cellSize) cellSize = cellByPieceH;
        if (cellByPieceW < cellSize) cellSize = cellByPieceW;
        // 최소값 보장
        if (cellSize < 18) cellSize = 18;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // ── 보드 영역 ──────────────────────────────────
            SizedBox(
              width: w,
              height: boardAreaH,
              child: Column(
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
                      onRemove: (pp) {{
                        if (_state.status != GameStatus.playing) return;
                        SoundService.playRemove();
                        setState(() {{
                          final newPlaced = _state.placedPieces.where((p) => p != pp).toList();
                          final newAvailable = [..._state.availablePieces, pp.piece];
                          _state = _state.copyWith(placedPieces: newPlaced, availablePieces: newAvailable);
                        }});
                      }},
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '{txt_remove}',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            // ── 조각 영역 ──────────────────────────────────
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
                      '{txt_hint}',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _state.availablePieces.map((piece) {{
                            final current = _transformedPieces[piece.instanceId] ?? piece;
                            return PieceWidget(
                              key: ValueKey(piece.instanceId),
                              piece: current,
                              cellSize: cellSize,
                              onTransform: (transformed) {{
                                setState(() => _transformedPieces[piece.instanceId] = transformed);
                              }},
                            );
                          }}).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }},
    );
  }}

"""

new_content = content[:start_idx] + new_method + content[end_idx:]

with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
print(f"Lines: {len(c.splitlines())}")
print(f"Braces: open={c.count(chr(123))}, close={c.count(chr(125))}")
# cellSize 관련 라인 확인
for i, line in enumerate(c.splitlines()):
    if 'cellSize' in line and ('=' in line or 'clamp' in line):
        print(f"  {i+1}: {line.strip()}")
