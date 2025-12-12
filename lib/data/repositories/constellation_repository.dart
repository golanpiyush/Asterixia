import '../models/constellation_model.dart';
import '../../core/services/data_loader.dart';

class ConstellationRepository {
  Future<List<ConstellationModel>> getAllConstellations() async {
    final data = await DataLoader.loadConstellationData();
    return data
        .map((constData) => ConstellationModel.fromMap(constData))
        .toList();
  }

  Future<ConstellationModel?> getConstellationByName(String name) async {
    final allConstellations = await getAllConstellations();
    return allConstellations.firstWhere(
      (constellation) => constellation.name.toLowerCase() == name.toLowerCase(),
      orElse: () => ConstellationModel(
        name: '',
        abbreviation: '',
        genitive: '',
        meaning: '',
        boundaries: [],
        stars: [],
        brightestStarMagnitude: 0.0,
      ),
    );
  }

  Future<List<ConstellationModel>> getVisibleConstellations(
    double lat,
    double lon,
    DateTime time,
  ) async {
    // In production, calculate which constellations are visible
    return getAllConstellations();
  }
}
