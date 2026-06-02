package com.ahmed.wird.wird_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ahmed.wird.wird_app/widget")
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
    }

    private fun updatePrayerWidgetDirectly() {
        val context: Context = applicationContext
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
            setTextViewText(R.id.tv_fajr, prefs.getString("fajr", "--") ?: "--")
            setTextViewText(R.id.tv_shurooq, prefs.getString("shurooq", "--") ?: "--")
            setTextViewText(R.id.tv_dhuhr, prefs.getString("dhuhr", "--") ?: "--")
            setTextViewText(R.id.tv_asr, prefs.getString("asr", "--") ?: "--")
            setTextViewText(R.id.tv_maghrib, prefs.getString("maghrib", "--") ?: "--")
            setTextViewText(R.id.tv_isha, prefs.getString("isha", "--") ?: "--")
            setTextViewText(R.id.tv_city, prefs.getString("city", "المدينة") ?: "المدينة")
            setTextViewText(R.id.tv_hijri, prefs.getString("hijri", "التاريخ الهجري") ?: "التاريخ الهجري")
            setTextViewText(R.id.tv_next_prayer_name, prefs.getString("nextPrayerName", "الصلاة") ?: "الصلاة")
            
            val nextPrayerTimeMillis = prefs.getLong("nextPrayerTimeMillis", 0L)
            if (nextPrayerTimeMillis > 0L) {
                val timeDiff = nextPrayerTimeMillis - System.currentTimeMillis()
                val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                }
                setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
            } else {
                setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "بعد --:--", false)
            }
        }

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
