# -*- coding: utf-8 -*-
# 전략:
# 1. 먼저 보드 기준 최대 cellSize 계산
# 2. 그 cellSize로 조각 Wrap 총 높이 계산
# 3. 조각 총 높이 + 보드 총 높이 + 고정UI가 h 안에 들어오면 OK
# 4. 안 들어오면 cellSize를 이진탐색으로 줄임
# 5. 보드/조각 영역 비율은 고정하지 않고 실제 크기에 맞게 배분

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

        // 고정 UI 높이: 안내텍스트(11) + SizedBox(4) + 조각영역텍스트(11) + SizedBox(6) + 패딩마진(41)
        const fixedUI = 73.0;

        // 조각 정보
        int maxPieceRows = 1;
        int maxPieceCols = 1;
        final pieceCount = _puzzle.pieceIds.length;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }}

        // 주어진 cellSize에서 조각 Wrap 총 높이
        double pieceWrapHeight(double cs) {{
          final pieceW = cs * maxPieceCols;
          final perRow = ((w - 16) / (pieceW + 10)).floor().clamp(1, pieceCount);
          final rows = ((pieceCount + perRow - 1) ~/ perRow);
          final oneH = cs * maxPieceRows + 32;
          return rows * oneH + (rows - 1) * 10.0;
        }}

        // 주어진 cellSize에서 보드 높이
        double boardHeight(double cs) => cs * _puzzle.rows;

        // 전체 필요 높이
        double totalHeight(double cs) => boardHeight(cs) + pieceWrapHeight(cs) + fixedUI;

        // 보드 기준 최대 cellSize
        final cBoardMax = (() {{
          final byW = (w * 0.94) / _puzzle.cols;
          final byH = (h * 0.60) / _puzzle.rows; // 보드 최대 60%
          return byW < byH ? byW : byH;
        }})();

        // 이진탐색: totalHeight(cs) <= h 인 최대 cs
        double lo = 16, hi = cBoardMax;
        for (int i = 0; i < 30; i++) {{
          final mid = (lo + hi) / 2;
          if (totalHeight(mid) <= h) {{
            lo = mid;
          }} else {{
            hi = mid;
          }}
        }}
        final cellSize = lo;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // ── 보드 영역 ────────────────────────────────────
            SizedBox(
              width: w,
              height: boardH + 15, // 안내텍스트 포함
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
            // ── 조각 영역 (Expanded: 남은 공간) ─────────────
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
                    Wrap(
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
