class PlanetModel {
  final String name;
  final String type; // 'planet', 'dwarf_planet', 'moon', 'sun'
  final double radius; // km
  final double mass; // kg
  final double orbitalPeriod; // Earth days
  final double rotationPeriod; // hours
  final double semiMajorAxis; // AU
  final double eccentricity;
  final double inclination; // degrees
  final String description;

  PlanetModel({
    required this.name,
    required this.type,
    required this.radius,
    required this.mass,
    required this.orbitalPeriod,
    required this.rotationPeriod,
    required this.semiMajorAxis,
    required this.eccentricity,
    required this.inclination,
    required this.description,
  });

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'radius': radius,
      'mass': mass,
      'orbitalPeriod': orbitalPeriod,
      'rotationPeriod': rotationPeriod,
      'semiMajorAxis': semiMajorAxis,
      'eccentricity': eccentricity,
      'inclination': inclination,
      'description': description,
    };
  }

  // Create from map
  factory PlanetModel.fromMap(Map<String, dynamic> map) {
    return PlanetModel(
      name: map['name'] ?? '',
      type: map['type'] ?? 'planet',
      radius: (map['radius'] ?? 0.0).toDouble(),
      mass: (map['mass'] ?? 0.0).toDouble(),
      orbitalPeriod: (map['orbitalPeriod'] ?? 0.0).toDouble(),
      rotationPeriod: (map['rotationPeriod'] ?? 0.0).toDouble(),
      semiMajorAxis: (map['semiMajorAxis'] ?? 0.0).toDouble(),
      eccentricity: (map['eccentricity'] ?? 0.0).toDouble(),
      inclination: (map['inclination'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
    );
  }
}
