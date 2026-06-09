/// The kind of aquatic habitat a tank represents. Every tank picks one, and
/// the habitat decides which default water parameters are tracked.
class Habitat {
  static const freshwater = 'freshwater';
  static const saltwater = 'saltwater';
  static const pond = 'pond';

  static const all = <String>[freshwater, saltwater, pond];

  static const _labels = <String, String>{
    freshwater: 'Freshwater',
    saltwater: 'Saltwater',
    pond: 'Pond',
  };

  static String label(String habitat) => _labels[habitat] ?? 'Saltwater';
}
