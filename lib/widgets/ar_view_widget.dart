// lib/widgets/ar/ar_view_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class ARViewWidget extends StatefulWidget {
  final VoidCallback? onARViewCreated;
  final bool enablePlaneDetection;
  final bool enableLightEstimation;
  final bool enableAutoFocus;

  const ARViewWidget({
    Key? key,
    this.onARViewCreated,
    this.enablePlaneDetection = false,
    this.enableLightEstimation = true,
    this.enableAutoFocus = true,
  }) : super(key: key);

  @override
  State<ARViewWidget> createState() => _ARViewWidgetState();
}

class _ARViewWidgetState extends State<ARViewWidget>
    with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel(
    'com.astronomy.ar/engine',
  );
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseSession();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSession();
    }
  }

  Future<void> _initializeAR() async {
    if (_isInitialized) return;

    try {
      final result = await _channel.invokeMethod('initializeARSession', {
        'enablePlaneDetection': widget.enablePlaneDetection,
        'enableLightEstimation': widget.enableLightEstimation,
        'enableAutoFocus': widget.enableAutoFocus,
      });

      if (result == true) {
        setState(() {
          _isInitialized = true;
        });
        widget.onARViewCreated?.call();
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to initialize AR: ${e.message}');
    }
  }

  Future<void> _pauseSession() async {
    try {
      await _channel.invokeMethod('pauseSession');
    } catch (e) {
      debugPrint('Failed to pause AR session: $e');
    }
  }

  Future<void> _resumeSession() async {
    if (_isInitialized) {
      try {
        await _channel.invokeMethod('resumeSession');
      } catch (e) {
        debugPrint('Failed to resume AR session: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'com.example.astronomy_ar/arview',
        onPlatformViewCreated: (id) {
          // Small delay to ensure view is ready
          Future.delayed(const Duration(milliseconds: 500), _initializeAR);
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'com.example.astronomy_ar/arview',
        onPlatformViewCreated: (id) {
          Future.delayed(const Duration(milliseconds: 500), _initializeAR);
        },
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const Center(child: Text('AR not supported on this platform'));
  }
}
