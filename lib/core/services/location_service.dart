import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latKey = 'cached_lat';
  static const String _lngKey = 'cached_lng';

  /// Returns the cached location if available, otherwise requests it
  static Future<Position?> getCurrentPosition() async {
    final prefs = await SharedPreferences.getInstance();
    
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _getCachedPosition(prefs);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _getCachedPosition(prefs);
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return _getCachedPosition(prefs);
    } 

    try {
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        // Cache it
        await prefs.setDouble(_latKey, position.latitude);
        await prefs.setDouble(_lngKey, position.longitude);
        return position;
      }
      
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 4));
      
      // Cache it
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);
      
      return position;
    } catch (e) {
      return _getCachedPosition(prefs);
    }
  }

  static Position? _getCachedPosition(SharedPreferences prefs) {
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat != null && lng != null) {
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    }
    return null;
  }
}
