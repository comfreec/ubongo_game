# -*- coding: utf-8 -*-
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "  Widget _buildGameBody() {"
end_marker   = "  Widget _buildResultOverlay() {"

start_idx = content.find(start_marker)
end_idx   = content.find(end_marker)

new_method = """  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final boardAreaH = h * 0.52;
        final pieceAreaH = h * 0.48;

        int maxPieceRows = 1;
        int maxPieceCols = 1;
        for (final id in _puzzle.pieceIds) {
          final p = allPieces[id]!;
          if (p.maxRow + 1 > maxPieceRows) maxPieceRows = p.maxRow + 1;
          if (p.maxCol + 1 > maxPieceCols) maxPieceCols = p.maxCol + 1;
        }

        final c1 = (w * 0.94) / _puzzle.cols;
        final c2 = boardAreaH / _puzzle.rows;
        final c3 = (pieceAreaH - 73) / maxPieceRows;
        final c4 = (w - 36) / (maxPieceCols * 2 + 1).toDouble();

        double cellSize = [c1, c2, c3, c4].reduce((a, b) => a < b ? a : b);
        if (cellSize < 16) cellSize = 16;

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        // DEBUG: 수치 표시
        return Column(
          children: [
            Container(
              color: Colors.red.withValues(alpha: 0.8),
              padding: const EdgeInsets.all(4),
              child: Text(
                'h=${h.toInt()} w=${w.toInt()} cs=${cellSize.toStringAsFixed(1)}\\n'
                'bH=${boardAreaH.toInt()} pH=${pieceAreaH.toInt()} maxR=$maxPieceRows\\n'
                'c1=${c1.toStringAsFixed(1)} c2=${c2.toStringAsFixed(1)} c3=${c3.toStringAsFixed(1)} c4=${c4.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            SizedBox(
              width: w,
              height: boardAreaH - 50,
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
                ],
              ),
            ),
            SizedBox(
              width: w,
              height: pieceAreaH,
              child: Container(
                color: Colors.blue.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    const Text('piece area', style: TextStyle(color: Colors.white54, fontSize: 11)),
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

new_content = content[:start_idx] + new_method + content[end_idx:]

with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)

with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    c = f.read()
print(f"Lines: {len(c.splitlines())}, Braces: {c.count(chr(123))}/{c.count(chr(125))}")
