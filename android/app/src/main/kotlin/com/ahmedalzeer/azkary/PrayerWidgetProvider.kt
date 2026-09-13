package com.ahmedalzeer.azkary

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d("PrayerWidgetProvider", "onReceive: action=$action")
        if (action == Intent.ACTION_USER_PRESENT ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == "android.intent.action.TIME_SET" ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_BOOT_COMPLETED
        ) {
            updateDirectly(context)
            return
        }
        super.onReceive(context, intent)
    }

    companion object {
        fun updateDirectly(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                    val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                    PrayerWidgetProvider().onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
                }
            } catch (e: Exception) {
                Log.e("PrayerWidgetProvider", "Error in updateDirectly", e)
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val now = System.currentTimeMillis()

        // 1. Check staleness and recalculate if needed
        ensureFreshData(context)

        // 2. Always read from fresh SharedPreferences
        val freshPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        // 3. Find the next prayer with robust fallback
        val (nextPrayerName, nextPrayerMillis) = findNextPrayer(freshPrefs, now, context)

        // 4. Ensure we use the latest prefs in case findNextPrayer performed a recalculation
        val displayPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

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

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = if (launchIntent != null) {
            android.app.PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                if (pendingIntent != null) {
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                setTextViewText(R.id.tv_fajr, displayPrefs.getString("fajr", "--"))
                setTextViewText(R.id.tv_shurooq, displayPrefs.getString("shurooq", "--"))
                setTextViewText(R.id.tv_dhuhr, displayPrefs.getString("dhuhr", "--"))
                setTextViewText(R.id.tv_asr, displayPrefs.getString("asr", "--"))
                setTextViewText(R.id.tv_maghrib, displayPrefs.getString("maghrib", "--"))
                setTextViewText(R.id.tv_isha, displayPrefs.getString("isha", "--"))
                setTextViewText(R.id.tv_city, displayPrefs.getString("city", "المدينة"))
                setTextViewText(R.id.tv_hijri, displayPrefs.getString("hijri", "التاريخ الهجري"))
                setTextViewText(R.id.tv_next_prayer_name, nextPrayerName)

                // Dynamically highlight the next prayer in orange, reset others to default grey
                prayerViewIds.forEach { (name, viewId) ->
                    val color = if (name == nextPrayerName) activeColor else defaultColor
                    setTextColor(viewId, color)
                }

                val timeDiff = nextPrayerMillis - now
                if (nextPrayerMillis > now && timeDiff > 1000) {
                    setViewVisibility(R.id.chrono_next_prayer_time, View.VISIBLE)
                    setViewVisibility(R.id.tv_now, View.GONE)
                    val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                    }
                    setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
                } else {
                    // Time has arrived or is past (within a few minutes)
                    setViewVisibility(R.id.chrono_next_prayer_time, View.GONE)
                    setViewVisibility(R.id.tv_now, View.VISIBLE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        WidgetUpdateScheduler.scheduleAll(context, displayPrefs)
    }

    /**
     * Check if the stored prayer data is from today. If not, recalculate
     * natively using PrayerCalculator so the widget always shows current data
     * even if the Flutter app hasn't been opened.
     */
    private fun ensureFreshData(context: Context) {
        val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val freshPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val lastUpdate = freshPrefs.getString("last_update_day", null)
        val fajrMillis = WidgetUpdateScheduler.readMillis(freshPrefs, "fajr_millis")
        val dhuhrMillis = WidgetUpdateScheduler.readMillis(freshPrefs, "dhuhr_millis")

        if (lastUpdate == todayStr && fajrMillis > 0L && dhuhrMillis > 0L) {
            return // Data is fresh and prayer times are valid, no recalculation needed
        }

        Log.d("PrayerWidgetProvider", "Data is stale or incomplete (last: $lastUpdate, today: $todayStr, fajr: $fajrMillis) – recalculating")
        try {
            PrayerCalculator.recalculateAndSave(context)
        } catch (e: Exception) {
            Log.e("PrayerWidgetProvider", "Error recalculating prayer times", e)
        }
    }

    private fun findNextPrayer(data: SharedPreferences, now: Long, context: Context, retried: Boolean = false): Pair<String, Long> {
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

        // All times have passed — data is stale. Force recalculation once.
        if (!retried) {
            Log.d("PrayerWidgetProvider", "All prayer times passed — forcing native recalculation")
            try {
                PrayerCalculator.recalculateAndSave(context)
                val freshData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                return findNextPrayer(freshData, now, context, retried = true)
            } catch (e: Exception) {
                Log.e("PrayerWidgetProvider", "Error during forced recalculation", e)
            }
        }

        // Ultimate fallback: calculate tomorrow's Fajr directly using PrayerCalculator
        try {
            val cal = java.util.Calendar.getInstance()
            cal.add(java.util.Calendar.DAY_OF_YEAR, 1)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val widgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val lat = PrayerCalculator.getLat(widgetPrefs, flutterPrefs)
            val lng = PrayerCalculator.getLng(widgetPrefs, flutterPrefs)
            val tz = PrayerCalculator.getTzOffset(widgetPrefs)
            val tomorrowTimes = PrayerCalculator.calculatePrayerTimes(cal, lat, lng, tz)
            return "الفجر" to tomorrowTimes.fajr
        } catch (_: Exception) {
            val cal = java.util.Calendar.getInstance()
            cal.add(java.util.Calendar.DAY_OF_YEAR, 1)
            cal.set(java.util.Calendar.HOUR_OF_DAY, 5)
            cal.set(java.util.Calendar.MINUTE, 5)
            return "الفجر" to cal.timeInMillis
        }
    }
}
