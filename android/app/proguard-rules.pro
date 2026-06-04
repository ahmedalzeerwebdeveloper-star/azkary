# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep home_widget
-keep class es.antonborri.home_widget.** { *; }

# Keep our widget provider (referenced from manifest and via Class.forName)
-keep class com.ahmedalzeer.azkary.PrayerWidgetProvider { *; }
-keep class com.ahmedalzeer.azkary.MainActivity { *; }
-keep class com.ahmedalzeer.azkary.AlarmReceiver { *; }

# Keep Play Core (needed by Flutter deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
