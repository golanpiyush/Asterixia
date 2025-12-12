import 'dart:math';
import '../utils/math_utils.dart';
import '../utils/time_utils.dart';
import '../utils/logger.dart';

class AstronomyService {
  // Astronomical constants
  static const double astronomicalUnit = 149597870.7; // km
  static const double earthRadius = 6371.0; // km

  // Get Sun position (simplified)
  static Map<String, double> getSunPosition(
    DateTime dateTime,
    double lat,
    double lon,
  ) {
    final t = TimeUtils.julianCenturies(dateTime);

    // Mean longitude
    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360.0;

    // Mean anomaly
    final m = (357.52911 + t * (35999.05029 - t * 0.0001537)) % 360.0;

    // Eccentricity
    final e = 0.016708634 - t * (0.000042037 + t * 0.0000001267);

    // Sun's equation of center
    final c =
        (1.914602 - t * (0.004817 + t * 0.000014)) *
            sin(m * MathUtils.degToRad) +
        (0.019993 - t * 0.000101) * sin(2 * m * MathUtils.degToRad) +
        0.000289 * sin(3 * m * MathUtils.degToRad);

    // True longitude
    final trueLong = l0 + c;

    // True anomaly
    final trueAnomaly = m + c;

    // Sun-Earth distance (AU)
    final distanceAU =
        (1.000001018 * (1 - e * e)) /
        (1 + e * cos(trueAnomaly * MathUtils.degToRad));

    // Apparent longitude (corrected for nutation and aberration)
    final apparentLong = trueLong - 0.00569;

    // Mean obliquity
    final obliquity =
        TimeUtils.meanObliquity(t) + 0.00256 * cos(m * MathUtils.degToRad);

    // Right Ascension and Declination
    final ra =
        atan2(
          cos(obliquity * MathUtils.degToRad) *
              sin(apparentLong * MathUtils.degToRad),
          cos(apparentLong * MathUtils.degToRad),
        ) *
        MathUtils.radToDeg;

    final dec =
        asin(
          sin(obliquity * MathUtils.degToRad) *
              sin(apparentLong * MathUtils.degToRad),
        ) *
        MathUtils.radToDeg;

    // Convert to Alt/Az
    final horizontal = MathUtils.equatorialToHorizontal(
      ra / 15.0, // Convert to hours
      dec,
      lat,
      lon,
      dateTime,
    );

    return {
      'rightAscension': ra,
      'declination': dec,
      'altitude': horizontal['altitude']!,
      'azimuth': horizontal['azimuth']!,
      'distance': distanceAU * astronomicalUnit,
    };
  }

  // Get Moon position (simplified)
  static Map<String, double> getMoonPosition(
    DateTime dateTime,
    double lat,
    double lon,
  ) {
    final t = TimeUtils.julianCenturies(dateTime);

    // Moon's mean longitude
    final l = (218.3164477 + t * (481267.88123421 - t * 0.0015786)) % 360.0;

    // Moon's mean anomaly
    final m = (134.9633964 + t * (477198.8675055 + t * 0.0087414)) % 360.0;

    // Moon's argument of latitude
    final f = (93.2720950 + t * (483202.0175233 - t * 0.0036539)) % 360.0;

    // Distance to Moon (km)
    final distance = 385000.56 + 20905.355 * cos(m * MathUtils.degToRad);

    // Geocentric latitude and longitude (simplified)
    final beta = 5.128 * sin(f * MathUtils.degToRad);
    final lambda = l + 6.289 * sin(m * MathUtils.degToRad);

    // Convert to Alt/Az (simplified - using Sun position as base)
    final sunPos = getSunPosition(dateTime, lat, lon);
    final moonAz =
        (sunPos['azimuth']! + 13.0) % 360.0; // Moon is about 13° from Sun
    final moonAlt = sunPos['altitude']! + 0.5; // Slightly different altitude

    return {'altitude': moonAlt, 'azimuth': moonAz, 'distance': distance};
  }

  // Get planet positions (simplified VSOP87)
  static Map<String, Map<String, double>> getPlanetPositions(
    DateTime dateTime,
    double lat,
    double lon,
  ) {
    final t = TimeUtils.julianCenturies(dateTime);
    final positions = <String, Map<String, double>>{};

    // Simplified orbital elements for major planets
    final planets = {
      'Mercury': {
        'a': 0.387099, // semi-major axis (AU)
        'e': 0.205636, // eccentricity
        'i': 7.005, // inclination (deg)
        'L': 252.251, // mean longitude (deg)
        'w': 77.456, // perihelion (deg)
        'N': 48.331, // ascending node (deg)
      },
      'Venus': {
        'a': 0.723332,
        'e': 0.006772,
        'i': 3.3946,
        'L': 181.979,
        'w': 131.533,
        'N': 76.680,
      },
      'Mars': {
        'a': 1.52371,
        'e': 0.09339,
        'i': 1.850,
        'L': 355.453,
        'w': 336.040,
        'N': 49.558,
      },
      'Jupiter': {
        'a': 5.2026,
        'e': 0.04850,
        'i': 1.303,
        'L': 34.404,
        'w': 14.753,
        'N': 100.556,
      },
      'Saturn': {
        'a': 9.5549,
        'e': 0.05551,
        'i': 2.489,
        'L': 50.075,
        'w': 92.431,
        'N': 113.715,
      },
      'Uranus': {
        'a': 19.2184,
        'e': 0.04630,
        'i': 0.773,
        'L': 314.055,
        'w': 170.964,
        'N': 74.229,
      },
      'Neptune': {
        'a': 30.1104,
        'e': 0.00899,
        'i': 1.770,
        'L': 304.345,
        'w': 44.971,
        'N': 131.721,
      },
    };

    // Calculate positions for each planet
    planets.forEach((name, elements) {
      // Simplified calculation - in production use full VSOP87
      final meanAnomaly = (elements['L']! - elements['w']!) % 360.0;
      final mRad = meanAnomaly * MathUtils.degToRad;

      // Solve Kepler's equation (simplified)
      double eccentricAnomaly = mRad;
      for (int i = 0; i < 3; i++) {
        eccentricAnomaly = mRad + elements['e']! * sin(eccentricAnomaly);
      }

      // True anomaly
      final trueAnomaly =
          2 *
          atan(
            sqrt((1 + elements['e']!) / (1 - elements['e']!)) *
                tan(eccentricAnomaly / 2),
          );

      // Distance
      final distance =
          elements['a']! * (1 - elements['e']! * cos(eccentricAnomaly));

      // Heliocentric coordinates (simplified)
      final x = distance * cos(trueAnomaly);
      final z = distance * sin(trueAnomaly);

      // Convert to geocentric and then to Alt/Az (simplified)
      // In reality, this requires complex coordinate transformations

      // For demo, place planets near ecliptic with some offset
      final sunPos = getSunPosition(dateTime, lat, lon);
      final planetOffset = 10.0 * (planets.keys.toList().indexOf(name) + 1);

      positions[name] = {
        'altitude': sunPos['altitude']! + planetOffset,
        'azimuth': (sunPos['azimuth']! + planetOffset) % 360.0,
        'distance': distance * astronomicalUnit,
      };
    });

    return positions;
  }

  // Get celestial equator coordinates
  static List<Map<String, double>> getCelestialEquatorPoints(
    double lat,
    double lon,
    DateTime time,
  ) {
    final points = <Map<String, double>>[];

    // Generate points along celestial equator
    for (int i = 0; i <= 360; i += 10) {
      final horizontal = MathUtils.equatorialToHorizontal(
        i / 15.0, // RA in hours
        0.0, // Dec = 0 for celestial equator
        lat,
        lon,
        time,
      );

      if (horizontal['altitude']! > -5.0) {
        // Only show above horizon
        points.add({
          'azimuth': horizontal['azimuth']!,
          'altitude': horizontal['altitude']!,
        });
      }
    }

    return points;
  }

  // Get ecliptic line coordinates
  static List<Map<String, double>> getEclipticPoints(
    double lat,
    double lon,
    DateTime time,
  ) {
    final points = <Map<String, double>>[];
    final obliquity = 23.44; // Earth's axial tilt

    // Generate points along ecliptic
    for (int i = 0; i <= 360; i += 10) {
      final dec = obliquity * sin(i * MathUtils.degToRad);
      final horizontal = MathUtils.equatorialToHorizontal(
        i / 15.0,
        dec,
        lat,
        lon,
        time,
      );

      if (horizontal['altitude']! > -5.0) {
        points.add({
          'azimuth': horizontal['azimuth']!,
          'altitude': horizontal['altitude']!,
        });
      }
    }

    return points;
  }

  // Get horizon circle points
  static List<Map<String, double>> getHorizonPoints() {
    final points = <Map<String, double>>[];

    // Generate horizon circle (altitude = 0)
    for (int i = 0; i <= 360; i += 10) {
      points.add({'azimuth': i.toDouble(), 'altitude': 0.0});
    }

    return points;
  }
}
