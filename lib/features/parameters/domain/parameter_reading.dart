/// A single measured value for a parameter on a tank at a point in time.
class ParameterReading {
  const ParameterReading({
    required this.id,
    required this.tankId,
    required this.parameterKey,
    required this.value,
    required this.measuredAt,
    this.notes,
  });

  final String id;
  final String tankId;
  final String parameterKey;
  final double value;
  final DateTime measuredAt;
  final String? notes;

  factory ParameterReading.fromJson(Map<String, dynamic> json) =>
      ParameterReading(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        parameterKey: json['parameter_key'] as String,
        value: (json['value'] as num).toDouble(),
        measuredAt: DateTime.parse(json['measured_at'] as String).toLocal(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'parameter_key': parameterKey,
        'value': value,
        'measured_at': measuredAt.toUtc().toIso8601String(),
        'notes': notes,
      };
}
