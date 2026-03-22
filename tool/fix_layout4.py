# -*- coding: utf-8 -*-
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  Widget _buildGameBody() {"
end_marker   = "  Widget _buildResultOverlay() {"

start_idx = content.find(start_marker)
end_idx   = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("ERROR: markers not found")
    exit(1)

txt_remove = '보드의 조각을 탭하면 제거됩니다'
txt_hint   = '탭: 회전  |  길게 탭: 반전  |  드래그: 배치'

# PieceWidget 한 개 높이 = cellSize * pieceRows + 4(SizedBox) + 28(버튼행)
# 조각 컨테이너 내부 가용 높이 = pieceAreaH - 패딩(8*2) - 마진하단(8) - 텍스트(11) - SizedBox(6) = pieceAreaH - 41
# 가장 큰 조각이 딱 들어가려면: cellSize * maxPieceRows + 32 <= pieceAreaH - 41
# => cellSize <= (pieceAreaH - 73) / maxPieceRows

new_method = f"""  Widget _buildGameBody() {{
    return LayoutBuilder(
      builder: (context, constraints) {{
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 보드 영역 52%, 조각 영역 48% 고정 분할
        final boardAreaH = h * 0.52;
        final pieceAreaH = h * 0.48;

        // 현재 퍼즐 조각 중 최대 행/열 수 계산
        int maxPieceRows = 1;
        int maxPieceCols = 1;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }}

        // cellSize 제약 4가지 중 최솟값
        // 1) 보드 너비 기준
        final c1 = (w * 0.94) / _puzzle.cols;
        // 2) 보드 높이 기준
        final c2 = boardAreaH / _puzzle.rows;
        // 3) 조각 높이 기준: PieceWidget = cellSize*rows + 32px(버튼+여백)
        //    가용높이 = pieceAreaH - 41(패딩+텍스트)
        final c3 = (pieceAreaH - 73) / maxPieceRows;
        // 4) 조각 너비 기준: 조각 2개 나란히 + spacing(10)
        final c4 = (w - 36) / (maxPieceCols * 2 + 1).toDouble();

        double cellSize = [c1, c2, c3, c4].reduce((a, b) => a < b ? a : b);
        if (cellSize < 16) cellSize = 16;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // ── 보드 영역 (52%) ─────────────────────────────
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
                  const Text('{txt_remove}',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            // ── 조각 영역 (48%) ─────────────────────────────
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
                    const Text('{txt_hint}',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
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
print(f"Braces open={c.count(chr(123))} close={c.count(chr(125))}")
for i, line in enumerate(c.splitlines()):
    if any(x in line for x in ['cellSize', 'boardAreaH', 'pieceAreaH', 'maxPiece']):
        if '=' in line or '<' in line:
            print(f"  {i+1}: {line.strip()}")
