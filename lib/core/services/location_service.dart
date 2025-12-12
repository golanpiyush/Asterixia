import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/logger.dart';

class LocationService extends ChangeNotifier {
  double _latitude = 0.0;
  double _longitude = 0.0;
  double _altitude = 0.0;
  bool _isLoading = false;
  String _error = '';

  double get latitude => _latitude;
  double get longitude => _longitude;
  double get altitude => _altitude;
  bool get isLoading => _isLoading;
  String get error => _error;

  bool get hasLocation => _latitude != 0.0 && _longitude != 0.0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permission permanently denied';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
      _error = '';

      Logger.info('Location acquired: $_latitude, $_longitude');
    } catch (e) {
      _error = 'Failed to get location: $e';
      Logger.error('Location service error', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get position stream for continuous updates
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Calculate distance between two coordinates in meters
  double calculateDistance(double lat2, double lon2) {
    if (!hasLocation) return 0.0;
    return Geolocator.distanceBetween(_latitude, _longitude, lat2, lon2);
  }

  // Get location name (using geocoding)
  Future<String> getLocationName() async {
    if (!hasLocation) return 'Unknown Location';

    try {
      final placemarks = await placemarkFromCoordinates(_latitude, _longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final locality = place.locality ?? '';
        final adminArea = place.administrativeArea ?? '';

        if (locality.isNotEmpty && adminArea.isNotEmpty) {
          return '$locality, $adminArea';
        } else if (locality.isNotEmpty) {
          return locality;
        } else if (adminArea.isNotEmpty) {
          return adminArea;
        }
      }
    } catch (e) {
      Logger.error('Failed to get location name', error: e);
    }

    return '${_latitude.toStringAsFixed(4)}°, ${_longitude.toStringAsFixed(4)}°';
  }

  // Method to refresh location
  Future<void> refreshLocation() async {
    await initialize();
  }

  // Clean up resources
  @override
  void dispose() {
    super.dispose();
  }
}
