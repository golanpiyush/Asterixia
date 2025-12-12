import '../models/star_model.dart';
import '../../core/services/data_loader.dart';

class StarRepository {
  Future<List<StarModel>> getAllStars() async {
    final data = await DataLoader.loadStarData();
    return data.map((starData) => StarModel.fromMap(starData)).toList();
  }

  Future<List<StarModel>> getBrightStars(double minMagnitude) async {
    final allStars = await getAllStars();
    return allStars.where((star) => star.magnitude <= minMagnitude).toList();
  }

  Future<List<StarModel>> getStarsInConstellation(String constellation) async {
    final allStars = await getAllStars();
    // In production, filter by constellation
    return allStars;
  }

  Future<StarModel?> getStarByName(String name) async {
    final allStars = await getAllStars();
    return allStars.firstWhere(
      (star) => star.name.toLowerCase() == name.toLowerCase(),
      orElse: () => StarModel(
        name: '',
        designation: '',
        rightAscension: 0.0,
        declination: 0.0,
        magnitude: 0.0,
        distance: 0.0,
        spectralClass: '',
        temperature: 0.0,
      ),
    );
  }
}
