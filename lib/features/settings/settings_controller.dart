// lib/features/settings/settings_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/data_loader.dart';
import '../../core/utils/logger.dart';

class SettingsController {
  final StreamController<Map<String, dynamic>> _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic> _currentSettings = {};

  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  // Getters for individual settings
  bool get showLabels => _currentSettings['showLabels'] ?? true;
  bool get showGuides => _currentSettings['showGuides'] ?? true;
  bool get showConstellationLines =>
      _currentSettings['showConstellationLines'] ?? true;
  bool get showPlanets => _currentSettings['showPlanets'] ?? true;
  bool get showSun => _currentSettings['showSun'] ?? true;
  bool get showMoon => _currentSettings['showMoon'] ?? true;
  bool get showStars => _currentSettings['showStars'] ?? true;
  bool get showOrbits => _currentSettings['showOrbits'] ?? false;
  bool get showHorizon => _currentSettings['showHorizon'] ?? true;
  bool get showEcliptic => _currentSettings['showEcliptic'] ?? true;
  bool get showCelestialEquator =>
      _currentSettings['showCelestialEquator'] ?? true;
  bool get showPlanetaryAxes => _currentSettings['showPlanetaryAxes'] ?? false;
  bool get autoLocation => _currentSettings['autoLocation'] ?? true;
  bool get nightMode => _currentSettings['nightMode'] ?? false;
  bool get showDistance => _currentSettings['showDistance'] ?? true;
  bool get showMagnitude => _currentSettings['showMagnitude'] ?? false;
  String get arQuality => _currentSettings['arQuality'] ?? 'medium';
  double get brightnessLevel => _currentSettings['brightnessLevel'] ?? 1.0;
  double get labelSize => _currentSettings['labelSize'] ?? 1.0;
  double get lineThickness => _currentSettings['lineThickness'] ?? 1.0;

  Future<void> loadSettings() async {
    try {
      final settings = await DataLoader.loadSettings();
      _currentSettings = settings;
      _settingsController.add(settings);
      Logger.info('Settings loaded: $settings');
    } catch (e) {
      Logger.error('Failed to load settings', error: e);
      // Load default settings
      _currentSettings = _getDefaultSettings();
      _settingsController.add(_currentSettings);
    }
  }

  void updateSetting(String key, dynamic value) {
    _currentSettings[key] = value;
    _settingsController.add(Map.from(_currentSettings));
    Logger.info('Setting updated: $key = $value');

    // Auto-save settings after update
    saveSettings();
  }

  Future<void> saveSettings() async {
    try {
      await DataLoader.saveSettings(_currentSettings);
      Logger.info('Settings saved');
    } catch (e) {
      Logger.error('Failed to save settings', error: e);
    }
  }

  void resetSettings() {
    _currentSettings = _getDefaultSettings();
    _settingsController.add(_currentSettings);
    saveSettings();
    Logger.info('Settings reset to defaults');
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      // Display Settings
      'showLabels': true,
      'showGuides': true,
      'showConstellationLines': true,
      'showDistance': true,
      'showMagnitude': false,

      // Celestial Objects
      'showPlanets': true,
      'showSun': true,
      'showMoon': true,
      'showStars': true,
      'showOrbits': false,

      // Guide Lines
      'showHorizon': true,
      'showEcliptic': true,
      'showCelestialEquator': true,
      'showPlanetaryAxes': false,

      // Location & Appearance
      'autoLocation': true,
      'nightMode': false,
      'arQuality': 'medium', // 'low', 'medium', 'high'
      // Visual Adjustments
      'brightnessLevel': 1.0, // 0.0 to 2.0
      'labelSize': 1.0, // 0.5 to 2.0
      'lineThickness': 1.0, // 0.5 to 2.0
    };
  }

  /// Bulk update multiple settings at once
  void updateMultipleSettings(Map<String, dynamic> updates) {
    _currentSettings.addAll(updates);
    _settingsController.add(Map.from(_currentSettings));
    Logger.info('Multiple settings updated: ${updates.keys.join(", ")}');
    saveSettings();
  }

  /// Toggle a boolean setting
  void toggleSetting(String key) {
    if (_currentSettings[key] is bool) {
      _currentSettings[key] = !(_currentSettings[key] as bool);
      _settingsController.add(Map.from(_currentSettings));
      Logger.info('Setting toggled: $key = ${_currentSettings[key]}');
      saveSettings();
    }
  }

  /// Get current settings as map
  Map<String, dynamic> getCurrentSettings() {
    return Map.from(_currentSettings);
  }

  /// Check if a specific object type should be shown
  bool shouldShow(String objectType) {
    switch (objectType.toLowerCase()) {
      case 'planet':
        return showPlanets;
      case 'sun':
        return showSun;
      case 'moon':
        return showMoon;
      case 'star':
        return showStars;
      case 'constellation':
        return showConstellationLines;
      case 'orbit':
        return showOrbits;
      case 'horizon':
        return showHorizon;
      case 'ecliptic':
        return showEcliptic;
      case 'celestialequator':
        return showCelestialEquator;
      case 'axis':
        return showPlanetaryAxes;
      default:
        return true;
    }
  }

  void dispose() {
    _settingsController.close();
  }
}

/// Settings categories for organized UI
enum SettingCategory {
  display,
  celestialObjects,
  guideLines,
  appearance,
  advanced,
}

/// Setting item model for building UI
class SettingItem {
  final String key;
  final String title;
  final String description;
  final SettingType type;
  final SettingCategory category;
  final dynamic defaultValue;
  final dynamic minValue;
  final dynamic maxValue;
  final List<String>? options;

  const SettingItem({
    required this.key,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.defaultValue,
    this.minValue,
    this.maxValue,
    this.options,
  });
}

enum SettingType { toggle, slider, dropdown }

/// Available settings configuration
class SettingsConfig {
  static final List<SettingItem> allSettings = [
    // Display Settings
    SettingItem(
      key: 'showLabels',
      title: 'Show Labels',
      description: 'Display names of celestial objects',
      type: SettingType.toggle,
      category: SettingCategory.display,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showDistance',
      title: 'Show Distance',
      description: 'Display distance information in labels',
      type: SettingType.toggle,
      category: SettingCategory.display,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showMagnitude',
      title: 'Show Magnitude',
      description: 'Display brightness magnitude of objects',
      type: SettingType.toggle,
      category: SettingCategory.display,
      defaultValue: false,
    ),

    // Celestial Objects
    SettingItem(
      key: 'showPlanets',
      title: 'Show Planets',
      description: 'Display planets in AR view',
      type: SettingType.toggle,
      category: SettingCategory.celestialObjects,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showSun',
      title: 'Show Sun',
      description: 'Display the Sun',
      type: SettingType.toggle,
      category: SettingCategory.celestialObjects,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showMoon',
      title: 'Show Moon',
      description: 'Display the Moon',
      type: SettingType.toggle,
      category: SettingCategory.celestialObjects,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showStars',
      title: 'Show Stars',
      description: 'Display stars in AR view',
      type: SettingType.toggle,
      category: SettingCategory.celestialObjects,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showOrbits',
      title: 'Show Orbital Paths',
      description: 'Display planetary orbits',
      type: SettingType.toggle,
      category: SettingCategory.celestialObjects,
      defaultValue: false,
    ),

    // Guide Lines
    SettingItem(
      key: 'showGuides',
      title: 'Show All Guides',
      description: 'Display all guide lines',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showConstellationLines',
      title: 'Constellation Lines',
      description: 'Connect stars to form constellations',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showHorizon',
      title: 'Show Horizon',
      description: 'Display horizon line',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showEcliptic',
      title: 'Show Ecliptic',
      description: 'Display ecliptic plane (Sun\'s path)',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showCelestialEquator',
      title: 'Celestial Equator',
      description: 'Display celestial equator line',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: true,
    ),
    SettingItem(
      key: 'showPlanetaryAxes',
      title: 'Planetary Axes',
      description: 'Show rotation axes of planets',
      type: SettingType.toggle,
      category: SettingCategory.guideLines,
      defaultValue: false,
    ),

    // Appearance
    SettingItem(
      key: 'nightMode',
      title: 'Night Mode',
      description: 'Reduce brightness for night observation',
      type: SettingType.toggle,
      category: SettingCategory.appearance,
      defaultValue: false,
    ),
    SettingItem(
      key: 'brightnessLevel',
      title: 'Brightness',
      description: 'Adjust overall brightness',
      type: SettingType.slider,
      category: SettingCategory.appearance,
      defaultValue: 1.0,
      minValue: 0.3,
      maxValue: 2.0,
    ),
    SettingItem(
      key: 'labelSize',
      title: 'Label Size',
      description: 'Adjust label text size',
      type: SettingType.slider,
      category: SettingCategory.appearance,
      defaultValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
    ),
    SettingItem(
      key: 'lineThickness',
      title: 'Line Thickness',
      description: 'Adjust guide line thickness',
      type: SettingType.slider,
      category: SettingCategory.appearance,
      defaultValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
    ),

    // Advanced
    SettingItem(
      key: 'arQuality',
      title: 'AR Quality',
      description: 'Adjust rendering quality',
      type: SettingType.dropdown,
      category: SettingCategory.advanced,
      defaultValue: 'medium',
      options: ['low', 'medium', 'high'],
    ),
    SettingItem(
      key: 'autoLocation',
      title: 'Auto Location',
      description: 'Automatically use device location',
      type: SettingType.toggle,
      category: SettingCategory.advanced,
      defaultValue: true,
    ),
  ];

  /// Get settings by category
  static List<SettingItem> getSettingsByCategory(SettingCategory category) {
    return allSettings.where((s) => s.category == category).toList();
  }
}
