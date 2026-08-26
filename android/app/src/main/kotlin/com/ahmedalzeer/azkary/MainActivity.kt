package com.ahmedalzeer.azkary

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
}
