// lib/features/ar_view/ar_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import '../../core/services/sensor_service.dart';
import '../../core/ar_engine/ar_platform_channel.dart';
import 'star_overlay.dart';
import '../../core/utils/logger.dart';

class ARController {
  final LocationService locationService;
  final SensorService sensorService;

  late StarOverlay _starOverlay;
  late Timer _updateTimer;

  bool _isInitialized = false;
  bool _isARSessionReady = false;

  // Current settings
  bool _showGuides = true;
  bool _showLabels = true;

  ARController({required this.locationService, required this.sensorService});

  /// Initialize the AR controller and session
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.ar('Initializing AR Controller...');

    // Setup AR event callbacks
    _setupARCallbacks();

    // Initialize AR session
    final success = await ARPlatformChannel.initializeARSession(
      enablePlaneDetection:
          false, // We don't need plane detection for astronomy
      enableLightEstimation: true,
      enableAutoFocus: true,
    );

    if (!success) {
      Logger.error('Failed to initialize AR session');
      return;
    }

    _isInitialized = true;
    Logger.ar('AR Controller initialized');
  }

  void _setupARCallbacks() {
    // Listen for AR session initialization
    ARPlatformChannel.onSessionInitialized = (data) {
      Logger.ar('AR Session initialized: $data');
      _isARSessionReady = true;
      _onARSessionReady();
    };

    // Listen for errors
    ARPlatformChannel.onError = (message) {
      Logger.error('AR Error: $message');
    };

    // Listen for camera transform updates
    ARPlatformChannel.onCameraTransform = (x, y, z) {
      // Can be used for debugging or UI updates
      // Logger.ar('Camera position: ($x, $y, $z)');
    };

    // Listen for node tap events
    ARPlatformChannel.onNodeTapped = (data) {
      final nodeName = data['nodeName'] as String?;
      if (nodeName != null) {
        Logger.ar('Node tapped: $nodeName');
        _handleNodeTapped(nodeName);
      }
    };

    // Start listening to events
    ARPlatformChannel.startListeningToEvents();
  }

  void _onARSessionReady() {
    Logger.ar('AR Session is ready');

    // Initialize star overlay
    _starOverlay = StarOverlay(
      latitude: locationService.latitude,
      longitude: locationService.longitude,
      showGuides: _showGuides,
      showLabels: _showLabels,
    );

    // Update the overlay immediately
    _updateOverlay();

    // Start periodic updates
    _startUpdateTimer();
  }

  void _startUpdateTimer() {
    // Update overlay every 2 seconds for smooth tracking
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _updateOverlay();
    });

    Logger.ar('Update timer started');
  }

  Future<void> _updateOverlay() async {
    if (!_isARSessionReady) {
      Logger.ar('AR session not ready yet');
      return;
    }

    if (!locationService.hasLocation) {
      Logger.ar('Location not available');
      return;
    }

    try {
      Logger.ar('Updating overlay...');
      await _starOverlay.updateOverlay(
        DateTime.now(),
        sensorService.azimuth,
        sensorService.pitch,
      );
      Logger.ar('Overlay updated successfully');
    } catch (e) {
      Logger.error('Failed to update overlay', error: e);
    }
  }

  void _handleNodeTapped(String nodeName) {
    // Handle celestial body tap events
    // You can show info dialogs or update UI based on the tapped object
    Logger.ar('User tapped on: $nodeName');
  }

  /// Update location and refresh overlay
  void updateLocation(double latitude, double longitude) {
    if (!_isARSessionReady) return;

    Logger.ar('Updating location: ($latitude, $longitude)');

    // Recreate star overlay with new location
    _starOverlay = StarOverlay(
      latitude: latitude,
      longitude: longitude,
      showGuides: _showGuides,
      showLabels: _showLabels,
    );

    _updateOverlay();
  }

  /// Toggle guide lines (horizon, ecliptic, celestial equator)
  void toggleGuides(bool show) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling guides: $show');
    _showGuides = show;

    // Recreate overlay with new settings
    _starOverlay = StarOverlay(
      latitude: locationService.latitude,
      longitude: locationService.longitude,
      showGuides: show,
      showLabels: _showLabels,
    );

    _updateOverlay();
  }

  /// Toggle labels on celestial bodies
  void toggleLabels(bool show) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling labels: $show');
    _showLabels = show;

    // Recreate overlay with new settings
    _starOverlay = StarOverlay(
      latitude: locationService.latitude,
      longitude: locationService.longitude,
      showGuides: _showGuides,
      showLabels: show,
    );

    _updateOverlay();
  }

  /// Force refresh the AR scene
  Future<void> refresh() async {
    Logger.ar('Refreshing AR scene');

    // Clear all existing nodes
    await ARPlatformChannel.clearAllNodes();

    // Update overlay
    await _updateOverlay();
  }

  /// Pause AR session (e.g., when app goes to background)
  Future<void> pause() async {
    if (!_isARSessionReady) return;

    Logger.ar('Pausing AR session');
    _updateTimer.cancel();
    await ARPlatformChannel.pauseSession();
  }

  /// Resume AR session (e.g., when app comes back to foreground)
  Future<void> resume() async {
    if (!_isARSessionReady) return;

    Logger.ar('Resuming AR session');
    await ARPlatformChannel.resumeSession();
    _startUpdateTimer();
    _updateOverlay();
  }

  /// Clean up resources
  void dispose() {
    Logger.ar('Disposing AR Controller');

    if (_updateTimer.isActive) {
      _updateTimer.cancel();
    }

    ARPlatformChannel.dispose();
    _isInitialized = false;
    _isARSessionReady = false;
  }
}
