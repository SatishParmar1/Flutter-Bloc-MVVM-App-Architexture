import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class LocationService {
  LocationService._();

  static Future<bool> isLocationServiceEnabled() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        AppLogger.warning('Location services are disabled on this device.', tag: 'LocationService');
      }
      return enabled;
    } catch (e) {
      AppLogger.error('Failed to check if location services are enabled', error: e, tag: 'LocationService');
      return false;
    }
  }

  static Future<LocationPermission> handlePermissionFlow() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permission denied by user', tag: 'LocationService');
          return LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission permanently denied. Settings must be opened.', tag: 'LocationService');
        return LocationPermission.deniedForever;
      }

      AppLogger.success('Location permission approved: ${permission.name}', tag: 'LocationService');
      return permission;
    } catch (e) {
      AppLogger.error('Error during location permission flow', error: e, tag: 'LocationService');
      return LocationPermission.denied;
    }
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final isServiceEnabled = await isLocationServiceEnabled();
      if (!isServiceEnabled) return null;

      final permission = await handlePermissionFlow();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      AppLogger.success(
        'Current Position: Lat: ${position.latitude}, Lng: ${position.longitude} (Acc: ${position.accuracy}m)',
        tag: 'LocationService',
      );
      return position;
    } catch (e, stack) {
      AppLogger.error('Failed to retrieve current location', error: e, stackTrace: stack, tag: 'LocationService');
      return null;
    }
  }

  static Stream<Position> getLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      final double distanceInMeters = Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
      return distanceInMeters;
    } catch (e) {
      AppLogger.error('Failed to calculate distance', error: e, tag: 'LocationService');
      return 0.0;
    }
  }

  static Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      AppLogger.error('Failed to open location settings', error: e, tag: 'LocationService');
      return false;
    }
  }
}
