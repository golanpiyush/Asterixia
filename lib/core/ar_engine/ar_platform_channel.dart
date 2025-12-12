// lib/core/ar_engine/ar_platform_channel.dart
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:typed_data';
import '../utils/logger.dart';

class ARPlatformChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.astronomy.ar/engine',
  );
  static const EventChannel _arEventChannel = EventChannel(
    'com.astronomy.ar/events',
  );

  static Stream<AREvent>? _arEventStream;
  static StreamSubscription? _eventSubscription;

  // Callbacks
  static Function(Map<String, dynamic>)? onSessionInitialized;
  static Function(String)? onError;
  static Function(double, double, double)? onCameraTransform;
  static Function(String nodeId, String name)? onCelestialBodyTapped;
  static Function(bool enabled, double intensity)? onNightModeChanged;

  /// Initialize AR session
  static Future<bool> initializeARSession({
    bool enablePlaneDetection = false,
    bool enableLightEstimation = true,
    bool enableAutoFocus = true,
  }) async {
    try {
      final result = await _channel.invokeMethod('initializeARSession', {
        'enablePlaneDetection': enablePlaneDetection,
        'enableLightEstimation': enableLightEstimation,
        'enableAutoFocus': enableAutoFocus,
      });

      Logger.ar('AR Session initialized: $result');
      return result as bool;
    } on PlatformException catch (e) {
      Logger.error('Failed to initialize AR session', error: e);
      onError?.call(e.message ?? 'Unknown error');
      return false;
    }
  }

  /// Start listening to AR events
  static void startListeningToEvents() {
    _arEventStream ??= _arEventChannel.receiveBroadcastStream().map(
      (dynamic event) => AREvent.fromMap(event as Map),
    );

    _eventSubscription = _arEventStream!.listen(
      (AREvent event) {
        _handleAREvent(event);
      },
      onError: (dynamic error) {
        Logger.error('AR Event stream error', error: error);
        onError?.call(error.toString());
      },
    );
  }

  static void _handleAREvent(AREvent event) {
    switch (event.type) {
      case AREventType.sessionInitialized:
        onSessionInitialized?.call(event.data);
        break;
      case AREventType.cameraTransform:
        final x = event.data['x'] as double;
        final y = event.data['y'] as double;
        final z = event.data['z'] as double;
        onCameraTransform?.call(x, y, z);
        break;
      case AREventType.celestialBodyTapped:
        final nodeId = event.data['id'] as String;
        final name = event.data['name'] as String;
        onCelestialBodyTapped?.call(nodeId, name);
        Logger.ar('Celestial body tapped: $name');
        break;
      case AREventType.nightModeChanged:
        final enabled = event.data['enabled'] as bool;
        final intensity = event.data['intensity'] as double;
        onNightModeChanged?.call(enabled, intensity);
        break;
      case AREventType.error:
        onError?.call(event.data['message'] as String);
        break;
    }
  }

  /// Add a celestial body node with distance-based scaling
  static Future<String?> addCelestialBody({
    required String name,
    required double x,
    required double y,
    required double z,
    required double scale,
    required int color,
    required String type, // 'sun', 'moon', 'planet', 'star'
    double glowIntensity = 0.5,
    double realDistance =
        0.0, // Distance from Earth (AU for planets, km for Moon)
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addCelestialBody', {
        'name': name,
        'x': x,
        'y': y,
        'z': z,
        'scale': scale,
        'color': color,
        'type': type,
        'glowIntensity': glowIntensity,
        'realDistance': realDistance,
      });

      Logger.ar(
        'Added celestial body: $name with ID: $nodeId (distance: $realDistance)',
      );
      return nodeId as String?;
    } on PlatformException catch (e) {
      Logger.error('Failed to add celestial body', error: e);
      return null;
    }
  }

  /// Add a constellation line
  static Future<String?> addConstellationLine({
    required String name,
    required List<Map<String, double>> points,
    required int color,
    double width = 0.005,
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addConstellationLine', {
        'name': name,
        'points': points,
        'color': color,
        'width': width,
      });

      Logger.ar('Added constellation line: $name');
      return nodeId as String?;
    } on PlatformException catch (e) {
      Logger.error('Failed to add constellation line', error: e);
      return null;
    }
  }

  /// Add a guide circle (horizon, celestial equator, ecliptic)
  static Future<String?> addGuideCircle({
    required String name,
    required double radius,
    required int color,
    required double thickness,
    double tilt = 0.0,
    double rotation = 0.0,
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addGuideCircle', {
        'name': name,
        'radius': radius,
        'color': color,
        'thickness': thickness,
        'tilt': tilt,
        'rotation': rotation,
      });

      Logger.ar('Added guide circle: $name');
      return nodeId as String?;
    } on PlatformException catch (e) {
      Logger.error('Failed to add guide circle', error: e);
      return null;
    }
  }

  /// Add an orbital path for planets
  static Future<String?> addOrbitalPath({
    required String planetName,
    required double centerX,
    required double centerY,
    required double centerZ,
    required double semiMajorAxis,
    required double semiMinorAxis,
    required double inclination,
    required int color,
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addOrbitalPath', {
        'planetName': planetName,
        'centerX': centerX,
        'centerY': centerY,
        'centerZ': centerZ,
        'semiMajorAxis': semiMajorAxis,
        'semiMinorAxis': semiMinorAxis,
        'inclination': inclination,
        'color': color,
      });

      Logger.ar('Added orbital path for: $planetName');
      return nodeId as String?;
    } on PlatformException catch (e) {
      Logger.error('Failed to add orbital path', error: e);
      return null;
    }
  }

  /// Add an axis line (rotation axis)
  static Future<String?> addAxisLine({
    required String name,
    required String bodyName,
    required double length,
    required double tilt,
    required int color,
    bool showRotation = false,
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addAxisLine', {
        'name': name,
        'bodyName': bodyName,
        'length': length,
        'tilt': tilt,
        'color': color,
        'showRotation': showRotation,
      });

      Logger.ar('Added axis line: $name');
      return nodeId as String?;
    } catch (e) {
      Logger.error('Failed to add axis line', error: e);
      return null;
    }
  }

  /// Add a text label
  static Future<String?> addTextLabel({
    required String text,
    required double x,
    required double y,
    required double z,
    required int color,
    double fontSize = 0.1,
    bool billboarding = true, // Always face camera
  }) async {
    try {
      final nodeId = await _channel.invokeMethod('addTextLabel', {
        'text': text,
        'x': x,
        'y': y,
        'z': z,
        'color': color,
        'fontSize': fontSize,
        'billboarding': billboarding,
      });

      Logger.ar('Added text label: $text');
      return nodeId as String?;
    } on PlatformException catch (e) {
      Logger.error('Failed to add text label', error: e);
      return null;
    }
  }

  /// Set night mode to dim camera and boost celestial glow
  static Future<void> setNightMode(
    bool enabled, {
    double intensity = 0.3,
  }) async {
    try {
      await _channel.invokeMethod('setNightMode', {
        'enabled': enabled,
        'intensity': intensity,
      });
      Logger.ar(
        'Night mode ${enabled ? "enabled" : "disabled"} (intensity: $intensity)',
      );
    } on PlatformException catch (e) {
      Logger.error('Failed to set night mode', error: e);
    }
  }

  /// Update node position
  static Future<bool> updateNodePosition({
    required String nodeId,
    required double x,
    required double y,
    required double z,
  }) async {
    try {
      final result = await _channel.invokeMethod('updateNodePosition', {
        'nodeId': nodeId,
        'x': x,
        'y': y,
        'z': z,
      });
      return result as bool;
    } on PlatformException catch (e) {
      Logger.error('Failed to update node position', error: e);
      return false;
    }
  }

  /// Remove a node
  static Future<bool> removeNode(String nodeId) async {
    try {
      final result = await _channel.invokeMethod('removeNode', {
        'nodeId': nodeId,
      });
      Logger.ar('Removed node: $nodeId');
      return result as bool;
    } on PlatformException catch (e) {
      Logger.error('Failed to remove node', error: e);
      return false;
    }
  }

  /// Clear all nodes
  static Future<bool> clearAllNodes() async {
    try {
      final result = await _channel.invokeMethod('clearAllNodes');
      Logger.ar('Cleared all nodes');
      return result as bool;
    } on PlatformException catch (e) {
      Logger.error('Failed to clear nodes', error: e);
      return false;
    }
  }

  /// Pause AR session
  static Future<void> pauseSession() async {
    try {
      await _channel.invokeMethod('pauseSession');
      Logger.ar('AR session paused');
    } on PlatformException catch (e) {
      Logger.error('Failed to pause AR session', error: e);
    }
  }

  /// Resume AR session
  static Future<void> resumeSession() async {
    try {
      await _channel.invokeMethod('resumeSession');
      Logger.ar('AR session resumed');
    } on PlatformException catch (e) {
      Logger.error('Failed to resume AR session', error: e);
    }
  }

  /// Take screenshot
  static Future<Uint8List?> takeScreenshot() async {
    try {
      final result = await _channel.invokeMethod('takeScreenshot');
      Logger.ar('Screenshot captured');
      return result as Uint8List?;
    } on PlatformException catch (e) {
      Logger.error('Failed to take screenshot', error: e);
      return null;
    }
  }

  /// Dispose resources
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}

// AR Event Types
enum AREventType {
  sessionInitialized,
  cameraTransform,
  celestialBodyTapped,
  nightModeChanged,
  error,
}

class AREvent {
  final AREventType type;
  final Map<String, dynamic> data;

  AREvent({required this.type, required this.data});

  factory AREvent.fromMap(Map<dynamic, dynamic> map) {
    final typeString = map['type'] as String;
    final type = AREventType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => AREventType.error,
    );

    return AREvent(
      type: type,
      data: Map<String, dynamic>.from(map['data'] as Map),
    );
  }
}
