package com.ahmedalzeer.azkary

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = System.currentTimeMillis()
        val (nextPrayerName, nextPrayerMillis) = findNextPrayer(widgetData, now)

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
                setTextViewText(R.id.tv_next_prayer_name, nextPrayerName)

                val timeDiff = nextPrayerMillis - now
                if (nextPrayerMillis > now && timeDiff > 1000) {
                    val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                    }
                    setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
                } else {
                    setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "", false)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        WidgetUpdateScheduler.scheduleAll(context, widgetData)
    }

    private fun findNextPrayer(data: SharedPreferences, now: Long): Pair<String, Long> {
        val prayers = listOf(
            "الفجر" to WidgetUpdateScheduler.readMillis(data, "fajr_millis"),
            "الظهر" to WidgetUpdateScheduler.readMillis(data, "dhuhr_millis"),
            "العصر" to WidgetUpdateScheduler.readMillis(data, "asr_millis"),
            "المغرب" to WidgetUpdateScheduler.readMillis(data, "maghrib_millis"),
            "العشاء" to WidgetUpdateScheduler.readMillis(data, "isha_millis"),
        )
        for ((name, millis) in prayers) {
            if (millis > now) return name to millis
        }
        val tomorrowFajr = WidgetUpdateScheduler.readMillis(data, "tomorrow_fajr_millis")
        if (tomorrowFajr > now) {
            return (data.getString("tomorrow_fajr_name", "الفجر") ?: "الفجر") to tomorrowFajr
        }
        return "الفجر" to 0L
    }
}
