// lib/core/services/ar_service.dart
import 'dart:math';

/// Helper class for AR-related calculations and conversions
class ARService {
  /// Convert astronomical coordinates (azimuth, altitude) to AR 3D position
  ///
  /// Azimuth: 0° = North, 90° = East, 180° = South, 270° = West
  /// Altitude: 0° = Horizon, 90° = Zenith (straight up)
  /// Distance: Distance from camera in AR space (meters)
  static ARPosition calculateARPosition(
    double azimuth,
    double altitude,
    double distance,
  ) {
    // Convert degrees to radians
    final azimuthRad = azimuth * pi / 180.0;
    final altitudeRad = altitude * pi / 180.0;

    // Convert spherical coordinates to Cartesian
    // In ARCore/ARKit coordinate system:
    // - X axis points to the right
    // - Y axis points up
    // - Z axis points toward the user (negative Z is forward/away)

    // Calculate horizontal distance from viewer
    final horizontalDistance = distance * cos(altitudeRad);

    // X: East-West (right is positive)
    // Using sin(azimuth) because 0° is North (into the screen)
    final x = horizontalDistance * sin(azimuthRad);

    // Y: Up-Down (up is positive)
    final y = distance * sin(altitudeRad);

    // Z: North-South (negative is away from user)
    // Using -cos(azimuth) because 0° is North (negative Z)
    final z = -horizontalDistance * cos(azimuthRad);

    return ARPosition(x, y, z);
  }

  /// Calculate appropriate scale for celestial objects based on their type
  static double calculateScale(String objectName, double distance) {
    // Base scales for different object types
    const scales = {
      // Sun
      'Sun': 0.5,

      // Moon
      'Moon': 0.12,

      // Inner planets
      'Mercury': 0.06,
      'Venus': 0.10,
      'Earth': 0.10,
      'Mars': 0.08,

      // Outer planets
      'Jupiter': 0.25,
      'Saturn': 0.22,
      'Uranus': 0.16,
      'Neptune': 0.15,

      // Stars (default)
      'Star': 0.02,
    };

    // Get base scale, default to star size if not found
    double baseScale = scales[objectName] ?? scales['Star']!;

    // Adjust scale based on distance (perspective)
    // Closer objects appear larger
    final distanceFactor = 10.0 / max(distance, 1.0);

    return baseScale * distanceFactor;
  }

  /// Calculate the distance adjustment based on object brightness
  /// Brighter objects can be placed slightly farther to appear more prominent
  static double calculateDistanceAdjustment(double magnitude) {
    // Magnitude is inverse logarithmic - lower numbers = brighter
    // Adjust distance: brighter objects (lower magnitude) get placed farther

    if (magnitude < -5) return 12.0; // Very bright (Sun, Moon)
    if (magnitude < 0) return 10.0; // Bright planets
    if (magnitude < 2) return 9.0; // Moderately bright
    if (magnitude < 4) return 8.0; // Dim
    return 7.0; // Very dim
  }

  /// Create a circle of points for guide lines (horizon, celestial equator, etc.)
  static List<Map<String, double>> createCirclePoints({
    required double altitude,
    double startAzimuth = 0.0,
    double endAzimuth = 360.0,
    int segments = 72, // 5-degree intervals
  }) {
    final points = <Map<String, double>>[];
    final step = (endAzimuth - startAzimuth) / segments;

    for (int i = 0; i <= segments; i++) {
      final azimuth = startAzimuth + (i * step);
      points.add({'azimuth': azimuth % 360, 'altitude': altitude});
    }

    return points;
  }

  /// Calculate the rotation quaternion for an object to face a specific direction
  static ARQuaternion calculateRotationToFace(ARPosition from, ARPosition to) {
    // Calculate direction vector
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final dz = to.z - from.z;

    // Normalize
    final length = sqrt(dx * dx + dy * dy + dz * dz);
    final nx = dx / length;
    final ny = dy / length;
    final nz = dz / length;

    // Calculate rotation angles
    final yaw = atan2(nx, -nz);
    final pitch = asin(ny);

    return ARQuaternion.fromEuler(pitch, yaw, 0);
  }

  /// Convert device orientation to astronomical azimuth
  /// Device azimuth: 0° = North, increases clockwise
  /// Astronomical azimuth: 0° = North, increases clockwise (same)
  static double deviceToAstronomicalAzimuth(double deviceAzimuth) {
    return deviceAzimuth;
  }

  /// Convert device pitch to astronomical altitude
  /// Device pitch: 0° = horizontal, 90° = pointing up, -90° = pointing down
  /// Astronomical altitude: 0° = horizon, 90° = zenith
  static double deviceToAstronomicalAltitude(double devicePitch) {
    return devicePitch;
  }

  /// Check if a celestial object is visible (above horizon)
  static bool isVisible(double altitude) {
    return altitude > -5.0; // Include objects slightly below horizon
  }

  /// Calculate visual magnitude adjustment for AR display
  static double calculateVisualBrightness(double magnitude) {
    // Convert magnitude to brightness scale (0.0 to 1.0)
    // Lower magnitude = brighter object

    // Clamp magnitude to reasonable range
    final clampedMag = magnitude.clamp(-5.0, 6.0);

    // Convert to 0-1 scale (inverted because lower mag = brighter)
    return 1.0 - ((clampedMag + 5.0) / 11.0);
  }

  /// Calculate color temperature for stars based on spectral type
  static int getStarColorFromTemperature(int temperatureKelvin) {
    if (temperatureKelvin < 3500) {
      return 0xFFFF4500; // Red/Orange (cool stars)
    } else if (temperatureKelvin < 5000) {
      return 0xFFFFD700; // Yellow (like our Sun)
    } else if (temperatureKelvin < 7500) {
      return 0xFFFFFFFF; // White
    } else if (temperatureKelvin < 10000) {
      return 0xFFB0C4DE; // Light blue
    } else {
      return 0xFF4169E1; // Deep blue (hot stars)
    }
  }

  /// Calculate atmospheric refraction effect
  /// Objects near the horizon appear higher due to atmospheric refraction
  static double calculateRefraction(double apparentAltitude) {
    if (apparentAltitude < -5) return 0.0;

    // Simplified refraction formula (in degrees)
    // More accurate near the horizon
    if (apparentAltitude < 15) {
      return 34.0 / 60.0; // ~34 arcminutes at horizon
    } else if (apparentAltitude < 45) {
      return (1.02 /
              tan(
                (apparentAltitude + 10.3 / (apparentAltitude + 5.11)) *
                    pi /
                    180,
              )) /
          60.0;
    } else {
      return 0.0; // Negligible refraction at high altitudes
    }
  }
}

/// Helper class to represent AR position in 3D space
class ARPosition {
  final double x;
  final double y;
  final double z;

  ARPosition(this.x, this.y, this.z);

  @override
  String toString() =>
      'ARPosition(x: ${x.toStringAsFixed(2)}, y: ${y.toStringAsFixed(2)}, z: ${z.toStringAsFixed(2)})';

  /// Calculate distance from origin
  double get magnitude => sqrt(x * x + y * y + z * z);

  /// Normalize the position
  ARPosition normalize() {
    final mag = magnitude;
    return ARPosition(x / mag, y / mag, z / mag);
  }

  /// Multiply by scalar
  ARPosition operator *(double scalar) {
    return ARPosition(x * scalar, y * scalar, z * scalar);
  }

  /// Add two positions
  ARPosition operator +(ARPosition other) {
    return ARPosition(x + other.x, y + other.y, z + other.z);
  }

  /// Subtract two positions
  ARPosition operator -(ARPosition other) {
    return ARPosition(x - other.x, y - other.y, z - other.z);
  }
}

/// Helper class to represent rotation as quaternion
class ARQuaternion {
  final double x;
  final double y;
  final double z;
  final double w;

  ARQuaternion(this.x, this.y, this.z, this.w);

  /// Create quaternion from Euler angles (in radians)
  factory ARQuaternion.fromEuler(double pitch, double yaw, double roll) {
    final cy = cos(yaw * 0.5);
    final sy = sin(yaw * 0.5);
    final cp = cos(pitch * 0.5);
    final sp = sin(pitch * 0.5);
    final cr = cos(roll * 0.5);
    final sr = sin(roll * 0.5);

    return ARQuaternion(
      sr * cp * cy - cr * sp * sy, // x
      cr * sp * cy + sr * cp * sy, // y
      cr * cp * sy - sr * sp * cy, // z
      cr * cp * cy + sr * sp * sy, // w
    );
  }

  @override
  String toString() => 'ARQuaternion(x: $x, y: $y, z: $z, w: $w)';
}
