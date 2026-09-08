package com.ahmedalzeer.azkary

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * BroadcastReceiver that fires every day around midnight (00:01)
 * to recalculate prayer times and update the widget without needing
 * to open the Flutter app.
 *
 * Self-rescheduling: after each trigger, it schedules itself for tomorrow.
 */
class MidnightReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "MidnightReceiver triggered – recalculating prayer times")
        try {
            // 1. Recalculate prayer times natively and save to SharedPreferences
            val success = PrayerCalculator.recalculateAndSave(context)
            Log.d(TAG, "Prayer recalculation ${if (success) "succeeded" else "failed"}")

            // 2. Trigger widget UI refresh
            WidgetUpdateScheduler.triggerUpdate(context)

            // 3. Re-schedule all prayer-based alarms with the new data
            val widgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            WidgetUpdateScheduler.scheduleAll(context, widgetPrefs)

        } catch (e: Exception) {
            Log.e(TAG, "Error in MidnightReceiver", e)
        }

        // 4. Always reschedule self for tomorrow midnight
        scheduleMidnightAlarm(context)
    }

    companion object {
        private const val TAG = "MidnightReceiver"
        private const val REQUEST_CODE_MIDNIGHT = 99_001
        private const val REQUEST_CODE_FALLBACK = 99_002

        /**
         * Schedule a midnight alarm for 00:01 tomorrow.
         * Uses setExactAndAllowWhileIdle for reliability during Doze mode.
         */
        fun scheduleMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val calendar = java.util.Calendar.getInstance().apply {
                add(java.util.Calendar.DAY_OF_YEAR, 1)
                set(java.util.Calendar.HOUR_OF_DAY, 0)
                set(java.util.Calendar.MINUTE, 1)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }

            val intent = Intent(context, MidnightReceiver::class.java)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(context, REQUEST_CODE_MIDNIGHT, intent, flags)

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent
                        )
                    } else {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                }
                Log.d(TAG, "Midnight alarm scheduled for ${calendar.time}")
            } catch (e: SecurityException) {
                alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                Log.w(TAG, "Fell back to inexact alarm", e)
            }

            // Also schedule a fallback alarm at 3:00 AM as a safety net
            scheduleFallbackAlarm(context)
        }

        /**
         * Fallback alarm at 3:00 AM. If the midnight alarm was missed
         * (battery optimization, Doze, etc.), this ensures the widget
         * still gets updated before Fajr.
         */
        private fun scheduleFallbackAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val calendar = java.util.Calendar.getInstance().apply {
                // If it's already past 3 AM today, schedule for tomorrow
                if (get(java.util.Calendar.HOUR_OF_DAY) >= 3) {
                    add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
                set(java.util.Calendar.HOUR_OF_DAY, 3)
                set(java.util.Calendar.MINUTE, 0)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }

            val intent = Intent(context, MidnightReceiver::class.java)
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            val pendingIntent = PendingIntent.getBroadcast(context, REQUEST_CODE_FALLBACK, intent, flags)

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent
                    )
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
                }
            } catch (e: SecurityException) {
                alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
            }
        }
    }
}
