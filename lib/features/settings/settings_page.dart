import 'package:asterixia/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_controller.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/custom_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController();
    _controller.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _controller.settingsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionHeader('AR Settings'),
              _buildSwitchTile(
                title: AppStrings.toggleGuides,
                value: settings['showGuides'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showGuides', value),
              ),
              _buildSwitchTile(
                title: AppStrings.showLabels,
                value: settings['showLabels'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showLabels', value),
              ),
              _buildSwitchTile(
                title: AppStrings.autoDetectLocation,
                value: settings['autoLocation'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('autoLocation', value),
              ),

              _buildSectionHeader('AR Quality'),
              _buildQualitySlider(settings),

              _buildSectionHeader('Location'),
              _buildLocationCard(context),

              _buildSectionHeader('About'),
              _buildAboutCard(),

              const SizedBox(height: 24),
              CustomButton(
                text: 'Save Settings',
                onPressed: _controller.saveSettings,
                backgroundColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Reset to Defaults',
                onPressed: _controller.resetSettings,
                backgroundColor: Colors.grey,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: Colors.grey[900],
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildQualitySlider(Map<String, dynamic> settings) {
    final quality = settings['arQuality'] ?? 'medium';
    final qualityMap = {'low': 0, 'medium': 1, 'high': 2};
    final currentValue = qualityMap[quality] ?? 1;

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AR Quality Level',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Slider(
              value: currentValue.toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              label: quality,
              onChanged: (value) {
                final newQuality = ['low', 'medium', 'high'][value.toInt()];
                _controller.updateSetting('arQuality', newQuality);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Low', style: TextStyle(color: Colors.grey)),
                Text('Medium', style: TextStyle(color: Colors.grey)),
                Text('High', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (locationService.hasLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latitude: ${locationService.latitude.toStringAsFixed(4)}°',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Longitude: ${locationService.longitude.toStringAsFixed(4)}°',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Altitude: ${locationService.altitude.toStringAsFixed(0)}m',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              )
            else
              const Text(
                'Location not available',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Refresh Location',
              onPressed: locationService.initialize,
              backgroundColor: Colors.blue,
              isLoading: locationService.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Asterixia v1.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AR Astronomy App',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track and visualize celestial bodies in augmented reality. '
              'View the Sun, Moon, and planets in real-time based on your location.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Features:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            _buildFeatureItem('• Real-time AR tracking of celestial bodies'),
            _buildFeatureItem('• Sensor fusion for accurate positioning'),
            _buildFeatureItem(
              '• Celestial guide lines (equator, ecliptic, horizon)',
            ),
            _buildFeatureItem('• Interactive star map'),
            _buildFeatureItem('• Astronomy calculations in pure Dart'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}
