import 'dart:math';
import 'package:flutter/material.dart';
import '../models/session.dart';

class DayTimelineChart extends StatefulWidget {
  final List<Session> sessions;
  final Map<int, Color> categoryColors;
  final Map<int, String> categoryNames;
  final String date;
  final List<({DateTime start, DateTime end})> sleepSessions;

  const DayTimelineChart({
    super.key,
    required this.sessions,
    required this.categoryColors,
    required this.categoryNames,
    required this.date,
    this.sleepSessions = const [],
  });

  @override
  State<DayTimelineChart> createState() => _DayTimelineChartState();
}

class _TapInfo {
  final String name;
  final String timeRange;
  final Color color;
  _TapInfo({required this.name, required this.timeRange, required this.color});
}

class _DayTimelineChartState extends State<DayTimelineChart> {
  _TapInfo? _info;

  static const double _radius = 94.0; // ring radius (220/2 - 16)
  static const double _strokeWidth = 36.0;
  // CustomPaint(220x220) is centered in SizedBox(252x252) → offset = 16px
  static const double _offset = 16.0;

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _handleTouch(Offset local) {
    // SizedBox is 252x252; CustomPaint(220x220) is centered → ring center at (126,126)
    const ringCenter = Offset(110 + _offset, 110 + _offset);
    final dx = local.dx - ringCenter.dx;
    final dy = local.dy - ringCenter.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist < _radius - _strokeWidth / 2 || dist > _radius + _strokeWidth / 2) {
      setState(() => _info = null);
      return;
    }

    final angle = atan2(dy, dx);
    final normalized = (angle + pi / 2 + 2 * pi) % (2 * pi);
    final tapSec = (normalized / (2 * pi) * 86400).round();

    final dt = DateTime.tryParse(widget.date);
    if (dt == null) return;
    final midnight = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch ~/ 1000;
    const daySeconds = 86400;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // セッションを検索（後に描画されたものを優先）
    for (final s in widget.sessions.reversed) {
      final startSec = (s.startedAt - midnight).clamp(0, daySeconds);
      final endSec = ((s.endedAt ?? nowSec) - midnight).clamp(0, daySeconds);
      if (tapSec >= startSec && tapSec < endSec) {
        final name = widget.categoryNames[s.categoryId] ?? '不明';
        final color = widget.categoryColors[s.categoryId] ?? const Color(0xFF64B5F6);
        final startDt = DateTime.fromMillisecondsSinceEpoch(s.startedAt * 1000);
        final endDt = DateTime.fromMillisecondsSinceEpoch((s.endedAt ?? nowSec) * 1000);
        setState(() => _info = _TapInfo(
          name: name,
          timeRange: '${_fmt(startDt)} ~ ${_fmt(endDt)}',
          color: color,
        ));
        return;
      }
    }

    // 睡眠セッションを検索
    for (final sleep in widget.sleepSessions) {
      final startSec = (sleep.start.millisecondsSinceEpoch ~/ 1000 - midnight).clamp(0, daySeconds);
      final endSec = (sleep.end.millisecondsSinceEpoch ~/ 1000 - midnight).clamp(0, daySeconds);
      if (tapSec >= startSec && tapSec < endSec) {
        setState(() => _info = _TapInfo(
          name: '睡眠',
          timeRange: '${_fmt(sleep.start)} ~ ${_fmt(sleep.end)}',
          color: const Color(0xFF6366F1),
        ));
        return;
      }
    }

    setState(() => _info = null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => _handleTouch(d.localPosition),
      onPanStart: (d) => _handleTouch(d.localPosition),
      onPanUpdate: (d) => _handleTouch(d.localPosition),
      child: SizedBox(
        width: 252,
        height: 252,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(220, 220),
              painter: _TimelinePainter(
                sessions: widget.sessions,
                categoryColors: widget.categoryColors,
                date: widget.date,
                sleepSessions: widget.sleepSessions,
              ),
            ),
            if (_info != null)
              Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withAlpha(230),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _info!.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _info!.name,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _info!.timeRange,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<Session> sessions;
  final Map<int, Color> categoryColors;
  final String date;
  final List<({DateTime start, DateTime end})> sleepSessions;

  const _TimelinePainter({
    required this.sessions,
    required this.categoryColors,
    required this.date,
    required this.sleepSessions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 36.0;

    // 背景リング（未使用時間）
    final bgPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, bgPaint);

    // 時間マーカー（6時間ごと: 0/6/12/18）
    final markerPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int h = 0; h < 24; h += 6) {
      final angle = (h / 24) * 2 * pi - pi / 2;
      final innerR = radius - strokeWidth / 2 - 4;
      final outerR = radius + strokeWidth / 2 + 4;
      canvas.drawLine(
        center + Offset(cos(angle) * innerR, sin(angle) * innerR),
        center + Offset(cos(angle) * outerR, sin(angle) * outerR),
        markerPaint,
      );
    }

    // セッション弧
    final dt = DateTime.tryParse(date);
    if (dt == null) return;
    final midnight = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch ~/ 1000;
    const daySeconds = 24 * 3600;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 睡眠データ弧（セッション弧の下に描画）
    for (final sleep in sleepSessions) {
      final startSec = (sleep.start.millisecondsSinceEpoch ~/ 1000 - midnight)
          .clamp(0, daySeconds);
      final endSec = (sleep.end.millisecondsSinceEpoch ~/ 1000 - midnight)
          .clamp(0, daySeconds);
      final duration = endSec - startSec;
      if (duration <= 0) continue;

      final startAngle = (startSec / daySeconds) * 2 * pi - pi / 2;
      final sweepAngle = (duration / daySeconds) * 2 * pi;

      final paint = Paint()
        ..color = const Color(0xFF6366F1).withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    for (final s in sessions) {
      final startSec = (s.startedAt - midnight).clamp(0, daySeconds);
      final endSec = ((s.endedAt ?? nowSec) - midnight).clamp(0, daySeconds);
      final duration = endSec - startSec;
      if (duration <= 0) continue;

      final startAngle = (startSec / daySeconds) * 2 * pi - pi / 2;
      final sweepAngle = (duration / daySeconds) * 2 * pi;

      final color = categoryColors[s.categoryId] ?? const Color(0xFF64B5F6);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }

    // 時刻ラベル（0, 6, 12, 18）
    const textStyle = TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final labelRadius = radius + strokeWidth / 2 + 14;
    for (final entry in {0: '0', 6: '6', 12: '12', 18: '18'}.entries) {
      final angle = (entry.key / 24) * 2 * pi - pi / 2;
      final x = center.dx + cos(angle) * labelRadius;
      final y = center.dy + sin(angle) * labelRadius;
      final tp = TextPainter(
        text: TextSpan(text: entry.value, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.sessions != sessions ||
      old.date != date ||
      old.sleepSessions != sleepSessions;
}
