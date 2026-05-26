import 'dart:math';
import 'package:flutter/material.dart';
import '../models/session.dart';

class DayTimelineChart extends StatelessWidget {
  final List<Session> sessions;
  final Map<int, Color> categoryColors; // categoryId -> Color
  final String date; // YYYY-MM-DD
  final List<({DateTime start, DateTime end})> sleepSessions;

  const DayTimelineChart({
    super.key,
    required this.sessions,
    required this.categoryColors,
    required this.date,
    this.sleepSessions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(
        painter: _TimelinePainter(
          sessions: sessions,
          categoryColors: categoryColors,
          date: date,
          sleepSessions: sleepSessions,
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
