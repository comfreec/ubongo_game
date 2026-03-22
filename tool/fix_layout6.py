# -*- coding: utf-8 -*-
# 스크린샷2: h=720, w=411, cs=75.1, maxR=3, pieceCount=3
# L4(3행), L5(4행) 조각이 세로로 길어서 2개가 세로 배치되면 넘침
#
# 핵심 공식:
# 조각 n개가 한 줄에 k개씩 배치될 때 줄 수 = ceil(n/k)
# k = floor(w / (cellSize * maxPieceCols + 10))
# 이 순환을 이진탐색으로 해결

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

        final boardAreaH = h * 0.50;
        // 조각 컨테이너 내부 가용 높이
        // Expanded가 남은 공간 차지, 패딩8*2 + 마진하단8 + 텍스트11 + SizedBox6 = 41
        final pieceAvailH = h * 0.50 - 41;

        int maxPieceRows = 1;
        int maxPieceCols = 1;
        final pieceCount = _puzzle.pieceIds.length;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }}

        // 보드 기준 cellSize
        final cBoard = (() {{
          final byW = (w * 0.94) / _puzzle.cols;
          final byH = boardAreaH / _puzzle.rows;
          return byW < byH ? byW : byH;
        }})();

        // 조각 배치 기준 cellSize: 이진탐색
        // 주어진 cellSize에서 Wrap 총 높이 계산
        double calcPieceHeight(double cs) {{
          final pieceW = cs * maxPieceCols;
          final perRow = ((w - 16) / (pieceW + 10)).floor().clamp(1, pieceCount);
          final rows = ((pieceCount + perRow - 1) ~/ perRow);
          final pieceH = cs * maxPieceRows + 32; // 32 = SizedBox(4) + 버튼(28)
          return rows * pieceH + (rows - 1) * 10;
        }}

        // 이진탐색: pieceAvailH 안에 들어오는 최대 cellSize
        double lo = 16, hi = cBoard;
        for (int i = 0; i < 20; i++) {{
          final mid = (lo + hi) / 2;
          if (calcPieceHeight(mid) <= pieceAvailH) {{
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
                  children: [
                    const Text('{txt_hint}',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
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
print(f"Lines: {len(c.splitlines())}, Braces: {c.count(chr(123))}/{c.count(chr(125))}")
