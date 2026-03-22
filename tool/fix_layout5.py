# -*- coding: utf-8 -*-
# 스크린샷 수치: h=720, w=411, bH=374, pH=345, maxR=4, cs=53.6
# 조각 3개, 큰 조각(T5=3x3, L5=4x2)이 있어서 한 줄에 2개씩 2줄 배치됨
# 2줄 배치 시 총 높이 = (53.6*4+32)*2 + 10 = (246.4)*2+10 = 502.8 > 345 → 잘림
#
# 해결: cellSize를 조각 배치 줄 수 고려해서 계산
# 조각 n개, 한 줄에 k개씩 → ceil(n/k)줄
# 줄 수 * (cellSize*maxRows + 32) + (줄수-1)*10 <= pieceAvailH
# pieceAvailH = pieceAreaH - 41
#
# 한 줄에 몇 개? → 조각 너비 기준: floor(w / (maxPieceCols*cellSize + 10))
# 이게 순환 참조라서, 먼저 cellSize 후보를 구하고 줄 수 계산 후 재조정

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

        // 보드 50% / 조각 50%
        final boardAreaH = h * 0.50;
        final pieceAreaH = h * 0.50;
        // 조각 컨테이너 내부 가용 높이 (패딩8*2 + 마진하단8 + 텍스트11 + SizedBox6 = 41)
        final pieceAvailH = pieceAreaH - 41;

        // 조각 최대 크기
        int maxPieceRows = 1;
        int maxPieceCols = 1;
        final pieceCount = _puzzle.pieceIds.length;
        for (final id in _puzzle.pieceIds) {{
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }}

        // 1단계: 보드 기준 cellSize 후보
        final cBoard = (w * 0.94) / _puzzle.cols < boardAreaH / _puzzle.rows
            ? (w * 0.94) / _puzzle.cols
            : boardAreaH / _puzzle.rows;

        // 2단계: 이 cellSize로 한 줄에 몇 개 들어가는지 계산
        // 조각 하나 너비 = cellSize * maxPieceCols
        // 한 줄 개수 = floor(w / (cellSize * maxPieceCols + 10))
        int perRow = (w / (cBoard * maxPieceCols + 10)).floor();
        if (perRow < 1) perRow = 1;
        // 줄 수
        final numRows = ((pieceCount + perRow - 1) ~/ perRow);
        // 필요한 높이 = numRows * (cellSize*maxPieceRows + 32) + (numRows-1)*10
        // 이게 pieceAvailH 이하여야 함
        // cellSize <= (pieceAvailH - (numRows-1)*10) / numRows - 32) / maxPieceRows
        final cPiece = ((pieceAvailH - (numRows - 1) * 10) / numRows - 32) / maxPieceRows;

        double cellSize = cBoard < cPiece ? cBoard : cPiece;
        if (cellSize < 16) cellSize = 16;

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
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
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
