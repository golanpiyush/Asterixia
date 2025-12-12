class StarModel {
  final String name;
  final String designation;
  final double rightAscension; // hours
  final double declination; // degrees
  final double magnitude;
  final double distance; // light years
  final String spectralClass;
  final double temperature; // Kelvin

  StarModel({
    required this.name,
    required this.designation,
    required this.rightAscension,
    required this.declination,
    required this.magnitude,
    required this.distance,
    required this.spectralClass,
    required this.temperature,
  });

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'rightAscension': rightAscension,
      'declination': declination,
      'magnitude': magnitude,
      'distance': distance,
      'spectralClass': spectralClass,
      'temperature': temperature,
    };
  }

  // Create from map
  factory StarModel.fromMap(Map<String, dynamic> map) {
    return StarModel(
      name: map['name'] ?? '',
      designation: map['designation'] ?? '',
      rightAscension: (map['rightAscension'] ?? 0.0).toDouble(),
      declination: (map['declination'] ?? 0.0).toDouble(),
      magnitude: (map['magnitude'] ?? 0.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      spectralClass: map['spectralClass'] ?? '',
      temperature: (map['temperature'] ?? 0.0).toDouble(),
    );
  }
}
