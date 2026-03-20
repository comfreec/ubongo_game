/// 퍼즐 카드: 보드 모양 + 사용할 조각 ID 목록
class Puzzle {
  final String id;
  final int rows;
  final int cols;

  /// true = 채워야 할 칸, false = 빈칸(사용 불가)
  final List<List<bool>> grid;

  /// 이 퍼즐에서 사용할 조각 ID 목록
  final List<String> pieceIds;

  const Puzzle({
    required this.id,
    required this.rows,
    required this.cols,
    required this.grid,
    required this.pieceIds,
  });
}
