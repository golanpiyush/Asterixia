import 'package:asterixia/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.settings,
          style: GoogleFonts.cabin(fontWeight: FontWeight.w600),
        ),
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
              // Display Settings
              _buildSectionHeader('Display Settings'),
              _buildSwitchTile(
                title: 'Show Labels',
                subtitle: 'Display names of celestial objects',
                value: settings['showLabels'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showLabels', value),
              ),
              _buildSwitchTile(
                title: 'Show Distance',
                subtitle: 'Display distance information in labels',
                value: settings['showDistance'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showDistance', value),
              ),
              _buildSwitchTile(
                title: 'Show Magnitude',
                subtitle: 'Display brightness magnitude of objects',
                value: settings['showMagnitude'] ?? false,
                onChanged: (value) =>
                    _controller.updateSetting('showMagnitude', value),
              ),

              // Celestial Objects
              _buildSectionHeader('Celestial Objects'),
              _buildSwitchTile(
                title: 'Show Planets',
                subtitle: 'Display planets in AR view',
                value: settings['showPlanets'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showPlanets', value),
              ),
              _buildSwitchTile(
                title: 'Show Sun',
                subtitle: 'Display the Sun',
                value: settings['showSun'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showSun', value),
              ),
              _buildSwitchTile(
                title: 'Show Moon',
                subtitle: 'Display the Moon',
                value: settings['showMoon'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showMoon', value),
              ),
              _buildSwitchTile(
                title: 'Show Stars',
                subtitle: 'Display stars in AR view',
                value: settings['showStars'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showStars', value),
              ),
              _buildSwitchTile(
                title: 'Show Orbital Paths',
                subtitle: 'Display planetary orbits',
                value: settings['showOrbits'] ?? false,
                onChanged: (value) =>
                    _controller.updateSetting('showOrbits', value),
              ),

              // Guide Lines
              _buildSectionHeader('Guide Lines'),
              _buildSwitchTile(
                title: 'Show All Guides',
                subtitle: 'Display all guide lines',
                value: settings['showGuides'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showGuides', value),
              ),
              _buildSwitchTile(
                title: 'Constellation Lines',
                subtitle: 'Connect stars to form constellations',
                value: settings['showConstellationLines'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showConstellationLines', value),
              ),
              _buildSwitchTile(
                title: 'Show Horizon',
                subtitle: 'Display horizon line',
                value: settings['showHorizon'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showHorizon', value),
              ),
              _buildSwitchTile(
                title: 'Show Ecliptic',
                subtitle: 'Display ecliptic plane (Sun\'s path)',
                value: settings['showEcliptic'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showEcliptic', value),
              ),
              _buildSwitchTile(
                title: 'Celestial Equator',
                subtitle: 'Display celestial equator line',
                value: settings['showCelestialEquator'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('showCelestialEquator', value),
              ),
              _buildSwitchTile(
                title: 'Planetary Axes',
                subtitle: 'Show rotation axes of planets',
                value: settings['showPlanetaryAxes'] ?? false,
                onChanged: (value) =>
                    _controller.updateSetting('showPlanetaryAxes', value),
              ),

              // Appearance
              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                title: 'Night Mode',
                subtitle: 'Reduce brightness for night observation',
                value: settings['nightMode'] ?? false,
                onChanged: (value) =>
                    _controller.updateSetting('nightMode', value),
              ),
              _buildSliderTile(
                title: 'Brightness',
                subtitle: 'Adjust overall brightness',
                value: settings['brightnessLevel'] ?? 1.0,
                min: 0.3,
                max: 2.0,
                divisions: 17,
                onChanged: (value) =>
                    _controller.updateSetting('brightnessLevel', value),
              ),
              _buildSliderTile(
                title: 'Label Size',
                subtitle: 'Adjust label text size',
                value: settings['labelSize'] ?? 1.0,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) =>
                    _controller.updateSetting('labelSize', value),
              ),
              _buildSliderTile(
                title: 'Line Thickness',
                subtitle: 'Adjust guide line thickness',
                value: settings['lineThickness'] ?? 1.0,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) =>
                    _controller.updateSetting('lineThickness', value),
              ),

              // Advanced Settings
              _buildSectionHeader('Advanced'),
              _buildQualityDropdown(settings),
              _buildSwitchTile(
                title: AppStrings.autoDetectLocation,
                subtitle: 'Automatically use device location',
                value: settings['autoLocation'] ?? true,
                onChanged: (value) =>
                    _controller.updateSetting('autoLocation', value),
              ),

              // Location
              _buildSectionHeader('Location'),
              _buildLocationCard(context),

              // About
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
                onPressed: () {
                  _showResetConfirmation(context);
                },
                backgroundColor: Colors.grey,
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.cabin(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.cabin(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.cabin(color: Colors.grey[400], fontSize: 13),
              )
            : null,
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    String? subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.cabin(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.cabin(color: Colors.grey[400], fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: value.toStringAsFixed(2),
                    onChanged: onChanged,
                    activeColor: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    value.toStringAsFixed(2),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cabin(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityDropdown(Map<String, dynamic> settings) {
    final quality = settings['arQuality'] ?? 'medium';

    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AR Quality',
              style: GoogleFonts.cabin(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust rendering quality',
              style: GoogleFonts.cabin(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: quality,
              dropdownColor: Colors.grey[850],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
              ),
              style: GoogleFonts.cabin(color: Colors.white, fontSize: 14),
              items: ['low', 'medium', 'high'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.toUpperCase(), style: GoogleFonts.cabin()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _controller.updateSetting('arQuality', value);
                }
              },
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
            Text(
              'Current Location',
              style: GoogleFonts.cabin(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            if (locationService.hasLocation)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationInfo(
                    'Latitude',
                    '${locationService.latitude.toStringAsFixed(4)}°',
                  ),
                  const SizedBox(height: 4),
                  _buildLocationInfo(
                    'Longitude',
                    '${locationService.longitude.toStringAsFixed(4)}°',
                  ),
                  const SizedBox(height: 4),
                  _buildLocationInfo(
                    'Altitude',
                    '${locationService.altitude.toStringAsFixed(0)}m',
                  ),
                ],
              )
            else
              Text(
                'Location not available',
                style: GoogleFonts.cabin(color: Colors.grey[400], fontSize: 14),
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

  Widget _buildLocationInfo(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: GoogleFonts.cabin(color: Colors.grey[500], fontSize: 14),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cabin(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            Text(
              'Asterixia v1.0',
              style: GoogleFonts.cabin(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AR Astronomy App',
              style: GoogleFonts.cabin(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track and visualize celestial bodies in augmented reality. '
              'View the Sun, Moon, and planets in real-time based on your location.',
              style: GoogleFonts.cabin(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Features:',
              style: GoogleFonts.cabin(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Real-time AR tracking of celestial bodies'),
            _buildFeatureItem('Sensor fusion for accurate positioning'),
            _buildFeatureItem(
              'Celestial guide lines (equator, ecliptic, horizon)',
            ),
            _buildFeatureItem('Interactive star map'),
            _buildFeatureItem('Astronomy calculations in pure Dart'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.cabin(color: Colors.blue, fontSize: 14),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cabin(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Reset Settings',
            style: GoogleFonts.cabin(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to reset all settings to their default values?',
            style: GoogleFonts.cabin(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.cabin(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                _controller.resetSettings();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Settings reset to defaults',
                      style: GoogleFonts.cabin(),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('Reset', style: GoogleFonts.cabin(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
