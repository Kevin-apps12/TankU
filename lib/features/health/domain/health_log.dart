/// A point-in-time health journal entry for a tank: a 1-10 rating plus an
/// optional written observation of how the reef looks.
class HealthLog {
  const HealthLog({
    required this.id,
    required this.tankId,
    required this.rating,
    required this.observedAt,
    this.notes,
  });

  final String id;
  final String tankId;

  /// 1 (struggling) … 10 (thriving).
  final int rating;
  final DateTime observedAt;
  final String? notes;

  factory HealthLog.fromJson(Map<String, dynamic> json) => HealthLog(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        rating: (json['rating'] as num).toInt(),
        observedAt: DateTime.parse(json['observed_at'] as String).toLocal(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'rating': rating,
        'observed_at': observedAt.toUtc().toIso8601String(),
        'notes': notes,
      };

  /// Short qualitative label for a rating.
  static String labelFor(int rating) {
    if (rating <= 2) return 'Struggling';
    if (rating <= 4) return 'Poor';
    if (rating <= 6) return 'Fair';
    if (rating <= 8) return 'Good';
    return 'Thriving';
  }
}
