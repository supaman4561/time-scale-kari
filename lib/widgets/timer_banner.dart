import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/date_utils.dart';

class TimerBanner extends StatefulWidget {
  final String categoryName;
  final int startedAt; // Unix seconds
  final VoidCallback onStop;

  const TimerBanner({
    super.key,
    required this.categoryName,
    required this.startedAt,
    required this.onStop,
  });

  @override
  State<TimerBanner> createState() => _TimerBannerState();
}

class _TimerBannerState extends State<TimerBanner> {
  late Timer _timer;
  late int _elapsed;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(_updateElapsed);
    });
  }

  void _updateElapsed() {
    _elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - widget.startedAt;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '計測中 — ${widget.categoryName}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(170),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDuration(_elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onStop,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                border: Border.all(color: Colors.white.withAlpha(60)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '停止',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
