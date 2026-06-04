package com.ahmedalzeer.azkary

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val _keepAdhan by lazy { com.ahmedalzeer.azkary.R.raw.adhan }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ahmedalzeer.azkary/widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updatePrayerWidget" -> {
                        try {
                            updatePrayerWidgetDirectly()
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("UPDATE_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ahmedalzeer.azkary/alarms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleAlarm" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                            val prayerBody = call.argument<String>("prayerBody") ?: ""
                            val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                            AlarmReceiver.schedule(this@MainActivity, id, prayerName, prayerBody, triggerAtMillis)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("SCHEDULE_ERROR", e.message, null)
                        }
                    }
                    "cancelAlarm" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            AlarmReceiver.cancel(this@MainActivity, id)
                            result.success(true)
                        } catch (e: Throwable) {
                            result.error("CANCEL_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun updatePrayerWidgetDirectly() {
        val context: Context = applicationContext
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        if (appWidgetIds.isNotEmpty()) {
            val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(intent)
        }
    }

    private fun findNextPrayer(data: SharedPreferences, now: Long): Pair<String, Long> {
        val prayers = listOf(
            "الفجر" to data.getLong("fajr_millis", 0L),
            "الظهر" to data.getLong("dhuhr_millis", 0L),
            "العصر" to data.getLong("asr_millis", 0L),
            "المغرب" to data.getLong("maghrib_millis", 0L),
            "العشاء" to data.getLong("isha_millis", 0L),
        )
        for ((name, millis) in prayers) {
            if (millis > now) return name to millis
        }
        val tomorrowFajr = data.getLong("tomorrow_fajr_millis", 0L)
        if (tomorrowFajr > now) {
            return (data.getString("tomorrow_fajr_name", "الفجر") ?: "الفجر") to tomorrowFajr
        }
        return "الفجر" to 0L
    }
}
