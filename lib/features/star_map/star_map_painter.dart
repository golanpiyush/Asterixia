import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/astronomy_service.dart';

class StarMapPainter extends CustomPainter {
  final double latitude;
  final double longitude;
  final double azimuth;
  final double pitch;
  final DateTime currentTime;

  StarMapPainter({
    required this.latitude,
    required this.longitude,
    required this.azimuth,
    required this.pitch,
    DateTime? currentTime,
  }) : currentTime = currentTime ?? DateTime.now();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 20;

    // Draw horizon circle
    _drawHorizon(canvas, center, radius);

    // Draw celestial equator
    _drawCelestialEquator(canvas, center, radius);

    // Draw ecliptic
    _drawEcliptic(canvas, center, radius);

    // Draw celestial bodies
    _drawCelestialBodies(canvas, center, radius);

    // Draw compass directions
    _drawCompassDirections(canvas, center, radius);
  }

  void _drawHorizon(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.horizon.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);

    // Draw direction markers
    const directions = ['N', 'E', 'S', 'W'];
    const directionAngles = [0.0, 90.0, 180.0, 270.0];

    for (int i = 0; i < directions.length; i++) {
      final angle = directionAngles[i] * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawCelestialEquator(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.celestialEquator.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw celestial equator as a circle offset based on latitude
    final equatorOffset = radius * (latitude / 90.0);
    final equatorCenter = Offset(center.dx, center.dy + equatorOffset);

    canvas.drawCircle(equatorCenter, radius * 0.8, paint);
  }

  void _drawEcliptic(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.ecliptic.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw ecliptic as a wavy line
    final path = Path();
    const steps = 36;

    for (int i = 0; i <= steps; i++) {
      final angle = (i / steps) * 2 * pi;
      final offset = radius * 0.7 * sin(angle * 2) * 0.1; // Wavy effect
      final x = center.dx + (radius * 0.7 + offset) * cos(angle);
      final y = center.dy + (radius * 0.7 + offset) * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawCelestialBodies(Canvas canvas, Offset center, double radius) {
    // Get positions
    final sunPos = AstronomyService.getSunPosition(
      currentTime,
      latitude,
      longitude,
    );
    final moonPos = AstronomyService.getMoonPosition(
      currentTime,
      latitude,
      longitude,
    );
    final planetPositions = AstronomyService.getPlanetPositions(
      currentTime,
      latitude,
      longitude,
    );

    // Draw Sun
    _drawCelestialBody(
      canvas,
      center,
      radius,
      sunPos['azimuth']!,
      sunPos['altitude']!,
      AppColors.sun,
      'Sun',
      12,
    );

    // Draw Moon
    _drawCelestialBody(
      canvas,
      center,
      radius,
      moonPos['azimuth']!,
      moonPos['altitude']!,
      AppColors.moon,
      'Moon',
      10,
    );

    // Draw planets
    for (final planet in planetPositions.entries) {
      final pos = planet.value;
      _drawCelestialBody(
        canvas,
        center,
        radius,
        pos['azimuth']!,
        pos['altitude']!,
        AppColors.getPlanetColor(planet.key),
        planet.key,
        8,
      );
    }
  }

  void _drawCelestialBody(
    Canvas canvas,
    Offset center,
    double radius,
    double azimuth,
    double altitude,
    Color color,
    String label,
    double size,
  ) {
    // Convert altitude/azimuth to polar coordinates
    final angle = (azimuth - 90) * pi / 180; // Adjust for 0° = East
    final distance = radius * (1 - altitude / 90); // Map altitude to radius

    final x = center.dx + distance * cos(angle);
    final y = center.dy + distance * sin(angle);

    // Draw body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(x, y), size / 2, bodyPaint);

    // Draw glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(Offset(x, y), size, glowPaint);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + size));
  }

  void _drawCompassDirections(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw crosshair
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      paint,
    );

    // Draw current direction indicator
    final currentAngle = (azimuth - 90) * pi / 180;
    final indicatorPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final indicatorX = center.dx + radius * cos(currentAngle);
    final indicatorY = center.dy + radius * sin(currentAngle);

    canvas.drawCircle(Offset(indicatorX, indicatorY), 6, indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
