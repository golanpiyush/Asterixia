import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asterixia/core/services/location_service.dart';
import 'package:asterixia/core/services/sensor_service.dart';
import 'star_map_painter.dart';
import '../../core/constants/app_strings.dart';
import '../../widgets/loading_indicator.dart';

class StarMapPage extends StatefulWidget {
  const StarMapPage({super.key});

  @override
  State<StarMapPage> createState() => _StarMapPageState();
}

class _StarMapPageState extends State<StarMapPage> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final locationService = Provider.of<LocationService>(
      context,
      listen: false,
    );
    final sensorService = Provider.of<SensorService>(context, listen: false);

    if (!locationService.hasLocation) {
      await locationService.initialize();
    }

    if (!sensorService.isCalibrated) {
      await sensorService.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    final sensorService = Provider.of<SensorService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Star Map'),
        backgroundColor: Colors.black.withOpacity(0.8),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF0A0A2A), Colors.black],
              ),
            ),
          ),

          // Star Map
          if (locationService.hasLocation && sensorService.isCalibrated)
            CustomPaint(
              painter: StarMapPainter(
                latitude: locationService.latitude,
                longitude: locationService.longitude,
                azimuth: sensorService.azimuth,
                pitch: sensorService.pitch,
              ),
              size: Size.infinite,
            ),

          // Loading
          if (locationService.isLoading || !sensorService.isCalibrated)
            const Center(child: LoadingIndicator()),

          // Info Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildInfoPanel(locationService, sensorService),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(LocationService location, SensorService sensor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Star Map View',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${location.latitude.toStringAsFixed(4)}°, ${location.longitude.toStringAsFixed(4)}°',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direction',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${sensor.getDirectionName()} (${sensor.azimuth.toStringAsFixed(1)}°)',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Showing solar system bodies and celestial guides',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
