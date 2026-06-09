/// A piece of equipment attached to a tank (light, filter, pump, refugium...).
class Equipment {
  const Equipment({
    required this.id,
    required this.tankId,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.notes,
  });

  final String id;
  final String tankId;
  final String name;

  /// One of [EquipmentCategory.all].
  final String category;
  final String? brand;
  final String? model;
  final String? notes;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        tankId: json['tank_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'other',
        brand: json['brand'] as String?,
        model: json['model'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsert() => {
        'tank_id': tankId,
        'name': name,
        'category': category,
        'brand': brand,
        'model': model,
        'notes': notes,
      };
}

class EquipmentCategory {
  static const light = 'light';
  static const filter = 'filter';
  static const skimmer = 'skimmer';
  static const pump = 'pump';
  static const powerhead = 'powerhead';
  static const heater = 'heater';
  static const chiller = 'chiller';
  static const refugium = 'refugium';
  static const reactor = 'reactor';
  static const ato = 'ato';
  static const doser = 'doser';
  static const controller = 'controller';
  static const other = 'other';

  static const all = <String>[
    light,
    filter,
    skimmer,
    pump,
    powerhead,
    heater,
    chiller,
    refugium,
    reactor,
    ato,
    doser,
    controller,
    other,
  ];
}
