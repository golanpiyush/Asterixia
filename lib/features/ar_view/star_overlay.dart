// lib/features/ar_view/star_overlay.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/ar_engine/ar_platform_channel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/astronomy_service.dart';
import '../../core/services/ar_service.dart';
import '../../core/utils/logger.dart';

class StarOverlay {
  final double latitude;
  final double longitude;
  final bool showGuides;
  final bool showLabels;

  final Map<String, String> _nodeIds = {};
  final List<String> _guideNodeIds = [];
  final List<String> _labelNodeIds = [];

  StarOverlay({
    required this.latitude,
    required this.longitude,
    this.showGuides = true,
    this.showLabels = true,
  });

  Future<void> updateOverlay(
    DateTime currentTime,
    double deviceAzimuth,
    double devicePitch,
  ) async {
    Logger.ar('Updating overlay for time: $currentTime');

    await _clearAllNodes();

    try {
      await _addSun(currentTime);
      await _addMoon(currentTime);
      await _addPlanets(currentTime);

      if (showGuides) {
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
      glowIntensity: 1.0,
      showAxis: true,
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
      glowIntensity: 0.3,
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
        glowIntensity: 0.4,
        showAxis: true,
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

      if (showAxis) {
        await _addAxis(
          bodyName: name,
          position: position,
          scale: scale,
          axisTilt: axisTilt,
        );
      }

      if (showLabels) {
        await _addLabel(name: name, position: position, offset: scale * 1.5);
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
      length: scale * 3.0,
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
  }) async {
    final labelId = await ARPlatformChannel.addTextLabel(
      text: name,
      x: position.x,
      y: position.y + offset,
      z: position.z,
      color: 0xFFFFFFFF,
      fontSize: 0.08,
      billboarding: true,
    );

    if (labelId != null) _labelNodeIds.add(labelId);
  }

  Future<void> _createGuideLines(DateTime currentTime) async {
    Logger.ar('Creating guide lines...');

    final equatorPoints = AstronomyService.getCelestialEquatorPoints(
      latitude,
      longitude,
      currentTime,
    );
    await _createLine(
      points: equatorPoints,
      color: AppColors.celestialEquator,
      label: AppStrings.celestialEquator,
      width: 0.008,
    );

    final eclipticPoints = AstronomyService.getEclipticPoints(
      latitude,
      longitude,
      currentTime,
    );
    await _createLine(
      points: eclipticPoints,
      color: AppColors.ecliptic,
      label: AppStrings.eclipticLine,
      width: 0.008,
    );

    final horizonPoints = AstronomyService.getHorizonPoints();
    await _createLine(
      points: horizonPoints,
      color: AppColors.horizon,
      label: AppStrings.horizon,
      width: 0.01,
    );
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

    final lineId = await ARPlatformChannel.addConstellationLine(
      name: label,
      points: arPoints,
      color: color.value,
      width: width,
    );

    if (lineId != null) _guideNodeIds.add(lineId);

    if (showLabels) {
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
        color: color.value,
        fontSize: 0.06,
        billboarding: true,
      );
    }
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
