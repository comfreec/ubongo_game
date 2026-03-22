# -*- coding: utf-8 -*-
# Wrap 대신 2열 고정 GridView 사용
# 각 셀 크기를 (w/2 - spacing) 기준으로 맞추고
# 조각은 그 안에서 Center로 배치
# cellSize는 보드와 조각 영역 높이 기준으로 이진탐색

with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  Widget _buildGameBody() {"
end_marker   = "  Widget _buildResultOverlay() {"
start_idx = content.find(start_marker)
end_idx   = content.find(end_marker)

txt_remove = '보드의 조각을 탭하면 제거됩니다'
txt_hint   = '탭: 회전  |  길게 탭: 반전  |  드래그: 배치'

new_method = f"""  Widget _buildGameBody() {{
    return LayoutBuilder(
      builder: (context, constraints) {{
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 조각 정보
        int maxPieceRows = 1;
        int maxPieceCols = 1;
        final pieceCount = _puzzle.pieceIds.length;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }}

        // 2열 고정 그리드: 행 수 = ceil(pieceCount / 2)
        final gridRows = ((pieceCount + 1) ~/ 2);

        // 고정 UI: 안내텍스트(11) + SizedBox(4) + 조각텍스트(11) + SizedBox(6) + 패딩마진(41)
        const fixedUI = 73.0;
        // 그리드 행 간격
        const rowSpacing = 8.0;

        // 이진탐색: cellSize 결정
        // 보드 높이 = cellSize * puzzle.rows
        // 조각 그리드 셀 높이 = cellSize * maxPieceRows + 32 (버튼+여백)
        // 조각 그리드 총 높이 = gridRows * cellH + (gridRows-1) * rowSpacing
        // 전체 = 보드높이 + 조각그리드총높이 + fixedUI <= h

        double totalH(double cs) {{
          final boardH = cs * _puzzle.rows;
          final cellH = cs * maxPieceRows + 32;
          final gridH = gridRows * cellH + (gridRows - 1) * rowSpacing;
          return boardH + gridH + fixedUI;
        }}

        // 보드 너비 기준 최대
        final cBoardW = (w * 0.94) / _puzzle.cols;
        // 조각 2열 기준 최대 (각 셀 너비 = (w-16-10)/2, 조각너비 = cs*maxPieceCols)
        final cPieceW = (w - 26) / 2 / maxPieceCols;
        final hiMax = cBoardW < cPieceW ? cBoardW : cPieceW;

        double lo = 16, hi = hiMax;
        for (int i = 0; i < 30; i++) {{
          final mid = (lo + hi) / 2;
          if (totalH(mid) <= h) lo = mid;
          else hi = mid;
        }}
        final cellSize = lo;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;
        final pieceCellH = cellSize * maxPieceRows + 32;

        return Column(
          children: [
            // ── 보드 영역 ────────────────────────────────────
            SizedBox(
              width: w,
              height: boardH + 15,
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
            // ── 조각 영역 (Expanded) ─────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('{txt_hint}',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    // 2열 고정 그리드
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: rowSpacing,
                        crossAxisSpacing: 10,
                        mainAxisExtent: pieceCellH,
                      ),
                      itemCount: _state.availablePieces.length,
                      itemBuilder: (context, i) {{
                        final piece = _state.availablePieces[i];
                        final current = _transformedPieces[piece.instanceId] ?? piece;
                        return Center(
                          child: PieceWidget(
                            key: ValueKey(piece.instanceId),
                            piece: current,
                            cellSize: cellSize,
                            onTransform: (transformed) {{
                              setState(() => _transformedPieces[piece.instanceId] = transformed);
                            }},
                          ),
                        );
                      }},
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
print(f"Lines: {len(c.splitlines())}, Braces: {c.count(chr(123))}/{c.count(chr(125))}")
