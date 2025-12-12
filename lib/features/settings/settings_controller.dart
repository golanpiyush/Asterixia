import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/services/data_loader.dart';
import '../../core/utils/logger.dart';

class SettingsController {
  final StreamController<Map<String, dynamic>> _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic> _currentSettings = {};

  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

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
    Logger.info('Settings reset to defaults');
  }

  Map<String, dynamic> _getDefaultSettings() {
    return {
      'showLabels': true,
      'showGuides': true,
      'autoLocation': true,
      'arQuality': 'medium',
    };
  }

  void dispose() {
    _settingsController.close();
  }
}
