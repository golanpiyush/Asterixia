import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../utils/logger.dart';

class SensorService extends ChangeNotifier {
  // Orientation
  double _azimuth = 0.0; // 0-360 degrees, 0 = North
  double _pitch = 0.0; // -90 to 90 degrees, 0 = horizontal
  double _roll = 0.0; // -180 to 180 degrees

  // Raw sensor data
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;

  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // States
  bool _isCalibrated = false;
  bool _isSubscribed = false;
  String _error = '';

  // Stream subscriptions
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Getters
  double get azimuth => _azimuth;
  double get pitch => _pitch;
  double get roll => _roll;
  bool get isCalibrated => _isCalibrated;
  String get error => _error;

  // Initialize all sensors
  Future<void> initialize() async {
    try {
      // Check compass availability
      final compassAvailable = await FlutterCompass.events!.first
          .then((_) => true)
          .catchError((_) => false);

      if (!compassAvailable) {
        _error = 'Compass not available';
        notifyListeners();
        return;
      }

      // Subscribe to sensors
      await _subscribeToSensors();
      _isCalibrated = true;
      _error = '';

      Logger.info('Sensors initialized');
    } catch (e) {
      _error = 'Failed to initialize sensors: $e';
      Logger.error('Sensor initialization error', error: e);
      notifyListeners();
    }
  }

  Future<void> _subscribeToSensors() async {
    // Compass
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        _azimuth = 360.0 - event.heading!; // Convert to 0=N, clockwise
        _updateOrientation();
      }
    });

    // Accelerometer
    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _accelX = event.x;
      _accelY = event.y;
      _accelZ = event.z;
      _updateOrientation();
    });

    // Gyroscope
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
      // Gyro data could be used for smoothing in future
    });

    _isSubscribed = true;
  }

  void _updateOrientation() {
    // Calculate pitch and roll from accelerometer
    // Using simplified calculations - in production you'd want sensor fusion
    final gravity = sqrt(
      _accelX * _accelX + _accelY * _accelY + _accelZ * _accelZ,
    );

    if (gravity > 0) {
      // Pitch: rotation around X-axis
      _pitch = asin(_accelY / gravity) * (180.0 / pi);

      // Roll: rotation around Y-axis
      _roll = atan2(-_accelX, _accelZ) * (180.0 / pi);
    }

    notifyListeners();
  }

  // Get orientation as a map
  Map<String, double> getOrientation() {
    return {'azimuth': _azimuth, 'pitch': _pitch, 'roll': _roll};
  }

  // Get direction name
  String getDirectionName() {
    if (_azimuth >= 337.5 || _azimuth < 22.5) return 'N';
    if (_azimuth >= 22.5 && _azimuth < 67.5) return 'NE';
    if (_azimuth >= 67.5 && _azimuth < 112.5) return 'E';
    if (_azimuth >= 112.5 && _azimuth < 157.5) return 'SE';
    if (_azimuth >= 157.5 && _azimuth < 202.5) return 'S';
    if (_azimuth >= 202.5 && _azimuth < 247.5) return 'SW';
    if (_azimuth >= 247.5 && _azimuth < 292.5) return 'W';
    return 'NW';
  }

  // Clean up
  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    super.dispose();
  }
}
