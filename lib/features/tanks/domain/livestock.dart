/// A coral, fish, or invertebrate living in a tank.
class Livestock {
  const Livestock({
    required this.id,
    required this.tankId,
    required this.name,
    required this.kind,
    this.species,
    this.quantity = 1,
    this.addedOn,
    this.notes,
  });

  final String id;
  final String tankId;
  final String name;

  /// One of [LivestockKind.all].
  final String kind;
  final String? species;
  final int quantity;
  final DateTime? addedOn;
  final String? notes;

  factory Livestock.fromJson(Map<String, dynamic> json) => Livestock(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String? ?? 'other',
        species: json['species'] as String?,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        addedOn: json['added_on'] == null
            ? null
            : DateTime.parse(json['added_on'] as String),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'name': name,
        'kind': kind,
        'species': species,
        'quantity': quantity,
        'added_on': addedOn?.toIso8601String(),
        'notes': notes,
      };
}

class LivestockKind {
  // Saltwater
  static const fish = 'fish';
  static const sps = 'sps_coral';
  static const lps = 'lps_coral';
  static const softCoral = 'soft_coral';
  static const invertebrate = 'invertebrate';
  static const cuc = 'clean_up_crew';
  static const anemone = 'anemone';
  // Freshwater / pond
  static const shrimp = 'shrimp';
  static const snail = 'snail';
  static const crayfish = 'crayfish';
  static const plant = 'plant';
  static const amphibian = 'amphibian';
  static const other = 'other';

  static const saltwater = <String>[
    fish,
    sps,
    lps,
    softCoral,
    anemone,
    invertebrate,
    cuc,
    other,
  ];

  static const freshwater = <String>[
    fish,
    shrimp,
    snail,
    plant,
    crayfish,
    invertebrate,
    other,
  ];

  static const pond = <String>[
    fish,
    plant,
    snail,
    amphibian,
    other,
  ];

  /// Back-compat: the original saltwater-only list.
  static const all = saltwater;

  /// Kinds appropriate to a tank's habitat (see [Habitat]).
  static List<String> forHabitat(String habitat) => switch (habitat) {
        'freshwater' => freshwater,
        'pond' => pond,
        _ => saltwater,
      };
}
