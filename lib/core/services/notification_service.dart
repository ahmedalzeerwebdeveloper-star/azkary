import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'prayer_times_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const MethodChannel _alarmChannel = MethodChannel('com.ahmed.wird.wird_app/alarms');

  static int _prayerIndex(String name) {
    switch (name) {
      case 'الفجر': return 0;
      case 'الظهر': return 1;
      case 'العصر': return 2;
      case 'المغرب': return 3;
      case 'العشاء': return 4;
      default: return 5;
    }
  }

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> testNotification() async {
    try {
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

      const androidDetails = AndroidNotificationDetails(
        'prayer_channel_v2',
        'مواقيت الصلاة',
        channelDescription: 'تنبيهات الأذان ومواقيت الصلاة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
      );

      await _notificationsPlugin.show(
        9999,
        'تم التطوير بواسطة',
        'أحمد علي الزير',
        NotificationDetails(
          android: androidDetails,
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Test notification failed: $e');
    }
  }

  static Future<void> schedulePrayerNotifications() async {
    final now = DateTime.now();
    int scheduled = 0;

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final prayers = PrayerTimesService.getPrayersForDate(date);

      for (var prayer in prayers) {
        if (prayer.name == 'الشروق') continue;

        if (prayer.time.isAfter(now)) {
          String body;
          if (prayer.name == 'الفجر') {
            body = 'الصلاة خير من النوم - قم ولبِّ نداء الله';
          } else {
            body = 'حان الآن موعد صلاة ${prayer.name} - أقم صلاتك تسعد حياتك';
          }

          final int id = i * 10 + _prayerIndex(prayer.name);

          await _scheduleNotification(
            id: id,
            prayerName: prayer.name,
            body: body,
            scheduledTime: prayer.time,
          );
          scheduled++;
        }
      }
    }
    debugPrint('Scheduled $scheduled prayer notifications');
  }

  static Future<void> triggerPrayerNotification(String prayerName, String body) async {
    try {
      await _notificationsPlugin.show(
        7777,
        'نداء الصلاة - $prayerName',
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel_v2',
            'مواقيت الصلاة',
            channelDescription: 'تنبيهات الأذان ومواقيت الصلاة',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('adhan'),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Prayer notification failed: $e');
    }
  }

  static void scheduleDebugTimerTest({int secondsFromNow = 15}) {
    Future.delayed(Duration(seconds: secondsFromNow), () async {
      try {
        await _notificationsPlugin.show(
          8887,
          'اختبار التأخير',
          'ظهر بعد $secondsFromNow ثانية - الإشعارات شغالة',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'prayer_channel_v2',
              'مواقيت الصلاة',
              channelDescription: 'تنبيهات الأذان ومواقيت الصلاة',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              sound: RawResourceAndroidNotificationSound('adhan'),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Timer test failed: $e');
      }
    });
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String prayerName,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _alarmChannel.invokeMethod('scheduleAlarm', {
        'id': id,
        'prayerName': prayerName,
        'prayerBody': body,
        'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Failed to schedule alarm for $prayerName at $scheduledTime: $e');
    }
  }
}
