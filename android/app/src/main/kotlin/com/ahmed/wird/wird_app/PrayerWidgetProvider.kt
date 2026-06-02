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
                val fajr = widgetData.getString("fajr", "--")
                val shurooq = widgetData.getString("shurooq", "--")
                val dhuhr = widgetData.getString("dhuhr", "--")
                val asr = widgetData.getString("asr", "--")
                val maghrib = widgetData.getString("maghrib", "--")
                val isha = widgetData.getString("isha", "--")
                
                val city = widgetData.getString("city", "المدينة")
                val hijri = widgetData.getString("hijri", "التاريخ الهجري")
                val nextPrayerName = widgetData.getString("nextPrayerName", "الصلاة")
                val nextPrayerTimeMillis = widgetData.getLong("nextPrayerTimeMillis", 0L)

                setTextViewText(R.id.tv_fajr, fajr)
                setTextViewText(R.id.tv_shurooq, shurooq)
                setTextViewText(R.id.tv_dhuhr, dhuhr)
                setTextViewText(R.id.tv_asr, asr)
                setTextViewText(R.id.tv_maghrib, maghrib)
                setTextViewText(R.id.tv_isha, isha)
                
                setTextViewText(R.id.tv_city, city)
                setTextViewText(R.id.tv_hijri, hijri)
                setTextViewText(R.id.tv_next_prayer_name, nextPrayerName)
                
                if (nextPrayerTimeMillis > System.currentTimeMillis()) {
                    val timeDiff = nextPrayerTimeMillis - System.currentTimeMillis()
                    val chronometerBase = android.os.SystemClock.elapsedRealtime() + timeDiff
                    
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        setChronometerCountDown(R.id.chrono_next_prayer_time, true)
                    }
                    setChronometer(R.id.chrono_next_prayer_time, chronometerBase, "بعد %s", true)
                    
                    // Schedule an update exactly at prayer time to stop the negative countdown
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
                    
                    // Cancel any existing alarm for this widget
                    alarmManager.cancel(pendingIntent)
                    // Set exact alarm
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC, nextPrayerTimeMillis, pendingIntent)
                    } else {
                        alarmManager.setExact(AlarmManager.RTC, nextPrayerTimeMillis, pendingIntent)
                    }
                    
                } else {
                    // Hide or reset if time has passed
                    setChronometer(R.id.chrono_next_prayer_time, android.os.SystemClock.elapsedRealtime(), "حان الآن", false)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
