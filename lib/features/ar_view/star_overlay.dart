// lib/features/ar_view/star_overlay.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/ar_engine/ar_platform_channel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/astronomy_service.dart';
import '../../core/services/ar_service.dart';
import '../../core/utils/logger.dart';
import '../settings/settings_controller.dart';

class StarOverlay {
  final double latitude;
  final double longitude;
  final SettingsController settingsController;

  final Map<String, String> _nodeIds = {};
  final List<String> _guideNodeIds = [];
  final List<String> _labelNodeIds = [];

  StarOverlay({
    required this.latitude,
    required this.longitude,
    required this.settingsController,
  });

  Future<void> updateOverlay(
    DateTime currentTime,
    double deviceAzimuth,
    double devicePitch,
  ) async {
    Logger.ar('Updating overlay for time: $currentTime');

    await _clearAllNodes();

    try {
      // Add celestial bodies based on settings
      if (settingsController.showSun) {
        await _addSun(currentTime);
      }

      if (settingsController.showMoon) {
        await _addMoon(currentTime);
      }

      if (settingsController.showPlanets) {
        await _addPlanets(currentTime);
      }

      // Add guide lines based on settings
      if (settingsController.showGuides) {
        await _createGuideLines(currentTime);
      }

      Logger.ar('Overlay update complete: ${_nodeIds.length} objects');
    } catch (e) {
      Logger.error('Error updating overlay', error: e);
    }
  }

  Future<void> _clearAllNodes() async {
    Logger.ar('Clearing all nodes...');
    await ARPlatformChannel.clearAllNodes();

    _nodeIds.clear();
    _guideNodeIds.clear();
    _labelNodeIds.clear();
  }

  Future<void> _addSun(DateTime currentTime) async {
    final pos = AstronomyService.getSunPosition(
      currentTime,
      latitude,
      longitude,
    );

    await _createCelestialBody(
      name: 'Sun',
      azimuth: pos['azimuth']!,
      altitude: pos['altitude']!,
      distance: 10.0,
      color: AppColors.sun,
      type: 'sun',
      glowIntensity: settingsController.brightnessLevel,
      showAxis: settingsController.showPlanetaryAxes,
      axisTilt: 7.25,
    );
  }

  Future<void> _addMoon(DateTime currentTime) async {
    final pos = AstronomyService.getMoonPosition(
      currentTime,
      latitude,
      longitude,
    );

    await _createCelestialBody(
      name: 'Moon',
      azimuth: pos['azimuth']!,
      altitude: pos['altitude']!,
      distance: 10.0,
      color: AppColors.moon,
      type: 'moon',
      glowIntensity: 0.3 * settingsController.brightnessLevel,
      showAxis: false,
      axisTilt: 6.7,
    );
  }

  Future<void> _addPlanets(DateTime currentTime) async {
    final planetPositions = AstronomyService.getPlanetPositions(
      currentTime,
      latitude,
      longitude,
    );

    for (final planet in planetPositions.entries) {
      final pos = planet.value;

      await _createCelestialBody(
        name: planet.key,
        azimuth: pos['azimuth']!,
        altitude: pos['altitude']!,
        distance: 10.0,
        color: AppColors.getPlanetColor(planet.key),
        type: 'planet',
        glowIntensity: 0.4 * settingsController.brightnessLevel,
        showAxis: settingsController.showPlanetaryAxes,
        axisTilt: _getPlanetAxisTilt(planet.key),
      );
    }
  }

  Future<void> _createCelestialBody({
    required String name,
    required double azimuth,
    required double altitude,
    required double distance,
    required Color color,
    required String type,
    required double glowIntensity,
    required bool showAxis,
    required double axisTilt,
  }) async {
    final v = ARService.calculateARPosition(azimuth, altitude, distance);

    final position = ARPosition(v.x, v.y, v.z);
    final scale = ARService.calculateScale(name, distance);

    Logger.ar('Creating $name at az=$azimuth alt=$altitude');

    final nodeId = await ARPlatformChannel.addCelestialBody(
      name: name,
      x: position.x,
      y: position.y,
      z: position.z,
      scale: scale,
      color: color.value,
      type: type,
      glowIntensity: glowIntensity,
    );

    if (nodeId != null) {
      _nodeIds[name] = nodeId;

      if (showAxis && settingsController.showPlanetaryAxes) {
        await _addAxis(
          bodyName: name,
          position: position,
          scale: scale,
          axisTilt: axisTilt,
        );
      }

      if (settingsController.showLabels) {
        await _addLabel(
          name: name,
          position: position,
          offset: scale * 1.5,
          distance: distance,
        );
      }
    }
  }

  Future<void> _addAxis({
    required String bodyName,
    required ARPosition position,
    required double scale,
    required double axisTilt,
  }) async {
    final axisId = await ARPlatformChannel.addAxisLine(
      name: '${bodyName}_axis',
      bodyName: bodyName,
      length: scale * 3.0 * settingsController.lineThickness,
      tilt: axisTilt,
      color: 0xFF00FFFF,
      showRotation: true,
    );

    if (axisId != null) _guideNodeIds.add(axisId);
  }

  Future<void> _addLabel({
    required String name,
    required ARPosition position,
    required double offset,
    required double distance,
  }) async {
    String labelText = name;

    // Add distance if enabled
    if (settingsController.showDistance) {
      labelText += '\n${distance.toStringAsFixed(1)} AU';
    }

    // Add magnitude if enabled (placeholder for now)
    if (settingsController.showMagnitude) {
      final magnitude = _getApproximateMagnitude(name);
      if (magnitude != null) {
        labelText += '\nMag: ${magnitude.toStringAsFixed(1)}';
      }
    }

    final labelId = await ARPlatformChannel.addTextLabel(
      text: labelText,
      x: position.x,
      y: position.y + offset,
      z: position.z,
      color: 0xFFFFFFFF,
      fontSize: 0.08 * settingsController.labelSize,
      billboarding: true,
    );

    if (labelId != null) _labelNodeIds.add(labelId);
  }

  Future<void> _createGuideLines(DateTime currentTime) async {
    Logger.ar('Creating guide lines...');

    // Celestial Equator
    if (settingsController.showCelestialEquator) {
      final equatorPoints = AstronomyService.getCelestialEquatorPoints(
        latitude,
        longitude,
        currentTime,
      );
      await _createLine(
        points: equatorPoints,
        color: AppColors.celestialEquator,
        label: AppStrings.celestialEquator,
        width: 0.008 * settingsController.lineThickness,
      );
    }

    // Ecliptic
    if (settingsController.showEcliptic) {
      final eclipticPoints = AstronomyService.getEclipticPoints(
        latitude,
        longitude,
        currentTime,
      );
      await _createLine(
        points: eclipticPoints,
        color: AppColors.ecliptic,
        label: AppStrings.eclipticLine,
        width: 0.008 * settingsController.lineThickness,
      );
    }

    // Horizon
    if (settingsController.showHorizon) {
      final horizonPoints = AstronomyService.getHorizonPoints();
      await _createLine(
        points: horizonPoints,
        color: AppColors.horizon,
        label: AppStrings.horizon,
        width: 0.01 * settingsController.lineThickness,
      );
    }

    // Constellation Lines (if you have constellation data)
    if (settingsController.showConstellationLines) {
      // Add constellation line rendering here if available
      Logger.ar('Constellation lines enabled but not yet implemented');
    }
  }

  Future<void> _createLine({
    required List<Map<String, double>> points,
    required Color color,
    required String label,
    required double width,
  }) async {
    if (points.length < 2) return;

    final arPoints = points.map((p) {
      final v = ARService.calculateARPosition(
        p['azimuth']!,
        p['altitude']!,
        10.0,
      );
      return {'x': v.x, 'y': v.y, 'z': v.z};
    }).toList();

    // Apply brightness level to color
    final adjustedColor = _adjustColorBrightness(
      color,
      settingsController.brightnessLevel,
    );

    final lineId = await ARPlatformChannel.addConstellationLine(
      name: label,
      points: arPoints,
      color: adjustedColor.value,
      width: width,
    );

    if (lineId != null) _guideNodeIds.add(lineId);

    if (settingsController.showLabels) {
      final mid = points[points.length ~/ 2];
      final v = ARService.calculateARPosition(
        mid['azimuth']!,
        mid['altitude']! + 5.0,
        10.0,
      );
      await ARPlatformChannel.addTextLabel(
        text: label,
        x: v.x,
        y: v.y,
        z: v.z,
        color: adjustedColor.value,
        fontSize: 0.06 * settingsController.labelSize,
        billboarding: true,
      );
    }
  }

  Color _adjustColorBrightness(Color color, double brightness) {
    if (settingsController.nightMode) {
      // Red tint for night mode
      return Color.fromARGB(
        color.alpha,
        (color.red * 0.7 * brightness).toInt().clamp(0, 255),
        (color.green * 0.2 * brightness).toInt().clamp(0, 255),
        (color.blue * 0.2 * brightness).toInt().clamp(0, 255),
      );
    }

    return Color.fromARGB(
      color.alpha,
      (color.red * brightness).toInt().clamp(0, 255),
      (color.green * brightness).toInt().clamp(0, 255),
      (color.blue * brightness).toInt().clamp(0, 255),
    );
  }

  double? _getApproximateMagnitude(String name) {
    const magnitudes = {
      'Sun': -26.7,
      'Moon': -12.6,
      'Venus': -4.6,
      'Jupiter': -2.9,
      'Mars': -2.0,
      'Mercury': -1.9,
      'Saturn': 0.4,
      'Uranus': 5.7,
      'Neptune': 7.8,
    };
    return magnitudes[name];
  }

  double _getPlanetAxisTilt(String name) {
    const tilts = {
      'Mercury': 0.034,
      'Venus': 177.4,
      'Earth': 23.5,
      'Mars': 25.2,
      'Jupiter': 3.1,
      'Saturn': 26.7,
      'Uranus': 97.8,
      'Neptune': 28.3,
    };
    return tilts[name] ?? 0.0;
  }

  void dispose() {
    _clearAllNodes();
  }
}

class ARPosition {
  final double x, y, z;
  ARPosition(this.x, this.y, this.z);

  @override
  String toString() => '($x, $y, $z)';
}
