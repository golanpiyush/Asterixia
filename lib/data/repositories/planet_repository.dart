import '../models/planet_model.dart';
import '../../core/services/data_loader.dart';
import '../../core/services/astronomy_service.dart';

class PlanetRepository {
  Future<List<PlanetModel>> getAllPlanets() async {
    final data = await DataLoader.loadPlanetData();
    final planetsData = data['planets'] as List<dynamic>;
    return planetsData
        .map((planetData) => PlanetModel.fromMap(planetData))
        .toList();
  }

  Future<PlanetModel?> getPlanetByName(String name) async {
    final allPlanets = await getAllPlanets();
    return allPlanets.firstWhere(
      (planet) => planet.name.toLowerCase() == name.toLowerCase(),
      orElse: () => PlanetModel(
        name: '',
        type: '',
        radius: 0.0,
        mass: 0.0,
        orbitalPeriod: 0.0,
        rotationPeriod: 0.0,
        semiMajorAxis: 0.0,
        eccentricity: 0.0,
        inclination: 0.0,
        description: '',
      ),
    );
  }

  Future<Map<String, Map<String, double>>> getPlanetPositions(
    double lat,
    double lon,
    DateTime time,
  ) async {
    return AstronomyService.getPlanetPositions(time, lat, lon);
  }

  Future<Map<String, double>> getSunPosition(
    double lat,
    double lon,
    DateTime time,
  ) async {
    return AstronomyService.getSunPosition(time, lat, lon);
  }

  Future<Map<String, double>> getMoonPosition(
    double lat,
    double lon,
    DateTime time,
  ) async {
    return AstronomyService.getMoonPosition(time, lat, lon);
  }
}
