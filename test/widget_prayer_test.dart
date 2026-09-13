import 'package:flutter_test/flutter_test.dart';
import 'package:adhan/adhan.dart';

void main() {
  test('Prayer times correctly identify next prayer throughout the day', () {
    // El Husseiniya coordinates
    final coordinates = Coordinates(30.86, 31.92);
    final date = DateComponents(2026, 9, 13);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final prayers = PrayerTimes(coordinates, date, params);
    
    expect(prayers.fajr.hour, 5);

    // Case 1: 03:00 AM -> Next is Fajr
    final t1 = DateTime(2026, 9, 13, 3, 0);
    expect(prayers.fajr.isAfter(t1), isTrue);

    // Case 2: 09:47 AM (The user's screenshot time!)
    final t2 = DateTime(2026, 9, 13, 9, 47);
    expect(prayers.fajr.isAfter(t2), isFalse);
    expect(prayers.sunrise.isAfter(t2), isFalse);
    expect(prayers.dhuhr.isAfter(t2), isTrue); // Next MUST be Dhuhr!

    // Case 3: 13:00 PM -> Next is Asr
    final t3 = DateTime(2026, 9, 13, 13, 0);
    expect(prayers.dhuhr.isAfter(t3), isFalse);
    expect(prayers.asr.isAfter(t3), isTrue);

    // Case 4: 17:00 PM -> Next is Maghrib
    final t4 = DateTime(2026, 9, 13, 17, 0);
    expect(prayers.asr.isAfter(t4), isFalse);
    expect(prayers.maghrib.isAfter(t4), isTrue);

    // Case 5: 19:30 PM -> Next is Isha
    final t5 = DateTime(2026, 9, 13, 19, 30);
    expect(prayers.maghrib.isAfter(t5), isFalse);
    expect(prayers.isha.isAfter(t5), isTrue);

    // Case 6: 22:00 PM -> All today passed, next is tomorrow Fajr
    final t6 = DateTime(2026, 9, 13, 22, 0);
    expect(prayers.isha.isAfter(t6), isFalse);
    final tomorrowPrayers = PrayerTimes(coordinates, DateComponents(2026, 9, 14), params);
    expect(tomorrowPrayers.fajr.isAfter(t6), isTrue);
  });
}
