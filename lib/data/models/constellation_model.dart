class ConstellationModel {
  final String name;
  final String abbreviation;
  final String genitive;
  final String meaning;
  final List<List<double>> boundaries; // List of RA/Dec points
  final List<Map<String, double>> stars; // Major stars in constellation
  final double brightestStarMagnitude;

  ConstellationModel({
    required this.name,
    required this.abbreviation,
    required this.genitive,
    required this.meaning,
    required this.boundaries,
    required this.stars,
    required this.brightestStarMagnitude,
  });

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'genitive': genitive,
      'meaning': meaning,
      'boundaries': boundaries,
      'stars': stars,
      'brightestStarMagnitude': brightestStarMagnitude,
    };
  }

  // Create from map
  factory ConstellationModel.fromMap(Map<String, dynamic> map) {
    return ConstellationModel(
      name: map['name'] ?? '',
      abbreviation: map['abbreviation'] ?? '',
      genitive: map['genitive'] ?? '',
      meaning: map['meaning'] ?? '',
      boundaries: List<List<double>>.from(
        map['boundaries']?.map((x) => List<double>.from(x)) ?? [],
      ),
      stars: List<Map<String, double>>.from(map['stars'] ?? []),
      brightestStarMagnitude: (map['brightestStarMagnitude'] ?? 0.0).toDouble(),
    );
  }
}
