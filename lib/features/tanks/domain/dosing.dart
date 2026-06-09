/// A recurring supplement/additive dose for a tank
/// (e.g. 10 mL/day of a two-part alkalinity supplement).
class Dosing {
  const Dosing({
    required this.id,
    required this.tankId,
    required this.product,
    required this.amount,
    required this.unit,
    required this.frequency,
    this.targetParameter,
    this.notes,
  });

  final String id;
  final String tankId;
  final String product;
  final double amount;

  /// e.g. "mL", "g", "drops".
  final String unit;

  /// One of [DosingFrequency.all].
  final String frequency;

  /// Optional parameter this dose targets, e.g. "alkalinity".
  final String? targetParameter;
  final String? notes;

  factory Dosing.fromJson(Map<String, dynamic> json) => Dosing(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        product: json['product'] as String,
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'] as String? ?? 'mL',
        frequency: json['frequency'] as String? ?? 'daily',
        targetParameter: json['target_parameter'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'product': product,
        'amount': amount,
        'unit': unit,
        'frequency': frequency,
        'target_parameter': targetParameter,
        'notes': notes,
      };
}

class DosingFrequency {
  static const daily = 'daily';
  static const weekly = 'weekly';
  static const asNeeded = 'as_needed';

  static const all = <String>[daily, weekly, asNeeded];
}
