class Session {
  final int? id;
  final int categoryId;
  final String date; // YYYY-MM-DD
  final int startedAt; // Unix timestamp (seconds)
  final int? endedAt;
  final int? durationSec;

  const Session({
    this.id,
    required this.categoryId,
    required this.date,
    required this.startedAt,
    this.endedAt,
    this.durationSec,
  });

  factory Session.fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int,
        date: map['date'] as String,
        startedAt: map['started_at'] as int,
        endedAt: map['ended_at'] as int?,
        durationSec: map['duration_sec'] as int?,
      );

  bool get isInProgress => endedAt == null;
}
