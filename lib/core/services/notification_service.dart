import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_times_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

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

    // Request permissions for Android 13+
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
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('Test notification sent successfully');
    } catch (e) {
      debugPrint('Test notification failed: $e');
    }
  }

  static Future<void> schedulePrayerNotifications() async {
    final now = DateTime.now();
    int scheduled = 0;
    int id = 0;

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

          await _scheduleNotification(
            id: id++,
            title: 'نداء الصلاة',
            body: body,
            scheduledTime: prayer.time,
          );
          scheduled++;
        }
      }
    }
    debugPrint('Scheduled $scheduled prayer notifications');
  }

  static Future<void> scheduleDebugNotification({int secondsFromNow = 30}) async {
    try {
      _notificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

      await _notificationsPlugin.zonedSchedule(
        8888,
        'اختبار جدولة الإشعارات',
        'تم جدولة هذا الإشعار قبل $secondsFromNow ث - إذا رأيته فالجَدوَلة تعمل',
        tz.TZDateTime.from(DateTime.now().add(Duration(seconds: secondsFromNow)), tz.local),
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Debug notification scheduled via zonedSchedule');
    } catch (e) {
      debugPrint('zonedSchedule failed: $e');
    }
  }

  static void scheduleDebugTimerTest({int secondsFromNow = 30}) {
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
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
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
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Exact notification failed for $title at $scheduledTime: $e');
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledTime, tz.local),
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('Inexact fallback also failed for $title: $e2');
      }
    }
  }
}
