// ignore_for_file: empty_catches

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:geocoding/geocoding.dart';
import 'prayer_times_service.dart';
import 'location_service.dart';

class WidgetService {
  static const String appGroupId = 'com.ahmedalzeer.azkary';
  static const String androidWidgetName = 'PrayerWidgetProvider';
  static const _widgetChannel = MethodChannel('com.ahmedalzeer.azkary/widget');

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {
    }
  }

  static Future<void> updateWidget() async {
    try {
      var prayers = PrayerTimesService.getTodayPrayers();
      if (prayers.isEmpty) {
        var position = await LocationService.getCurrentPosition();
        if (position == null) return;
        PrayerTimesService.init(position);
        prayers = PrayerTimesService.getTodayPrayers();
      }
      if (prayers.isEmpty) return;

String city = 'المدينة';
      try {
        final coords = PrayerTimesService.getCoordinates();
        if (coords == null) return;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          coords.latitude,
          coords.longitude,
        ).timeout(const Duration(seconds: 5));
        if (placemarks.isNotEmpty) {
          city = placemarks.first.subAdministrativeArea ?? placemarks.first.locality ?? 'المدينة';
        }
      } catch (_) {
      }
      
      const arabicDays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
      final currentDay = arabicDays[DateTime.now().weekday - 1];
      city = '$currentDay، $city';

      HijriCalendar.setLocal('ar');
      final today = HijriCalendar.now();
      String hijriDate = '${today.hDay} ${today.longMonthName} ${today.hYear}';

      await HomeWidget.saveWidgetData<String>('city', city);
      await HomeWidget.saveWidgetData<String>('hijri', hijriDate);
      final tomorrowPrayers = PrayerTimesService.getPrayersForDate(DateTime.now().add(const Duration(days: 1)));
      if (tomorrowPrayers.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('tomorrow_fajr_name', tomorrowPrayers.first.name);
        await HomeWidget.saveWidgetData<int>('tomorrow_fajr_millis', tomorrowPrayers.first.time.millisecondsSinceEpoch);
      }

      for (var prayer in prayers) {
        String key;
        if (prayer.name == 'الفجر') {
          key = 'fajr';
        } else if (prayer.name == 'الشروق') {
          key = 'shurooq';
        } else if (prayer.name == 'الظهر') {
          key = 'dhuhr';
        } else if (prayer.name == 'العصر') {
          key = 'asr';
        } else if (prayer.name == 'المغرب') {
          key = 'maghrib';
        } else if (prayer.name == 'العشاء') {
          key = 'isha';
        } else {
          key = '';
        }

        if (key.isNotEmpty) {
          await HomeWidget.saveWidgetData<String>(key, DateFormat('hh:mm a').format(prayer.time).replaceAll('AM', 'ص').replaceAll('PM', 'م'));
          await HomeWidget.saveWidgetData<int>('${key}_millis', prayer.time.millisecondsSinceEpoch);
        }
      }

      // Mark data as fresh so the native widget knows not to recalculate
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await HomeWidget.saveWidgetData<String>('last_update_day', todayStr);

      _updateWidgetAppearance();
    } catch (_) {
    }
  }

  static Future<void> _updateWidgetAppearance() async {
    try {
      await _widgetChannel
          .invokeMethod('updatePrayerWidget')
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      try {
        await HomeWidget.updateWidget(
          name: androidWidgetName,
          qualifiedAndroidName: 'com.ahmedalzeer.azkary.PrayerWidgetProvider',
        );
      } catch (_) {
      }
    }
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _widgetChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _widgetChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (_) {
    }
  }
}
