import 'dart:math';

class TimeUtils {
  // Convert DateTime to Julian Date (simplified)
  static double toJulianDate(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month;
    final day = dateTime.day;
    final hour =
        dateTime.hour + dateTime.minute / 60.0 + dateTime.second / 3600.0;

    if (month <= 2) {
      return 367 * year -
          ((7 * (year + 5001 + (month - 9) / 7)) / 4).floor() +
          ((275 * month) / 9).floor() +
          day +
          1729777 -
          0.5 +
          hour / 24.0;
    } else {
      return 367 * year -
          ((7 * (year + (month - 9) / 7)) / 4).floor() +
          ((275 * month) / 9).floor() +
          day +
          1729777 -
          0.5 +
          hour / 24.0;
    }
  }

  // Get current time in Julian Centuries
  static double julianCenturies(DateTime dateTime) {
    final jd = toJulianDate(dateTime);
    return (jd - 2451545.0) / 36525.0;
  }

  // Get mean obliquity of the ecliptic
  static double meanObliquity(double t) {
    // t in Julian centuries
    final seconds = 21.448 - t * (46.815 + t * (0.00059 - t * 0.001813));
    return 23.0 + (26.0 + seconds / 60.0) / 60.0;
  }

  // Get Greenwich Mean Sidereal Time
  static double greenwichMeanSiderealTime(DateTime dateTime) {
    final jd = toJulianDate(dateTime);
    final t = (jd - 2451545.0) / 36525.0;

    // GMST in degrees
    final gmst =
        280.46061837 +
        360.98564736629 * (jd - 2451545.0) +
        0.000387933 * t * t -
        t * t * t / 38710000.0;

    return gmst % 360.0;
  }

  // Format time for display
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Format date for display
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
