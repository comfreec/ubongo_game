# -*- coding: utf-8 -*-
with open('lib/screens/game_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old = r"""  Widget _buildGameBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // 고정 UI 높이: 안내텍스트(16) + SizedBox(4+8) + 조각영역 최소(120) + 여백(24+8)
        const fixedUI = 16.0 + 12.0 + 120.0 + 32.0;
        final boardAreaH = h - fixedUI;

        // cellSize: 보드가 너비와 높이 안에 딱 맞게
        final cellByW = (w * 0.96) / _puzzle.cols;
        final cellByH = boardAreaH / _puzzle.rows;
        final cellSize = (cellByW < cellByH ? cellByW : cellByH).clamp(24.0, 80.0);

        final boardW = cellSize * _puzzle.cols;
        final boardH = cellSize * _puzzle.rows;"""

new = r"""  Widget _buildGameBody() {
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
        final boardH = cellSize * _puzzle.rows;"""

if old in content:
    content = content.replace(old, new)
    with open('lib/screens/game_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("OK: cellSize calculation updated")
else:
    print("ERROR: pattern not found")
    # 현재 파일에서 관련 라인 출력
    for i, line in enumerate(content.splitlines()):
        if 'boardAreaH' in line or 'fixedUI' in line or 'cellByH' in line:
            print(f"  Line {i+1}: {line}")
