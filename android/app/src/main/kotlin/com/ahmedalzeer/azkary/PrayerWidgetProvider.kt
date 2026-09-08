package com.ahmedalzeer.azkary

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = System.currentTimeMillis()

        // Check if data is stale (from a previous day) and recalculate if needed
        ensureFreshData(context, widgetData)

        val (nextPrayerName, nextPrayerMillis) = findNextPrayer(widgetData, now)

        val prayerViewIds = mapOf(
            "الفجر" to R.id.tv_fajr,
            "الشروق" to R.id.tv_shurooq,
            "الظهر" to R.id.tv_dhuhr,
            "العصر" to R.id.tv_asr,
            "المغرب" to R.id.tv_maghrib,
            "العشاء" to R.id.tv_isha,
        )

        val activeColor = android.graphics.Color.parseColor("#ff8f00")
        val defaultColor = android.graphics.Color.parseColor("#757575")

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

                // Dynamically highlight the next prayer in orange, reset others to default grey
                prayerViewIds.forEach { (name, viewId) ->
                    val color = if (name == nextPrayerName) activeColor else defaultColor
                    setTextColor(viewId, color)
                }

                val timeDiff = nextPrayerMillis - now
                if (nextPrayerMillis > now && timeDiff > 1000) {
                    val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                    }
                    setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
                } else {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.chrono_next_prayer_time, false)
                    }
                    setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "حان الآن", false)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        WidgetUpdateScheduler.scheduleAll(context, widgetData)
    }

    /**
     * Check if the stored prayer data is from today. If not, recalculate
     * natively using PrayerCalculator so the widget always shows current data
     * even if the Flutter app hasn't been opened.
     */
    private fun ensureFreshData(context: Context, widgetData: SharedPreferences) {
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val lastUpdate = widgetData.getString("last_update_day", null)

        if (lastUpdate == todayStr) {
            return // Data is fresh, no recalculation needed
        }

        Log.d("PrayerWidgetProvider", "Data is stale (last: $lastUpdate, today: $todayStr) – recalculating")
        try {
            PrayerCalculator.recalculateAndSave(context)
        } catch (e: Exception) {
            Log.e("PrayerWidgetProvider", "Error recalculating prayer times", e)
        }
    }

    private fun findNextPrayer(data: SharedPreferences, now: Long): Pair<String, Long> {
        val prayers = listOf(
            "الفجر" to WidgetUpdateScheduler.readMillis(data, "fajr_millis"),
            "الشروق" to WidgetUpdateScheduler.readMillis(data, "shurooq_millis"),
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
