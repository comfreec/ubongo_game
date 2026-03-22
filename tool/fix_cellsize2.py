# -*- coding: utf-8 -*-
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = """  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 보드 영역: 전체 높이의 52%, 조각 영역: 48%
        // 이렇게 비율로 나누면 어떤 화면 크기에서도 두 영역이 화면 안에 들어옴
        final boardAreaH = h * 0.50;

        // cellSize: 보드가 너비와 높이 안에 딱 맞게
        final cellByW = (w * 0.96) / _puzzle.cols;
        final cellByH = boardAreaH / _puzzle.rows;
        final cellSize = (cellByW < cellByH ? cellByW : cellByH).clamp(20.0, 72.0);

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // 보드 영역: 계산된 높이만큼
            SizedBox(
              width: w,
              height: boardH + 8,
              child: Center(
                child: SizedBox(
                  width: boardW,
                  height: boardH,
                  child: BoardWidget("""

new = """  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 상단 안내 텍스트 + 여백 고정 높이
        const topTextH = 11.0 + 4.0; // 텍스트 + SizedBox(4)
        // 하단 조각 영역 고정 높이: 텍스트(11) + SizedBox(6) + 버튼행(32) + 패딩(16+8) + 마진(8)
        const pieceAreaFixed = 11.0 + 6.0 + 32.0 + 24.0 + 8.0;
        // 조각 그리드 최소 높이 (조각 1줄: cellSize + 버튼28 + SizedBox4)
        // 보드가 쓸 수 있는 최대 높이
        final boardAreaH = h - topTextH - pieceAreaFixed - 80.0;

        // cellSize: 너비 기준과 높이 기준 중 작은 값 사용
        final cellByW = (w * 0.94) / _puzzle.cols;
        final cellByH = boardAreaH / _puzzle.rows;
        // clamp 없이 순수하게 min 값 사용 (화면에 딱 맞게)
        final cellSize = (cellByW < cellByH ? cellByW : cellByH).clamp(18.0, 60.0);

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;

        return Column(
          children: [
            // 보드 영역: 실제 보드 크기만큼만
            SizedBox(
              width: w,
              height: boardH + 8,
              child: Center(
                child: SizedBox(
                  width: boardW,
                  height: boardH,
                  child: BoardWidget("""

if old in content:
    content = content.replace(old, new)
    with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("OK")
else:
    print("ERROR: pattern not found")
    for i, line in enumerate(content.splitlines()):
        if 'boardAreaH' in line or 'cellByH' in line or 'cellSize' in line:
            print(f"  {i+1}: {line.strip()}")
