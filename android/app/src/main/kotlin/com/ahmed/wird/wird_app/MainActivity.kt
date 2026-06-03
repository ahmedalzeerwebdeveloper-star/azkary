package com.ahmed.wird.wird_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val _keepAdhan by lazy { com.ahmed.wird.wird_app.R.raw.adhan }
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

            val now = System.currentTimeMillis()
            val nextPrayerName: String
            val nextPrayerMillis: Long

            val savedNextTime = prefs.getLong("nextPrayerTimeMillis", 0L)
            if (savedNextTime > now) {
                nextPrayerName = prefs.getString("nextPrayerName", "الصلاة") ?: "الصلاة"
                nextPrayerMillis = savedNextTime
            } else {
                val result = findNextPrayer(prefs, now)
                nextPrayerName = result.first
                nextPrayerMillis = result.second
            }

            setTextViewText(R.id.tv_next_prayer_name, nextPrayerName)

            val timeDiff = nextPrayerMillis - now
            if (nextPrayerMillis > now && timeDiff > 5000) {
                val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                    setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                }
                setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
            } else {
                setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "", false)
            }
        }

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
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
