/// A recurring feeding for a tank (e.g. "1 cube of frozen mysis, twice daily").
class Feeding {
  const Feeding({
    required this.id,
    required this.tankId,
    required this.food,
    required this.frequency,
    this.amount,
    this.notes,
  });

  final String id;
  final String tankId;
  final String food;

  /// Free-text amount, e.g. "1 cube", "pinch", "small sheet". Optional because
  /// feeding amounts are rarely a clean number.
  final String? amount;

  /// One of [FeedingFrequency.all].
  final String frequency;
  final String? notes;

  factory Feeding.fromJson(Map<String, dynamic> json) => Feeding(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        food: json['food'] as String,
        amount: json['amount'] as String?,
        frequency: json['frequency'] as String? ?? 'once_daily',
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'food': food,
        'amount': amount,
        'frequency': frequency,
        'notes': notes,
      };
}

class FeedingFrequency {
  static const onceDaily = 'once_daily';
  static const twiceDaily = 'twice_daily';
  static const threeTimesDaily = 'three_times_daily';
  static const everyOtherDay = 'every_other_day';
  static const weekly = 'weekly';
  static const asNeeded = 'as_needed';

  static const all = <String>[
    onceDaily,
    twiceDaily,
    threeTimesDaily,
    everyOtherDay,
    weekly,
    asNeeded,
  ];

  static String label(String freq) => switch (freq) {
        onceDaily => 'Once daily',
        twiceDaily => 'Twice daily',
        threeTimesDaily => '3× daily',
        everyOtherDay => 'Every other day',
        weekly => 'Weekly',
        asNeeded => 'As needed',
        _ => freq.replaceAll('_', ' '),
      };
}
