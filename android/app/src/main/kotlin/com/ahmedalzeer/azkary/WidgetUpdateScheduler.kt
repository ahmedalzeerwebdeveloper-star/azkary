package com.ahmedalzeer.azkary

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

object WidgetUpdateScheduler {
    private const val WIDGET_ALARM_BASE = 50_000

    fun scheduleAll(context: Context, widgetData: SharedPreferences) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()

        val updateTimes = mutableListOf<Long>()
        val prayerKeys = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
        for (key in prayerKeys) {
            val millis = readMillis(widgetData, "${key}_millis")
            if (millis > now) updateTimes.add(millis + 5_000)
        }

        val tomorrowFajr = readMillis(widgetData, "tomorrow_fajr_millis")
        if (tomorrowFajr > now) updateTimes.add(tomorrowFajr + 5_000)

        val calendar = java.util.Calendar.getInstance().apply {
            add(java.util.Calendar.DAY_OF_YEAR, 1)
            set(java.util.Calendar.HOUR_OF_DAY, 0)
            set(java.util.Calendar.MINUTE, 1)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }
        if (calendar.timeInMillis > now) updateTimes.add(calendar.timeInMillis)

        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
        val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
        if (widgetIds.isEmpty()) return

        for (i in 0 until 10) {
            cancelAlarm(context, alarmManager, WIDGET_ALARM_BASE + i)
        }

        updateTimes.sorted().distinct().take(10).forEachIndexed { index, triggerAt ->
            scheduleAlarm(context, alarmManager, widgetIds, WIDGET_ALARM_BASE + index, triggerAt)
        }
    }

    fun triggerUpdate(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
        val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
        if (widgetIds.isEmpty()) return

        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        context.sendBroadcast(intent)
    }

    fun readMillis(data: SharedPreferences, key: String): Long {
        return try {
            data.getLong(key, 0L)
        } catch (_: ClassCastException) {
            try {
                data.getInt(key, 0).toLong()
            } catch (_: ClassCastException) {
                data.getString(key, "0")?.toLongOrNull() ?: 0L
            }
        }
    }

    private fun scheduleAlarm(
        context: Context,
        alarmManager: AlarmManager,
        widgetIds: IntArray,
        requestCode: Int,
        triggerAtMillis: Long
    ) {
        val intent = Intent(context, PrayerWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, widgetIds)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (_: SecurityException) {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
        }
    }

    private fun cancelAlarm(context: Context, alarmManager: AlarmManager, requestCode: Int) {
        val intent = Intent(context, PrayerWidgetProvider::class.java)
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, flags)
        alarmManager.cancel(pendingIntent)
    }
}
