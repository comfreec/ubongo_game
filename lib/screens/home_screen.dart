import 'dart:math';
import 'package:flutter/material.dart';
import '../data/puzzles.dart';
import '../models/puzzle.dart';
import '../services/score_service.dart';
import '../widgets/bg_particles.dart';
import '../widgets/tutorial_overlay.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late List<Puzzle> _allPuzzles;
  int _filterIndex = 0;
  Set<String> _completed = {};
  Map<String, int> _bestTimes = {};
  int _totalStars = 0;
  int _easyDone = 0, _medDone = 0, _hardDone = 0;
  int _easyTotal = 0, _medTotal = 0, _hardTotal = 0;
  late AnimationController _titleCtrl;
  late Animation<double> _titleAnim;

  @override
  void initState() {
    super.initState();
    _allPuzzles = getShuffledPuzzles();
    _loadProgress();
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _titleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_titleCtrl);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final completed = await ScoreService.getCompleted();
    final Map<String, int> bests = {};
    int totalStars = 0;
    int easyDone = 0, medDone = 0, hardDone = 0;
    int easyTotal = 0, medTotal = 0, hardTotal = 0;
    for (final p in _allPuzzles) {
      final c = p.pieceIds.length;
      if (c <= 3) easyTotal++;
      else if (c == 4) medTotal++;
      else hardTotal++;
      final b = await ScoreService.getBest(p.id);
      if (b != null) {
        bests[p.id] = b;
        totalStars += ScoreService.calcStars(b, _timerFor(p));
      }
      if (completed.contains(p.id)) {
        if (c <= 3) easyDone++;
        else if (c == 4) medDone++;
        else hardDone++;
      }
    }
    if (mounted) setState(() {
      _completed = completed;
      _bestTimes = bests;
      _totalStars = totalStars;
      _easyDone = easyDone; _medDone = medDone; _hardDone = hardDone;
      _easyTotal = easyTotal; _medTotal = medTotal; _hardTotal = hardTotal;
    });
  }

  List<Puzzle> get _filtered {
    switch (_filterIndex) {
      case 1: return _allPuzzles.where((p) => p.pieceIds.length <= 3).toList();
      case 2: return _allPuzzles.where((p) => p.pieceIds.length == 4).toList();
      case 3: return _allPuzzles.where((p) => p.pieceIds.length >= 5).toList();
      default: return _allPuzzles;
    }
  }

  int _timerFor(Puzzle p) {
    final c = p.pieceIds.length;
    if (c <= 3) return 90;
    if (c == 4) return 60;
    return 45;
  }

  int _starsFor(Puzzle p) {
    final best = _bestTimes[p.id];
    if (best == null) return 0;
    return ScoreService.calcStars(best, _timerFor(p));
  }

  void _startGame(Puzzle puzzle) {
    final globalIndex = _allPuzzles.indexOf(puzzle);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(puzzles: _allPuzzles, initialIndex: globalIndex),
      ),
    ).then((_) => _loadProgress());
  }
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = _allPuzzles.length;
    final done = _completed.length;
    final pct = total > 0 ? done / total : 0.0;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: TutorialOverlay(
        child: Stack(
          children: [
            const Positioned.fill(child: BgParticles()),
            Positioned(
              top: 0, left: 0, right: 0, height: 280,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A3E).withValues(alpha: 0.95),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildTitleSection(),
                  _buildProgressSection(done, total, pct),
                  const SizedBox(height: 10),
                  _buildFilterRow(),
                  const SizedBox(height: 6),
                  Expanded(child: _buildPuzzleList(filtered)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _titleAnim,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.amber.withValues(alpha: 0.25 + _titleAnim.value * 0.1),
                  Colors.orange.withValues(alpha: 0.15),
                ]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.4 + _titleAnim.value * 0.2),
                  width: 1.5,
                ),
                boxShadow: [BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.15 + _titleAnim.value * 0.1),
                  blurRadius: 12, spreadRadius: 1,
                )],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    '$_totalStars / ${_allPuzzles.length * 3}',
                    style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ).then((_) => _loadProgress()),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.settings, color: Colors.white60, size: 20),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _titleAnim,
            builder: (_, __) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  const Color(0xFF4D96FF),
                  Color.lerp(const Color(0xFF9B59FF), const Color(0xFF4DFFB4), _titleAnim.value)!,
                  const Color(0xFF4D96FF),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                '블록피트',
                style: TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900, letterSpacing: 3),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '조각을 맞춰 보드를 채우세요',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int done, int total, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64, height: 64,
              child: CustomPaint(
                painter: _CircleProgressPainter(pct),
                child: Center(
                  child: Text(
                    '${(pct * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('전체 진행률', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      Text('$done / $total 완료', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _DiffBar(label: '쉽음', done: _easyDone, total: _easyTotal, color: const Color(0xFF6BCB77)),
                      const SizedBox(width: 8),
                      _DiffBar(label: '보통', done: _medDone, total: _medTotal, color: const Color(0xFFFF922B)),
                      const SizedBox(width: 8),
                      _DiffBar(label: '어려움', done: _hardDone, total: _hardTotal, color: const Color(0xFFFF6B6B)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final labels = ['전체', '쉽음', '보통', '어려움'];
    final colors = [Colors.white70, const Color(0xFF6BCB77), const Color(0xFFFF922B), const Color(0xFFFF6B6B)];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(labels.length, (i) => Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
          child: _FilterChip(
            label: labels[i], selected: _filterIndex == i,
            color: colors[i], onTap: () => setState(() => _filterIndex = i),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _allPuzzles = getShuffledPuzzles()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.shuffle, color: Colors.blueAccent, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzleList(List<Puzzle> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final puzzle = filtered[i];
        final count = puzzle.pieceIds.length;
        final isEasy = count <= 3;
        final isHard = count >= 5;
        final isCleared = _completed.contains(puzzle.id);
        final stars = _starsFor(puzzle);
        return _PuzzleCard(
          index: i + 1, puzzle: puzzle, isEasy: isEasy, isHard: isHard,
          isCleared: isCleared, stars: stars, onTap: () => _startGame(puzzle),
        );
      },
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double value;
  _CircleProgressPainter(this.value);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (size.width - 10) / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke ..strokeWidth = 6);
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, -pi / 2, 2 * pi * value, false, Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF4D96FF), Color(0xFF4DFFB4)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ).createShader(rect)
      ..style = PaintingStyle.stroke ..strokeWidth = 6 ..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(_CircleProgressPainter old) => old.value != value;
}

class _DiffBar extends StatelessWidget {
  final String label;
  final int done, total;
  final Color color;
  const _DiffBar({required this.label, required this.done, required this.total, required this.color});
  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? done / total : 0.0;
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        Text('$done/$total', style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 10)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(borderRadius: BorderRadius.circular(4), child: Stack(children: [
        Container(height: 6, color: Colors.white.withValues(alpha: 0.07)),
        FractionallySizedBox(widthFactor: ratio, child: Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
            borderRadius: BorderRadius.circular(4),
          ),
        )),
      ])),
    ]));
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.white.withValues(alpha: 0.15), width: selected ? 1.5 : 1),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 8)] : [],
        ),
        child: Text(label, style: TextStyle(
          color: selected ? color : Colors.white.withValues(alpha: 0.35),
          fontSize: 13, fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        )),
      ),
    );
  }
}

class _PuzzleCard extends StatefulWidget {
  final int index;
  final Puzzle puzzle;
  final bool isEasy, isHard, isCleared;
  final int stars;
  final VoidCallback onTap;
  const _PuzzleCard({required this.index, required this.puzzle, required this.isEasy,
    required this.isHard, required this.isCleared, required this.stars, required this.onTap});
  @override
  State<_PuzzleCard> createState() => _PuzzleCardState();
}

class _PuzzleCardState extends State<_PuzzleCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final diffColor = widget.isEasy ? const Color(0xFF6BCB77) : widget.isHard ? const Color(0xFFFF6B6B) : const Color(0xFFFF922B);
    final diffLabel = widget.isEasy ? '쉽음' : widget.isHard ? '어려움' : '보통';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 10),
        transform: Matrix4.identity()..scale(_pressed ? 0.97 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: widget.isCleared
                ? [const Color(0xFF1A2E20), const Color(0xFF0F1F14)]
                : [const Color(0xFF1C2340), const Color(0xFF111828)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isCleared ? const Color(0xFF6BCB77).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [BoxShadow(
            color: widget.isCleared ? const Color(0xFF6BCB77).withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            _MiniBoardPreview(puzzle: widget.puzzle, isCleared: widget.isCleared, diffColor: diffColor),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('퍼즐 ${widget.index}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.isCleared) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6BCB77).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6BCB77).withValues(alpha: 0.4)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check, color: Color(0xFF6BCB77), size: 11),
                    SizedBox(width: 3),
                    Text('완료', style: TextStyle(color: Color(0xFF6BCB77), fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(diffLabel, style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                Text('${widget.puzzle.rows}x${widget.puzzle.cols}  ·  조각 ${widget.puzzle.pieceIds.length}개',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              ]),
              if (widget.isCleared && widget.stars > 0) ...[
                const SizedBox(height: 6),
                Row(children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    i < widget.stars ? Icons.star : Icons.star_border,
                    color: i < widget.stars ? Colors.amber : Colors.white24, size: 16,
                  ),
                ))),
              ],
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.25), size: 22),
          ]),
        ),
      ),
    );
  }
}

class _MiniBoardPreview extends StatelessWidget {
  final Puzzle puzzle;
  final bool isCleared;
  final Color diffColor;
  const _MiniBoardPreview({required this.puzzle, required this.isCleared, required this.diffColor});
  @override
  Widget build(BuildContext context) {
    const sz = 58.0;
    final cs = (sz / (puzzle.rows > puzzle.cols ? puzzle.rows : puzzle.cols)).clamp(4.0, 12.0);
    return Container(
      width: sz, height: sz,
      decoration: BoxDecoration(
        color: const Color(0xFF080E1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCleared ? const Color(0xFF6BCB77).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [BoxShadow(color: (isCleared ? const Color(0xFF6BCB77) : diffColor).withValues(alpha: 0.12), blurRadius: 8)],
      ),
      child: Center(child: CustomPaint(
        size: Size(cs * puzzle.cols, cs * puzzle.rows),
        painter: _MiniBoardPainter(puzzle, isCleared, diffColor, cs),
      )),
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  final Puzzle puzzle;
  final bool isCleared;
  final Color diffColor;
  final double cs;
  _MiniBoardPainter(this.puzzle, this.isCleared, this.diffColor, this.cs);
  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.0;
    for (int r = 0; r < puzzle.rows; r++) {
      for (int c = 0; c < puzzle.cols; c++) {
        final active = puzzle.grid[r][c];
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * cs + gap, r * cs + gap, cs - gap * 2, cs - gap * 2),
          Radius.circular(cs * 0.25),
        );
        if (active) {
          canvas.drawRRect(rect, Paint()..shader = LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isCleared ? [const Color(0xFF6BCB77), const Color(0xFF20C997)]
                : [diffColor.withValues(alpha: 0.9), diffColor.withValues(alpha: 0.5)],
          ).createShader(Rect.fromLTWH(c * cs, r * cs, cs, cs)));
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(c * cs + gap, r * cs + gap, cs - gap * 2, 2), Radius.circular(cs * 0.25)),
            Paint()..color = Colors.white.withValues(alpha: 0.3),
          );
        } else {
          canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.04));
        }
      }
    }
  }
  @override
  bool shouldRepaint(_MiniBoardPainter old) => false;
}
