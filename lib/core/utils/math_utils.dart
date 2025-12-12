import 'dart:math';
import 'package:vector_math/vector_math.dart';

class MathUtils {
  // Constants
  static const double degToRad = pi / 180.0;
  static const double radToDeg = 180.0 / pi;
  static const double twoPi = 2.0 * pi;

  // Convert degrees to radians
  static double toRadians(double degrees) => degrees * degToRad;

  // Convert radians to degrees
  static double toDegrees(double radians) => radians * radToDeg;

  // Normalize angle to 0-360 degrees
  static double normalizeAngle(double angle) {
    double normalized = angle % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  // Convert equatorial coordinates (RA, Dec) to horizontal coordinates (Alt, Az)
  static Map<String, double> equatorialToHorizontal(
    double raHours, // Right Ascension in hours
    double decDeg, // Declination in degrees
    double lat, // Observer latitude in degrees
    double lon, // Observer longitude in degrees
    DateTime time, // Observer local time
  ) {
    // Convert to radians
    double ra = toRadians(raHours * 15.0); // Convert hours to degrees
    double dec = toRadians(decDeg);
    double phi = toRadians(lat);

    // Calculate Local Sidereal Time
    double lst = localSiderealTime(lon, time);
    double ha = toRadians(lst * 15.0) - ra; // Hour angle

    // Calculate altitude
    double sinAlt = sin(dec) * sin(phi) + cos(dec) * cos(phi) * cos(ha);
    double altitude = asin(sinAlt);

    // Calculate azimuth
    double cosAz =
        (sin(dec) - sin(altitude) * sin(phi)) / (cos(altitude) * cos(phi));
    cosAz = cosAz.clamp(-1.0, 1.0);
    double azimuth = acos(cosAz);

    // Determine azimuth quadrant
    if (sin(ha) > 0) {
      azimuth = twoPi - azimuth;
    }

    return {'altitude': toDegrees(altitude), 'azimuth': toDegrees(azimuth)};
  }

  // Calculate Local Sidereal Time
  static double localSiderealTime(double longitude, DateTime time) {
    // Convert to Julian Day
    double jd = julianDay(time);

    // Calculate Greenwich Sidereal Time
    double t = (jd - 2451545.0) / 36525.0;
    double gst =
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000.0;

    // Normalize and add longitude
    double lst = (gst + longitude) % 360.0;
    return lst / 15.0; // Convert to hours
  }

  // Calculate Julian Day
  static double julianDay(DateTime date) {
    int year = date.year;
    int month = date.month;
    int day = date.day;
    double hour = date.hour + date.minute / 60.0 + date.second / 3600.0;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    int a = (year / 100).floor();
    int b = 2 - a + (a / 4).floor();

    return (365.25 * (year + 4716)).floor().toDouble() +
        (30.6001 * (month + 1)).floor().toDouble() +
        day +
        b -
        1524.5 +
        hour / 24.0;
  }

  // Convert spherical to cartesian coordinates
  static Vector3 sphericalToCartesian(
    double radius,
    double azimuth,
    double altitude,
  ) {
    double azRad = toRadians(azimuth);
    double altRad = toRadians(altitude);

    double x = radius * cos(altRad) * sin(azRad);
    double y = radius * sin(altRad);
    double z = radius * cos(altRad) * cos(azRad);

    return Vector3(x, y, z);
  }

  // Calculate distance between two points in 3D space
  static double distance3D(Vector3 a, Vector3 b) {
    return sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2) + pow(a.z - b.z, 2));
  }
}
