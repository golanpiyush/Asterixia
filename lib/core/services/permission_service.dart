import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestLocation() async {
    final status = await Permission.location.status;

    // Already granted
    if (status.isGranted) return true;

    // Request permission
    final result = await Permission.location.request();

    // If permanently denied → open settings
    if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return result.isGranted;
  }
}
