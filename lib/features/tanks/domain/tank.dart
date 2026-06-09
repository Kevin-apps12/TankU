import 'habitat.dart';

/// An aquarium or pond owned by a user.
class Tank {
  const Tank({
    required this.id,
    required this.name,
    required this.volumeLiters,
    this.habitat = Habitat.saltwater,
    this.tankType,
    this.startedOn,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String name;

  /// Display/storage is always in liters; UI can convert to gallons.
  final double volumeLiters;

  /// One of [Habitat.all]: freshwater, saltwater or pond. Decides which
  /// default parameters are tracked.
  final String habitat;

  /// Sub-type within the habitat, e.g. "Mixed Reef" (saltwater),
  /// "Planted" (freshwater) or "Koi" (pond).
  final String? tankType;
  final DateTime? startedOn;
  final String? notes;
  final DateTime? createdAt;

  double get volumeGallons => volumeLiters * 0.264172;

  factory Tank.fromJson(Map<String, dynamic> json) => Tank(
        id: json['id'] as String,
        name: json['name'] as String,
        volumeLiters: (json['volume_liters'] as num).toDouble(),
        habitat: json['habitat'] as String? ?? Habitat.saltwater,
        tankType: json['tank_type'] as String?,
        startedOn: json['started_on'] == null
            ? null
            : DateTime.parse(json['started_on'] as String),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
      );

  /// Fields a client is allowed to write. `id`/`user_id`/`created_at`
  /// are managed by the database.
  Map<String, dynamic> toInsert() => {
        'name': name,
        'volume_liters': volumeLiters,
        'habitat': habitat,
        'tank_type': tankType,
        'started_on': startedOn?.toIso8601String(),
        'notes': notes,
      };

  Tank copyWith({
    String? name,
    double? volumeLiters,
    String? habitat,
    String? tankType,
    DateTime? startedOn,
    String? notes,
  }) =>
      Tank(
        id: id,
        name: name ?? this.name,
        volumeLiters: volumeLiters ?? this.volumeLiters,
        habitat: habitat ?? this.habitat,
        tankType: tankType ?? this.tankType,
        startedOn: startedOn ?? this.startedOn,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
