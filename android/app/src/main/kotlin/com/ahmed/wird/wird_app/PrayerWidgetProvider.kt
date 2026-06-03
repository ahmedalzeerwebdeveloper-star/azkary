package com.ahmed.wird.wird_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                setTextViewText(R.id.tv_fajr, widgetData.getString("fajr", "--"))
                setTextViewText(R.id.tv_shurooq, widgetData.getString("shurooq", "--"))
                setTextViewText(R.id.tv_dhuhr, widgetData.getString("dhuhr", "--"))
                setTextViewText(R.id.tv_asr, widgetData.getString("asr", "--"))
                setTextViewText(R.id.tv_maghrib, widgetData.getString("maghrib", "--"))
                setTextViewText(R.id.tv_isha, widgetData.getString("isha", "--"))
                setTextViewText(R.id.tv_city, widgetData.getString("city", "المدينة"))
                setTextViewText(R.id.tv_hijri, widgetData.getString("hijri", "التاريخ الهجري"))

                val now = System.currentTimeMillis()
                val nextPrayerName: String
                val nextPrayerMillis: Long

                val savedNextTime = widgetData.getLong("nextPrayerTimeMillis", 0L)
                if (savedNextTime > now) {
                    nextPrayerName = widgetData.getString("nextPrayerName", "الصلاة") ?: "الصلاة"
                    nextPrayerMillis = savedNextTime
                } else {
                    val result = findNextPrayer(widgetData, now)
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

                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
                    }
                    val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }
                    val pendingIntent = PendingIntent.getBroadcast(context, widgetId, intent, flags)

                    alarmManager.cancel(pendingIntent)
                    try {
                        val alarmTime = nextPrayerMillis + 10_000
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC, alarmTime, pendingIntent)
                        } else {
                            alarmManager.setExact(AlarmManager.RTC, alarmTime, pendingIntent)
                        }
                    } catch (_: SecurityException) {
                        try {
                            alarmManager.setWindow(AlarmManager.RTC, nextPrayerMillis + 10_000, 60_000, pendingIntent)
                        } catch (_: Exception) {}
                    }
                } else {
                    setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "", false)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
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
