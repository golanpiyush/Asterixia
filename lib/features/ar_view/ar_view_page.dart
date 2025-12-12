// lib/features/ar_view/ar_view_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/location_service.dart';
import '../../core/services/sensor_service.dart';
import 'ar_controller.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/logger.dart';

class ARViewPage extends StatefulWidget {
  const ARViewPage({super.key});

  @override
  State<ARViewPage> createState() => _ARViewPageState();
}

class _ARViewPageState extends State<ARViewPage> with WidgetsBindingObserver {
  ARController? _arController;
  bool _isARLoaded = false;
  bool _showGuides = true;
  bool _showLabels = true;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _arController?.dispose();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // AR View (native camera view rendered in background)
          // The actual AR rendering happens on the native side
          Container(
            color: Colors.black,
            child: Center(
              child: _isARLoaded
                  ? const Text(
                      '📱 AR Camera Active',
                      style: TextStyle(color: Colors.white24, fontSize: 16),
                    )
                  : null,
            ),
          ),

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
                      style: const TextStyle(color: Colors.white),
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
            _buildStatusOverlay(locationService, sensorService),

          // Controls overlay
          if (_isARLoaded)
            Positioned(top: 40, right: 20, child: _buildControls()),

          // Info button
          if (_isARLoaded)
            Positioned(top: 40, left: 20, child: _buildInfoButton()),
        ],
      ),
    );
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
              child: Text(error, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(LocationService location, SensorService sensor) {
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
                    style: const TextStyle(
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: Colors.yellow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.pointingAtSky,
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Toggle guide lines
          _buildControlButton(
            icon: _showGuides ? Icons.layers : Icons.layers_outlined,
            tooltip: 'Toggle Guide Lines',
            isActive: _showGuides,
            onPressed: () {
              setState(() => _showGuides = !_showGuides);
              _arController?.toggleGuides(_showGuides);
            },
          ),
          const SizedBox(height: 8),

          // Toggle labels
          _buildControlButton(
            icon: _showLabels ? Icons.label : Icons.label_outline,
            tooltip: 'Toggle Labels',
            isActive: _showLabels,
            onPressed: () {
              setState(() => _showLabels = !_showLabels);
              _arController?.toggleLabels(_showLabels);
            },
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
        title: const Text('AR Astronomy Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How to use:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('📱', 'Point your phone at the sky'),
              _buildInfoItem('🌟', 'See planets, Sun, and Moon in AR'),
              _buildInfoItem('🔵', 'Blue lines show celestial equator'),
              _buildInfoItem('🟡', 'Yellow lines show ecliptic path'),
              _buildInfoItem('⚪', 'White lines show horizon'),
              _buildInfoItem('🔄', 'Cyan axes show planetary rotation'),
              const SizedBox(height: 12),
              const Text(
                'Controls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildInfoItem('📐', 'Toggle guide lines'),
              _buildInfoItem('🏷️', 'Toggle object labels'),
              _buildInfoItem('🔄', 'Refresh the AR scene'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
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
          Expanded(child: Text(text)),
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
