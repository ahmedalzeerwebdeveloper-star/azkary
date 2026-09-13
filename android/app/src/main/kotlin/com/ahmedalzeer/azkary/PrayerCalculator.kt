package com.ahmedalzeer.azkary

import android.content.Context
import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.*

data class PrayerTimes(
    val fajr: Long,
    val sunrise: Long,
    val dhuhr: Long,
    val asr: Long,
    val maghrib: Long,
    val isha: Long
)

object PrayerCalculator {

    // Math helpers
    private fun sinD(degrees: Double): Double = sin(Math.toRadians(degrees))
    private fun cosD(degrees: Double): Double = cos(Math.toRadians(degrees))
    private fun tanD(degrees: Double): Double = tan(Math.toRadians(degrees))
    private fun asinD(value: Double): Double = Math.toDegrees(asin(value))
    private fun acosD(value: Double): Double = Math.toDegrees(acos(value))
    private fun atanD(value: Double): Double = Math.toDegrees(atan(value))
    
    private fun fixAngle(angle: Double): Double {
        var a = angle - 360.0 * floor(angle / 360.0)
        a = if (a < 0) a + 360 else a
        return a
    }
    
    private fun fixHour(hour: Double): Double {
        var h = hour - 24.0 * floor(hour / 24.0)
        h = if (h < 0) h + 24 else h
        return h
    }

    fun calculatePrayerTimes(calendar: Calendar, latitude: Double, longitude: Double): PrayerTimes {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        val timezone = calendar.timeZone.getOffset(calendar.timeInMillis) / 3600000.0

        // 1. Julian Date
        var y = year
        var m = month
        if (m <= 2) {
            y -= 1
            m += 12
        }
        val a = floor(y / 100.0)
        val b = 2 - a + floor(a / 4.0)
        val jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + day + b - 1524.5

        val d = jd - 2451545.0 // Days since J2000

        // 2. Sun Position
        val g = fixAngle(357.529 + 0.98560028 * d)
        val q = fixAngle(280.459 + 0.98564736 * d)
        val l = fixAngle(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g))
        
        // Obliquity of the ecliptic
        val e = 23.439 - 0.00000036 * d
        
        // Sun declination
        val dec = asinD(sinD(e) * sinD(l))
        
        // Right ascension
        var ra = atanD(cosD(e) * sinD(l) / cosD(l))
        ra = fixAngle(ra)
        val raQuadrant = floor(ra / 90) * 90
        val lQuadrant = floor(l / 90) * 90
        ra += (lQuadrant - raQuadrant)
        ra /= 15.0
        
        // Equation of time
        val eqt = q / 15.0 - ra
        
        // 3. Transit Time
        val transit = 12 + timezone - longitude / 15.0 - eqt

        // 4. Hour Angle calculation function
        fun hourAngle(angle: Double, dec: Double, lat: Double): Double {
            val cosH = (sinD(angle) - sinD(lat) * sinD(dec)) / (cosD(lat) * cosD(dec))
            if (cosH > 1 || cosH < -1) return 0.0
            return acosD(cosH) / 15.0
        }

        // 5. Fajr (19.5 degrees)
        val fajrHA = hourAngle(-19.5, dec, latitude)
        val fajrTime = transit - fajrHA

        // 6. Sunrise (-0.833 degrees)
        val sunriseHA = hourAngle(-0.8333, dec, latitude)
        val sunriseTime = transit - sunriseHA

        // 7. Dhuhr
        val dhuhrTime = transit

        // 8. Asr (Shafi, shadow factor = 1)
        val asrAlt = Math.toDegrees(atan(1.0 / (1.0 + tanD(abs(latitude - dec)))))
        val asrHA = hourAngle(asrAlt, dec, latitude)
        val asrTime = transit + asrHA

        // 9. Maghrib (-0.833 degrees)
        val maghribHA = hourAngle(-0.8333, dec, latitude)
        val maghribTime = transit + maghribHA

        // 10. Isha (17.5 degrees)
        val ishaHA = hourAngle(-17.5, dec, latitude)
        val ishaTime = transit + ishaHA

        fun getMillis(timeHour: Double): Long {
            val h = fixHour(timeHour)
            val hrs = floor(h).toInt()
            val mins = floor((h - hrs) * 60.0).toInt()
            val secs = floor(((h - hrs) * 60.0 - mins) * 60.0).toInt()
            
            val cal = calendar.clone() as Calendar
            cal.set(Calendar.HOUR_OF_DAY, hrs)
            cal.set(Calendar.MINUTE, mins)
            cal.set(Calendar.SECOND, secs)
            cal.set(Calendar.MILLISECOND, 0)
            return cal.timeInMillis
        }

        return PrayerTimes(
            fajr = getMillis(fajrTime),
            sunrise = getMillis(sunriseTime),
            dhuhr = getMillis(dhuhrTime),
            asr = getMillis(asrTime),
            maghrib = getMillis(maghribTime),
            isha = getMillis(ishaTime)
        )
    }

    fun getLat(widgetPrefs: SharedPreferences, flutterPrefs: SharedPreferences): Double {
        try {
            if (widgetPrefs.contains("lat")) {
                val v = widgetPrefs.all["lat"]
                if (v is Double) return v
                if (v is Float) return v.toDouble()
                if (v is Long) return java.lang.Double.longBitsToDouble(v)
                if (v is String) {
                    val d = v.toDoubleOrNull()
                    if (d != null) return d
                }
            }
        } catch (_: Exception) {}

        var lat = 30.0444
        try {
            val all = flutterPrefs.all
            for ((key, value) in all) {
                if (key.endsWith("cached_lat")) {
                    if (value is Double) return value
                    if (value is Float) return value.toDouble()
                    if (value is Long) return java.lang.Double.longBitsToDouble(value)
                    if (value is String) {
                        val clean = value.removePrefix("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu")
                        val d = clean.toDoubleOrNull()
                        if (d != null) return d
                    }
                }
            }
        } catch (_: Exception) {}
        return lat
    }

    fun getLng(widgetPrefs: SharedPreferences, flutterPrefs: SharedPreferences): Double {
        try {
            if (widgetPrefs.contains("lng")) {
                val v = widgetPrefs.all["lng"]
                if (v is Double) return v
                if (v is Float) return v.toDouble()
                if (v is Long) return java.lang.Double.longBitsToDouble(v)
                if (v is String) {
                    val d = v.toDoubleOrNull()
                    if (d != null) return d
                }
            }
        } catch (_: Exception) {}

        var lng = 31.2357
        try {
            val all = flutterPrefs.all
            for ((key, value) in all) {
                if (key.endsWith("cached_lng")) {
                    if (value is Double) return value
                    if (value is Float) return value.toDouble()
                    if (value is Long) return java.lang.Double.longBitsToDouble(value)
                    if (value is String) {
                        val clean = value.removePrefix("VGhpcyBpcyB0aGUgcHJlZml4IGZvciBEb3VibGUu")
                        val d = clean.toDoubleOrNull()
                        if (d != null) return d
                    }
                }
            }
        } catch (_: Exception) {}
        return lng
    }

    fun recalculateAndSave(context: Context): Boolean {
        try {
            val widgetPrefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val lat = getLat(widgetPrefs, flutterPrefs)
            val lng = getLng(widgetPrefs, flutterPrefs)

            val calToday = Calendar.getInstance()
            val timesToday = calculatePrayerTimes(calToday, lat, lng)

            val calTomorrow = Calendar.getInstance()
            calTomorrow.add(Calendar.DAY_OF_YEAR, 1)
            val timesTomorrow = calculatePrayerTimes(calTomorrow, lat, lng)

            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.ENGLISH)
            val timeFormat = SimpleDateFormat("hh:mm a", Locale.ENGLISH)
            
            fun formatTime(millis: Long): String {
                val d = Date(millis)
                return timeFormat.format(d).replace("AM", "ص").replace("PM", "م")
            }

            val editor = widgetPrefs.edit()
            
            editor.putString("fajr", formatTime(timesToday.fajr))
            editor.putString("shurooq", formatTime(timesToday.sunrise))
            editor.putString("dhuhr", formatTime(timesToday.dhuhr))
            editor.putString("asr", formatTime(timesToday.asr))
            editor.putString("maghrib", formatTime(timesToday.maghrib))
            editor.putString("isha", formatTime(timesToday.isha))
            
            editor.putLong("fajr_millis", timesToday.fajr)
            editor.putLong("shurooq_millis", timesToday.sunrise)
            editor.putLong("dhuhr_millis", timesToday.dhuhr)
            editor.putLong("asr_millis", timesToday.asr)
            editor.putLong("maghrib_millis", timesToday.maghrib)
            editor.putLong("isha_millis", timesToday.isha)
            
            editor.putLong("tomorrow_fajr_millis", timesTomorrow.fajr)
            editor.putString("tomorrow_fajr_name", "الفجر")
            
            editor.putString("last_update_day", dateFormat.format(calToday.time))

            // Update city with current Arabic day name
            val arabicDays = arrayOf("الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت")
            val dayOfWeek = calToday.get(Calendar.DAY_OF_WEEK) // 1=Sunday, 7=Saturday
            val dayName = arabicDays[dayOfWeek - 1]
            
            val savedCity = widgetPrefs.getString("city_name", null)
            val cityName = if (!savedCity.isNullOrBlank()) {
                savedCity
            } else {
                val existingCity = widgetPrefs.getString("city", "المدينة") ?: "المدينة"
                if (existingCity.contains("،")) existingCity.substringAfter("،").trim() else existingCity
            }
            editor.putString("city", "$dayName، $cityName")

            // Calculate and save Hijri Date
            editor.putString("hijri", getHijriDate(calToday))
            
            editor.commit()
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    private fun getHijriDate(calendar: Calendar): String {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                val localDate = java.time.LocalDate.of(
                    calendar.get(Calendar.YEAR),
                    calendar.get(Calendar.MONTH) + 1,
                    calendar.get(Calendar.DAY_OF_MONTH)
                )
                val hijrahDate = java.time.chrono.HijrahDate.from(localDate)
                val hDay = hijrahDate.get(java.time.temporal.ChronoField.DAY_OF_MONTH)
                val hMonth = hijrahDate.get(java.time.temporal.ChronoField.MONTH_OF_YEAR)
                val hYear = hijrahDate.get(java.time.temporal.ChronoField.YEAR)
                val months = arrayOf(
                    "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادى الأولى", "جمادى الآخرة",
                    "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
                )
                val monthName = if (hMonth in 1..12) months[hMonth - 1] else months[0]
                return "$hDay $monthName $hYear"
            }
        } catch (_: Exception) {}

        var day = calendar.get(Calendar.DAY_OF_MONTH)
        var month = calendar.get(Calendar.MONTH) + 1
        var year = calendar.get(Calendar.YEAR)
        
        var m = month
        var y = year
        if (m < 3) {
            y -= 1
            m += 12
        }
        
        var a = floor(y / 100.0)
        var b = 2 - a + floor(a / 4.0)
        
        if (y < 1583) b = 0.0
        if (y == 1582) {
            if (m > 10) b = -10.0
            if (m == 10) {
                b = 0.0
                if (day > 4) b = -10.0
            }
        }
        
        val jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + day + b - 1524.5
        
        var z = jd - 1948084.0 // epochastro
        val cyc = floor(z / 10631.0)
        z -= 10631.0 * cyc
        val j = floor((z - (8.01 / 60.0)) / (10631.0 / 30.0))
        val iy = 30.0 * cyc + j
        z -= floor(j * (10631.0 / 30.0) + (8.01 / 60.0))
        var im = floor((z + 28.5001) / 29.5)
        if (im == 13.0) im = 12.0
        val id = z - floor(29.5001 * im - 29)
        
        val hYear = iy.toInt()
        val hMonth = im.toInt()
        val hDay = max(1, id.toInt())
        
        val months = arrayOf(
            "محرم", "صفر", "ربيع الأول", "ربيع الثاني", "جمادى الأولى", "جمادى الآخرة",
            "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"
        )
        
        val monthName = if (hMonth in 1..12) months[hMonth - 1] else months[0]
        
        return "$hDay $monthName $hYear"
    }
}
