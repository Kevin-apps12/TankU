/// Definition of a measurable water parameter.
///
/// Built-in types come from [ParameterCatalog.builtIns]. Users can add
/// their own custom types (stored in the `parameter_types` table) — the
/// app treats both identically.
class ParameterType {
  const ParameterType({
    required this.key,
    required this.label,
    required this.unit,
    this.idealMin,
    this.idealMax,
    this.decimals = 2,
    this.isCustom = false,
  });

  /// Stable identifier stored on each reading, e.g. "alkalinity".
  final String key;
  final String label;
  final String unit;

  /// Recommended reef range; used to flag out-of-range readings and to
  /// shade the chart. Null when not applicable.
  final double? idealMin;
  final double? idealMax;
  final int decimals;
  final bool isCustom;

  bool inRange(double value) {
    if (idealMin != null && value < idealMin!) return false;
    if (idealMax != null && value > idealMax!) return false;
    return true;
  }

  factory ParameterType.fromJson(Map<String, dynamic> json) => ParameterType(
        key: json['key'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String? ?? '',
        idealMin: (json['ideal_min'] as num?)?.toDouble(),
        idealMax: (json['ideal_max'] as num?)?.toDouble(),
        decimals: (json['decimals'] as num?)?.toInt() ?? 2,
        isCustom: true,
      );

  Map<String, dynamic> toInsert() => {
        'key': key,
        'label': label,
        'unit': unit,
        'ideal_min': idealMin,
        'ideal_max': idealMax,
        'decimals': decimals,
      };
}

/// Built-in parameters with typical mixed-reef target ranges.
class ParameterCatalog {
  static const temperature = ParameterType(
    key: 'temperature',
    label: 'Temperature',
    unit: '°C',
    idealMin: 24.5,
    idealMax: 26.5,
    decimals: 1,
  );
  static const alkalinity = ParameterType(
    key: 'alkalinity',
    label: 'Alkalinity',
    unit: 'dKH',
    idealMin: 8.0,
    idealMax: 9.5,
    decimals: 2,
  );
  static const calcium = ParameterType(
    key: 'calcium',
    label: 'Calcium',
    unit: 'ppm',
    idealMin: 400,
    idealMax: 450,
    decimals: 0,
  );
  static const magnesium = ParameterType(
    key: 'magnesium',
    label: 'Magnesium',
    unit: 'ppm',
    idealMin: 1250,
    idealMax: 1350,
    decimals: 0,
  );
  static const ph = ParameterType(
    key: 'ph',
    label: 'pH',
    unit: '',
    idealMin: 7.9,
    idealMax: 8.4,
    decimals: 2,
  );
  static const nitrate = ParameterType(
    key: 'nitrate',
    label: 'Nitrate (NO₃)',
    unit: 'ppm',
    idealMin: 2,
    idealMax: 10,
    decimals: 1,
  );
  static const phosphate = ParameterType(
    key: 'phosphate',
    label: 'Phosphate (PO₄)',
    unit: 'ppm',
    idealMin: 0.03,
    idealMax: 0.10,
    decimals: 3,
  );
  static const salinity = ParameterType(
    key: 'salinity',
    label: 'Salinity',
    unit: 'ppt',
    idealMin: 34,
    idealMax: 35,
    decimals: 1,
  );

  /// Saltwater / reef defaults.
  static const saltwater = <ParameterType>[
    alkalinity,
    calcium,
    magnesium,
    ph,
    temperature,
    nitrate,
    phosphate,
    salinity,
  ];

  /// Kept for back-compatibility; the original app was saltwater-only.
  static const builtIns = saltwater;

  /// Freshwater (tropical community / planted) defaults.
  static const freshwater = <ParameterType>[
    ParameterType(
      key: 'temperature',
      label: 'Temperature',
      unit: '°C',
      idealMin: 24,
      idealMax: 27,
      decimals: 1,
    ),
    ParameterType(
      key: 'ph',
      label: 'pH',
      unit: '',
      idealMin: 6.5,
      idealMax: 7.5,
      decimals: 2,
    ),
    ParameterType(
      key: 'ammonia',
      label: 'Ammonia (NH₃)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 0.02,
      decimals: 2,
    ),
    ParameterType(
      key: 'nitrite',
      label: 'Nitrite (NO₂)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 0.1,
      decimals: 2,
    ),
    ParameterType(
      key: 'nitrate',
      label: 'Nitrate (NO₃)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 20,
      decimals: 0,
    ),
    ParameterType(
      key: 'gh',
      label: 'General Hardness (GH)',
      unit: 'dGH',
      idealMin: 4,
      idealMax: 12,
      decimals: 0,
    ),
    ParameterType(
      key: 'kh',
      label: 'Carbonate Hardness (KH)',
      unit: 'dKH',
      idealMin: 3,
      idealMax: 8,
      decimals: 0,
    ),
    ParameterType(
      key: 'phosphate',
      label: 'Phosphate (PO₄)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 1.0,
      decimals: 2,
    ),
  ];

  /// Pond (koi / goldfish) defaults. Adds dissolved oxygen, which is critical
  /// for ponds, and tolerates higher nitrate.
  static const pond = <ParameterType>[
    ParameterType(
      key: 'temperature',
      label: 'Temperature',
      unit: '°C',
      idealMin: 10,
      idealMax: 24,
      decimals: 1,
    ),
    ParameterType(
      key: 'ph',
      label: 'pH',
      unit: '',
      idealMin: 7.0,
      idealMax: 8.5,
      decimals: 2,
    ),
    ParameterType(
      key: 'ammonia',
      label: 'Ammonia (NH₃)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 0.02,
      decimals: 2,
    ),
    ParameterType(
      key: 'nitrite',
      label: 'Nitrite (NO₂)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 0.1,
      decimals: 2,
    ),
    ParameterType(
      key: 'nitrate',
      label: 'Nitrate (NO₃)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 40,
      decimals: 0,
    ),
    ParameterType(
      key: 'kh',
      label: 'Carbonate Hardness (KH)',
      unit: 'dKH',
      idealMin: 4,
      idealMax: 8,
      decimals: 0,
    ),
    ParameterType(
      key: 'dissolved_oxygen',
      label: 'Dissolved O₂',
      unit: 'mg/L',
      idealMin: 6,
      idealMax: 9,
      decimals: 1,
    ),
    ParameterType(
      key: 'phosphate',
      label: 'Phosphate (PO₄)',
      unit: 'ppm',
      idealMin: 0,
      idealMax: 0.5,
      decimals: 2,
    ),
  ];

  /// The default parameter set for a given habitat string (see [Habitat]).
  static List<ParameterType> forHabitat(String habitat) => switch (habitat) {
        'freshwater' => freshwater,
        'pond' => pond,
        _ => saltwater,
      };

  static ParameterType? byKey(String key) {
    for (final p in [...saltwater, ...freshwater, ...pond]) {
      if (p.key == key) return p;
    }
    return null;
  }
}
