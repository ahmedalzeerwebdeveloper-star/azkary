import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerData {
  final String name;
  final DateTime time;
  
  PrayerData(this.name, this.time);
}

class PrayerTimesService {
  static PrayerTimes? _prayerTimes;
  static Coordinates? _lastCoordinates;
  static DateTime? _lastDate;

  static void init(Position position) {
    _lastCoordinates = Coordinates(position.latitude, position.longitude);
    _calculateTimes();
  }

  static Coordinates? getCoordinates() => _lastCoordinates;

  static void refreshIfDayChanged() {
    final today = DateTime.now();
    if (_lastDate != null &&
        _lastDate!.year == today.year &&
        _lastDate!.month == today.month &&
        _lastDate!.day == today.day) {
      return;
    }
    if (_lastCoordinates != null) {
      _calculateTimes();
    }
  }

  static void _calculateTimes() {
    if (_lastCoordinates == null) return;
    
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    
    final now = DateTime.now();
    _lastDate = now;
    final date = DateComponents.from(now);
    _prayerTimes = PrayerTimes(_lastCoordinates!, date, params);
  }

  static List<PrayerData> getTodayPrayers() {
    if (_prayerTimes == null) return [];
    
    return [
      PrayerData('الفجر', _prayerTimes!.fajr),
      PrayerData('الشروق', _prayerTimes!.sunrise),
      PrayerData('الظهر', _prayerTimes!.dhuhr),
      PrayerData('العصر', _prayerTimes!.asr),
      PrayerData('المغرب', _prayerTimes!.maghrib),
      PrayerData('العشاء', _prayerTimes!.isha),
    ];
  }


  static List<PrayerData> getPrayersForDate(DateTime date) {
    if (_lastCoordinates == null) return [];
    
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;
    
    final dateComponents = DateComponents.from(date);
    final times = PrayerTimes(_lastCoordinates!, dateComponents, params);
    
    return [
      PrayerData('الفجر', times.fajr),
      PrayerData('الشروق', times.sunrise),
      PrayerData('الظهر', times.dhuhr),
      PrayerData('العصر', times.asr),
      PrayerData('المغرب', times.maghrib),
      PrayerData('العشاء', times.isha),
    ];
  }
  static PrayerData? getNextPrayer() {
    if (_prayerTimes == null) return null;
    
    final now = DateTime.now();
    final prayers = getTodayPrayers();
    
    for (var prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    
    // If all prayers today have passed, the next is Fajr tomorrow
    if (_lastCoordinates != null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextTimes = PrayerTimes(_lastCoordinates!, DateComponents.from(tomorrow), CalculationMethod.egyptian.getParameters());
      return PrayerData('الفجر', nextTimes.fajr);
    }
    return null;
  }
}
