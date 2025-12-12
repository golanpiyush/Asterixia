import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF4A42D6);
  static const Color primaryLight = Color(0xFF9B94FF);

  // Celestial bodies
  static const Color sun = Color(0xFFFFD700);
  static const Color moon = Color(0xFFD3D3D3);
  static const Color mercury = Color(0xFFA9A9A9);
  static const Color venus = Color(0xFFFFC8A2);
  static const Color earth = Color(0xFF6495ED);
  static const Color mars = Color(0xFFFF6B6B);
  static const Color jupiter = Color(0xFFFFA07A);
  static const Color saturn = Color(0xFFF4A460);
  static const Color uranus = Color(0xFFAFEEEE);
  static const Color neptune = Color(0xFF4169E1);

  // Lines & Guides
  static const Color celestialEquator = Color(0xFF00BFFF);
  static const Color ecliptic = Color(0xFFFF6347);
  static const Color horizon = Color(0xFF32CD32);

  // UI
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  static Color getPlanetColor(String name) {
    switch (name.toLowerCase()) {
      case 'sun':
        return sun;
      case 'moon':
        return moon;
      case 'mercury':
        return mercury;
      case 'venus':
        return venus;
      case 'earth':
        return earth;
      case 'mars':
        return mars;
      case 'jupiter':
        return jupiter;
      case 'saturn':
        return saturn;
      case 'uranus':
        return uranus;
      case 'neptune':
        return neptune;
      default:
        return primary;
    }
  }
}
