// lib/features/ar_view/ar_view_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/location_service.dart';
import '../../core/services/sensor_service.dart';
import '../../core/ar_engine/ar_platform_channel.dart';
import '../settings/settings_controller.dart';
import 'ar_controller.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/logger.dart';
import 'dart:io' show Platform;

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> with WidgetsBindingObserver {
  ARController? _arController;
  bool _isARLoaded = false;
  String _statusMessage = 'Initializing...';
  String? _selectedCelestialBody;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupEventListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arController?.dispose();
    ARPlatformChannel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_arController == null) return;

    switch (state) {
      case AppLifecycleState.paused:
        _arController?.pause();
        break;
      case AppLifecycleState.resumed:
        _arController?.resume();
        break;
      default:
        break;
    }
  }

  void _setupEventListeners() {
    // Listen for tap events on celestial bodies
    ARPlatformChannel.onCelestialBodyTapped = (nodeId, name) {
      setState(() {
        _selectedCelestialBody = name;
      });
      _showCelestialBodyInfo(name);
    };

    // Start listening to AR events
    ARPlatformChannel.startListeningToEvents();
  }

  void _showCelestialBodyInfo(String name) {
    final info = _getCelestialBodyInfo(name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getCelestialBodyIcon(name),
              color: _getCelestialBodyColor(name),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(name, style: GoogleFonts.cabin(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info['description'] ?? 'No description available',
                style: GoogleFonts.cabin(fontSize: 15),
              ),
              const SizedBox(height: 16),
              if (info['distance'] != null) ...[
                _buildInfoRow('Distance', info['distance']!),
                const SizedBox(height: 8),
              ],
              if (info['diameter'] != null) ...[
                _buildInfoRow('Diameter', info['diameter']!),
                const SizedBox(height: 8),
              ],
              if (info['type'] != null) ...[
                _buildInfoRow('Type', info['type']!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.cabin()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: GoogleFonts.cabin(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.cabin(color: Colors.black54)),
        ),
      ],
    );
  }

  Map<String, String> _getCelestialBodyInfo(String name) {
    final infoMap = {
      'Sun': {
        'description':
            'The Sun is the star at the center of our Solar System. It provides light and heat to Earth.',
        'distance': '149.6 million km (1 Astronomical Unit)',
        'diameter': '1.39 million km',
        'type': 'G-type main-sequence star',
      },
      'Moon': {
        'description':
            'Earth\'s only natural satellite. It affects tides and has been visited by humans.',
        'distance': '384,400 km from Earth',
        'diameter': '3,474 km',
        'type': 'Natural satellite',
      },
      'Mercury': {
        'description':
            'The smallest planet in our Solar System and closest to the Sun.',
        'distance': '0.39 AU (Astronomical Unit) from Sun',
        'diameter': '4,879 km',
        'type': 'Rocky planet',
      },
      'Venus': {
        'description':
            'Often called Earth\'s twin due to similar size. Hottest planet with thick atmosphere.',
        'distance': '0.72 AU (Astronomical Unit) from Sun',
        'diameter': '12,104 km',
        'type': 'Rocky planet',
      },
      'Earth': {
        'description': 'Our home planet. The only known world with life.',
        'distance': '1.0 AU (Astronomical Unit) from Sun',
        'diameter': '12,742 km',
        'type': 'Rocky planet',
      },
      'Mars': {
        'description': 'The Red Planet. Target for future human exploration.',
        'distance': '1.52 AU (Astronomical Unit) from Sun',
        'diameter': '6,779 km',
        'type': 'Rocky planet',
      },
      'Jupiter': {
        'description':
            'The largest planet in our Solar System. A gas giant with a Great Red Spot.',
        'distance': '5.2 AU (Astronomical Unit) from Sun',
        'diameter': '139,820 km',
        'type': 'Gas giant',
      },
      'Saturn': {
        'description': 'Known for its beautiful ring system. A gas giant.',
        'distance': '9.5 AU (Astronomical Unit) from Sun',
        'diameter': '116,460 km',
        'type': 'Gas giant',
      },
      'Uranus': {
        'description': 'An ice giant that rotates on its side.',
        'distance': '19.2 AU (Astronomical Unit) from Sun',
        'diameter': '50,724 km',
        'type': 'Ice giant',
      },
      'Neptune': {
        'description':
            'The farthest planet from the Sun. An ice giant with strong winds.',
        'distance': '30.1 AU (Astronomical Unit) from Sun',
        'diameter': '49,244 km',
        'type': 'Ice giant',
      },
    };

    return infoMap[name] ??
        {'description': 'A celestial object in the sky.', 'type': 'Unknown'};
  }

  IconData _getCelestialBodyIcon(String name) {
    switch (name.toLowerCase()) {
      case 'sun':
        return Icons.wb_sunny;
      case 'moon':
        return Icons.nightlight_round;
      case 'earth':
        return Icons.public;
      default:
        return Icons.circle;
    }
  }

  Color _getCelestialBodyColor(String name) {
    switch (name.toLowerCase()) {
      case 'sun':
        return Colors.orange;
      case 'moon':
        return Colors.grey;
      case 'mercury':
        return Colors.brown;
      case 'venus':
        return Colors.amber;
      case 'earth':
        return Colors.blue;
      case 'mars':
        return Colors.red;
      case 'jupiter':
        return Colors.orange.shade300;
      case 'saturn':
        return Colors.yellow.shade700;
      case 'uranus':
        return Colors.cyan;
      case 'neptune':
        return Colors.blue.shade900;
      default:
        return Colors.white;
    }
  }

  Future<void> _initializeServices() async {
    setState(() {
      _statusMessage = 'Initializing services...';
    });

    try {
      final locationService = Provider.of<LocationService>(
        context,
        listen: false,
      );
      final sensorService = Provider.of<SensorService>(context, listen: false);
      final settingsController = Provider.of<SettingsController>(
        context,
        listen: false,
      );

      // Initialize location service
      await locationService.initialize();

      // Initialize sensor service
      await sensorService.initialize();

      // Wait for location to be available
      if (!locationService.hasLocation) {
        setState(() {
          _statusMessage = 'Waiting for location...';
        });

        // Wait up to 10 seconds for location
        int attempts = 0;
        while (!locationService.hasLocation && attempts < 20) {
          await Future.delayed(const Duration(milliseconds: 500));
          attempts++;
        }
      }

      if (!locationService.hasLocation) {
        setState(() {
          _statusMessage =
              'Location unavailable. Please enable location services.';
        });
        return;
      }

      // Initialize AR Controller
      setState(() {
        _statusMessage = 'Initializing AR session...';
      });

      _arController = ARController(
        locationService: locationService,
        sensorService: sensorService,
        settingsController: settingsController,
      );

      await _arController!.initialize();

      setState(() {
        _isARLoaded = true;
        _statusMessage = 'AR Ready - Point at the sky!';
      });

      Logger.ar('All services initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize services', error: e);
      setState(() {
        _statusMessage = 'Initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final sensorService = Provider.of<SensorService>(context);
    final settingsController = Provider.of<SettingsController>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Native AR Camera View
          _buildARCameraView(),

          // Loading overlay
          if (!_isARLoaded)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LoadingIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage,
                      style: GoogleFonts.cabin(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Error messages
          if (locationService.error.isNotEmpty)
            _buildErrorOverlay(locationService.error),
          if (sensorService.error.isNotEmpty)
            _buildErrorOverlay(sensorService.error),

          // Status overlay
          if (!locationService.isLoading && _isARLoaded)
            _buildStatusOverlay(
              locationService,
              sensorService,
              settingsController,
            ),

          // Controls overlay
          if (_isARLoaded)
            Positioned(
              top: 40,
              right: 20,
              child: _buildControls(settingsController),
            ),

          // Info button
          if (_isARLoaded)
            Positioned(top: 40, left: 20, child: _buildInfoButton()),
        ],
      ),
    );
  }

  Widget _buildARCameraView() {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'com.example.astronomy_ar/arview',
        creationParams: <String, dynamic>{
          'enablePlaneDetection': false,
          'enableLightEstimation': true,
          'enableAutoFocus': true,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          Logger.ar('iOS AR View created with ID: $id');
        },
      );
    } else if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'com.example.astronomy_ar/arview',
        creationParams: <String, dynamic>{
          'enablePlaneDetection': false,
          'enableLightEstimation': true,
          'enableAutoFocus': true,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          Logger.ar('Android AR View created with ID: $id');
        },
      );
    } else {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            'AR not supported on this platform',
            style: GoogleFonts.cabin(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }
  }

  Widget _buildErrorOverlay(String error) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(error, style: GoogleFonts.cabin(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(
    LocationService location,
    SensorService sensor,
    SettingsController settings,
  ) {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                    style: GoogleFonts.cabin(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.explore, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${sensor.getDirectionName()} (${sensor.azimuth.toStringAsFixed(0)}°)',
                  style: GoogleFonts.cabin(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.straighten,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pitch: ${sensor.pitch.toStringAsFixed(0)}° | Roll: ${sensor.roll.toStringAsFixed(0)}°',
                  style: GoogleFonts.cabin(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Row(
              children: [
                Icon(
                  settings.nightMode ? Icons.nightlight : Icons.wb_sunny,
                  color: settings.nightMode
                      ? Colors.blue.shade200
                      : Colors.yellow,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.nightMode
                        ? 'Night mode: Enhanced glow'
                        : AppStrings.pointingAtSky,
                    style: GoogleFonts.cabin(
                      color: settings.nightMode
                          ? Colors.blue.shade200
                          : Colors.yellowAccent,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedCelestialBody != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: $_selectedCelestialBody',
                style: GoogleFonts.cabin(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControls(SettingsController settings) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Night mode toggle
          _buildControlButton(
            icon: settings.nightMode ? Icons.nightlight : Icons.wb_sunny,
            tooltip: 'Toggle Night Mode',
            isActive: settings.nightMode,
            onPressed: () =>
                _arController?.toggleNightMode(!settings.nightMode),
          ),
          const SizedBox(height: 8),

          // Toggle guide lines
          _buildControlButton(
            icon: settings.showGuides ? Icons.layers : Icons.layers_outlined,
            tooltip: 'Toggle Guide Lines',
            isActive: settings.showGuides,
            onPressed: () => _arController?.toggleGuides(!settings.showGuides),
          ),
          const SizedBox(height: 8),

          // Toggle labels
          _buildControlButton(
            icon: settings.showLabels ? Icons.label : Icons.label_outline,
            tooltip: 'Toggle Labels',
            isActive: settings.showLabels,
            onPressed: () => _arController?.toggleLabels(!settings.showLabels),
          ),
          const SizedBox(height: 8),

          // Refresh
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Refresh AR Scene',
            isActive: false,
            onPressed: _refreshAR,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoButton() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: IconButton(
        icon: const Icon(Icons.info_outline, color: Colors.white),
        onPressed: _showInfoDialog,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'AR Astronomy Help',
          style: GoogleFonts.cabin(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use:',
                style: GoogleFonts.cabin(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('📱', 'Point your phone at the sky'),
              _buildInfoItem('👆', 'Tap any celestial body to see details'),
              _buildInfoItem('🌟', 'See planets, Sun, and Moon in AR'),
              _buildInfoItem('🌙', 'Use night mode for better visibility'),
              _buildInfoItem('🔵', 'Blue lines show celestial equator'),
              _buildInfoItem('🟡', 'Yellow lines show ecliptic path'),
              _buildInfoItem('⚪', 'White lines show horizon'),
              const SizedBox(height: 12),
              Text(
                'Controls:',
                style: GoogleFonts.cabin(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('🌙', 'Toggle night mode'),
              _buildInfoItem('📐', 'Toggle guide lines'),
              _buildInfoItem('🏷️', 'Toggle object labels'),
              _buildInfoItem('🔄', 'Refresh the AR scene'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: GoogleFonts.cabin()),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.cabin())),
        ],
      ),
    );
  }

  Future<void> _refreshAR() async {
    setState(() {
      _statusMessage = 'Refreshing...';
    });

    await _arController?.refresh();

    setState(() {
      _statusMessage = 'AR Ready - Point at the sky!';
    });
  }
}
