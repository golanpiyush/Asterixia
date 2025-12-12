import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionSheet {
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _LocationSheet(),
    );

    return result == true;
  }
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  bool _isRequesting = false;

  Future<void> _ask() async {
    setState(() => _isRequesting = true);

    final result = await Permission.location.request();

    setState(() => _isRequesting = false);

    if (result.isGranted) {
      Navigator.pop(context, true);
      return;
    }

    // If denied → show a soft retry sheet
    if (mounted) {
      Navigator.pop(context);
      _showRetrySheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location, size: 42, color: Colors.white),
          const SizedBox(height: 16),

          const Text(
            "Enable Location",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            "We use your location to show accurate positions of stars, planets and constellations above you.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),

          const SizedBox(height: 32),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRequesting ? null : _ask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isRequesting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Allow Location Access",
                      style: TextStyle(fontSize: 17),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Future<void> _showRetrySheet(BuildContext context) async {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: Colors.white70),
          const SizedBox(height: 16),

          const Text(
            "Location Required",
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),
          const Text(
            "Without location, we cannot show where stars are relative to you.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),

          const SizedBox(height: 22),

          FilledButton(
            onPressed: () async {
              Navigator.pop(context); // Close UI first

              await Future.delayed(
                const Duration(milliseconds: 250),
              ); // allow UI to settle

              final status = await Permission.location.request();

              if (status.isGranted) {
                return; // all good
              }
              print("tapped");
              // show retry if denied
              _showRetrySheet(context);
            },

            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Try Again"),
          ),

          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}
