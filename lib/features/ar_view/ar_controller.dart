// lib/features/ar_view/ar_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/location_service.dart';
import '../../core/services/sensor_service.dart';
import '../../core/ar_engine/ar_platform_channel.dart';
import '../settings/settings_controller.dart';
import 'star_overlay.dart';
import '../../core/utils/logger.dart';

class ARController {
  final LocationService locationService;
  final SensorService sensorService;
  final SettingsController settingsController;

  late StarOverlay _starOverlay;
  late Timer _updateTimer;
  StreamSubscription<Map<String, dynamic>>? _settingsSubscription;

  bool _isInitialized = false;
  bool _isARSessionReady = false;

  ARController({
    required this.locationService,
    required this.sensorService,
    required this.settingsController,
  });

  /// Initialize the AR controller and session
  Future<void> initialize() async {
    if (_isInitialized) return;

    Logger.ar('Initializing AR Controller...');

    // Setup AR event callbacks
    _setupARCallbacks();

    // Listen to settings changes
    _setupSettingsListener();

    // Get AR quality from settings
    final arQuality = settingsController.arQuality;
    final enableLightEstimation = arQuality != 'low';
    final enableAutoFocus = arQuality == 'high';

    // Initialize AR session
    final success = await ARPlatformChannel.initializeARSession(
      enablePlaneDetection:
          false, // We don't need plane detection for astronomy
      enableLightEstimation: enableLightEstimation,
      enableAutoFocus: enableAutoFocus,
    );

    if (!success) {
      Logger.error('Failed to initialize AR session');
      return;
    }

    _isInitialized = true;
    Logger.ar('AR Controller initialized with quality: $arQuality');
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

    // Listen for celestial body tap events
    ARPlatformChannel.onCelestialBodyTapped = (nodeId, name) {
      Logger.ar('Celestial body tapped: $name (ID: $nodeId)');
      _handleCelestialBodyTapped(nodeId, name);
    };

    // Listen for night mode changes
    ARPlatformChannel.onNightModeChanged = (enabled, intensity) {
      Logger.ar('Night mode changed: $enabled (intensity: $intensity)');
    };

    // Start listening to events
    ARPlatformChannel.startListeningToEvents();
  }

  void _setupSettingsListener() {
    // Listen to settings changes and update the overlay
    _settingsSubscription = settingsController.settingsStream.listen((
      settings,
    ) {
      if (_isARSessionReady) {
        Logger.ar('Settings changed, updating overlay...');
        _updateOverlay();

        // Update night mode in native AR
        if (settings['nightMode'] == true) {
          ARPlatformChannel.setNightMode(
            true,
            intensity: 1.0 - (settings['brightnessLevel'] ?? 1.0),
          );
        } else {
          ARPlatformChannel.setNightMode(false, intensity: 0.0);
        }
      }
    });
  }

  void _onARSessionReady() {
    Logger.ar('AR Session is ready');

    // Initialize star overlay with settings controller
    _starOverlay = StarOverlay(
      latitude: locationService.latitude,
      longitude: locationService.longitude,
      settingsController: settingsController,
    );

    // Apply initial night mode setting
    if (settingsController.nightMode) {
      ARPlatformChannel.setNightMode(
        true,
        intensity: 1.0 - settingsController.brightnessLevel,
      );
    }

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

  void _handleCelestialBodyTapped(String nodeId, String name) {
    // Handle celestial body tap events
    // This is now handled in ar_view_page.dart via the callback
    Logger.ar('User tapped on: $name (Node ID: $nodeId)');
  }

  /// Update location and refresh overlay
  void updateLocation(double latitude, double longitude) {
    if (!_isARSessionReady) return;

    Logger.ar('Updating location: ($latitude, $longitude)');

    // Recreate star overlay with new location
    _starOverlay = StarOverlay(
      latitude: latitude,
      longitude: longitude,
      settingsController: settingsController,
    );

    _updateOverlay();
  }

  /// Toggle guide lines (horizon, ecliptic, celestial equator)
  void toggleGuides(bool show) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling guides: $show');
    settingsController.updateSetting('showGuides', show);
  }

  /// Toggle labels on celestial bodies
  void toggleLabels(bool show) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling labels: $show');
    settingsController.updateSetting('showLabels', show);
  }

  /// Toggle specific celestial object visibility
  void toggleCelestialObject(String objectType, bool show) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling $objectType: $show');

    switch (objectType.toLowerCase()) {
      case 'planets':
        settingsController.updateSetting('showPlanets', show);
        break;
      case 'sun':
        settingsController.updateSetting('showSun', show);
        break;
      case 'moon':
        settingsController.updateSetting('showMoon', show);
        break;
      case 'stars':
        settingsController.updateSetting('showStars', show);
        break;
      case 'constellations':
        settingsController.updateSetting('showConstellationLines', show);
        break;
      case 'orbits':
        settingsController.updateSetting('showOrbits', show);
        break;
    }
  }

  /// Set AR quality (low, medium, high)
  Future<void> setARQuality(String quality) async {
    if (!_isARSessionReady) return;

    Logger.ar('Setting AR quality: $quality');
    settingsController.updateSetting('arQuality', quality);

    // Restart AR session with new quality settings
    await pause();
    ARPlatformChannel.dispose();
    _isARSessionReady = false;
    await initialize();
  }

  /// Toggle night mode
  void toggleNightMode(bool enabled) {
    if (!_isARSessionReady) return;

    Logger.ar('Toggling night mode: $enabled');
    settingsController.updateSetting('nightMode', enabled);

    // Update native AR night mode
    ARPlatformChannel.setNightMode(
      enabled,
      intensity: enabled ? (1.0 - settingsController.brightnessLevel) : 0.0,
    );
  }

  /// Set brightness level (0.3 - 2.0)
  void setBrightness(double level) {
    if (!_isARSessionReady) return;

    Logger.ar('Setting brightness: $level');
    settingsController.updateSetting('brightnessLevel', level);

    // Update night mode intensity if enabled
    if (settingsController.nightMode) {
      ARPlatformChannel.setNightMode(true, intensity: 1.0 - level);
    }
  }

  /// Set label size (0.5 - 2.0)
  void setLabelSize(double size) {
    if (!_isARSessionReady) return;

    Logger.ar('Setting label size: $size');
    settingsController.updateSetting('labelSize', size);
  }

  /// Set line thickness (0.5 - 2.0)
  void setLineThickness(double thickness) {
    if (!_isARSessionReady) return;

    Logger.ar('Setting line thickness: $thickness');
    settingsController.updateSetting('lineThickness', thickness);
  }

  /// Force refresh the AR scene
  Future<void> refresh() async {
    Logger.ar('Refreshing AR scene');

    // Clear all existing nodes
    await ARPlatformChannel.clearAllNodes();

    // Recreate star overlay with current settings
    _starOverlay = StarOverlay(
      latitude: locationService.latitude,
      longitude: locationService.longitude,
      settingsController: settingsController,
    );

    // Update overlay
    await _updateOverlay();
  }

  /// Pause AR session (e.g., when app goes to background)
  Future<void> pause() async {
    if (!_isARSessionReady) return;

    Logger.ar('Pausing AR session');

    if (_updateTimer.isActive) {
      _updateTimer.cancel();
    }

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

  /// Get current AR statistics
  Map<String, dynamic> getARStats() {
    return {
      'isInitialized': _isInitialized,
      'isSessionReady': _isARSessionReady,
      'hasLocation': locationService.hasLocation,
      'latitude': locationService.latitude,
      'longitude': locationService.longitude,
      'azimuth': sensorService.azimuth,
      'pitch': sensorService.pitch,
      'roll': sensorService.roll,
      'arQuality': settingsController.arQuality,
      'nightMode': settingsController.nightMode,
      'brightness': settingsController.brightnessLevel,
    };
  }

  /// Clean up resources
  void dispose() {
    Logger.ar('Disposing AR Controller');

    _settingsSubscription?.cancel();

    if (_updateTimer.isActive) {
      _updateTimer.cancel();
    }

    _starOverlay.dispose();
    ARPlatformChannel.dispose();

    _isInitialized = false;
    _isARSessionReady = false;
  }
}
