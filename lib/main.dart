import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'ui/screens/home_screen.dart';

import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'core/services/settings_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error\n$stack');
    return true;
  };

  runApp(const MyApp());

  // Initialize non-critical services in background
  Future.microtask(() async {
    final savedMode = await SettingsService.getThemeMode();
    themeNotifier.value = savedMode;

    try {
      await NotificationService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }

    try {
      await WidgetService.init().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('WidgetService init error: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'أذكاري - الأذكار والأوراد',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ar', 'SA'), // Arabic RTL
          ],
          locale: const Locale('ar', 'SA'),
          localeResolutionCallback: (locale, supportedLocales) {
            return supportedLocales.first;
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}
