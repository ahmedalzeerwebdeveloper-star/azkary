import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latKey = 'cached_lat';
  static const String _lngKey = 'cached_lng';
  static const String _timeKey = 'cached_time';

  static Future<Position?> getCurrentPosition() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Check if we have valid cached position (< 6 hours old)
    final cachedTime = prefs.getInt(_timeKey);
    if (cachedTime != null) {
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(cachedTime);
      if (DateTime.now().difference(cacheDate).inHours < 6) {
        final position = _getCachedPosition(prefs);
        if (position != null) return position;
      }
    }

    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return _getCachedPosition(prefs);
    }

    if (!serviceEnabled) {
      return _getCachedPosition(prefs);
    }

    try {
      permission = await Geolocator.checkPermission();
    } catch (_) {
      return _getCachedPosition(prefs);
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (_) {
        return _getCachedPosition(prefs);
      }
      if (permission == LocationPermission.denied) {
        return _getCachedPosition(prefs);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _getCachedPosition(prefs);
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {
        position = null;
      }

      if (position != null) {
        await prefs.setDouble(_latKey, position.latitude);
        await prefs.setDouble(_lngKey, position.longitude);
        await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
        return position;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );

      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);
      await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);

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
