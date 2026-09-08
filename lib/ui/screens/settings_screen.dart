import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/widget_service.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _playAdhan = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isBatteryIgnored = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryStatus();
    }
  }

  Future<void> _checkBatteryStatus() async {
    final isIgnored = await WidgetService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() => _isBatteryIgnored = isIgnored);
    }
  }

  Future<void> _loadSettings() async {
    final playAdhan = await SettingsService.getPlayAdhan();
    final themeMode = await SettingsService.getThemeMode();
    final isIgnored = await WidgetService.isIgnoringBatteryOptimizations();
    if (mounted) {
      setState(() {
        _playAdhan = playAdhan;
        _themeMode = themeMode;
        _isBatteryIgnored = isIgnored;
        _loading = false;
      });
    }
  }

  Future<void> _onAdhanChanged(bool value) async {
    setState(() => _playAdhan = value);
    await SettingsService.setPlayAdhan(value);
    await NotificationService.schedulePrayerNotifications();
  }

  Future<void> _onThemeChanged(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    setState(() => _themeMode = newMode);
    themeNotifier.value = newMode;
    await SettingsService.setThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;
    final isDark = _themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'مظهر التطبيق',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: primaryColor,
                    ),
                    title: Text(isDark ? 'الوضع الداكن (Dark Mode)' : 'الوضع الفاتح (Light Mode)'),
                    subtitle: Text(
                      isDark ? 'تفعيل الألوان الداكنة المريحة للعين' : 'تفعيل الألوان الفاتحة المشرقة',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: isDark,
                    activeThumbColor: primaryColor,
                    onChanged: _onThemeChanged,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'تنبيهات الصلاة',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.notifications_active_rounded,
                      color: primaryColor,
                    ),
                    title: const Text('تشغيل نغمة الأذان'),
                    subtitle: Text(
                      _playAdhan
                          ? 'سيُشغَّل الأذان عند موعد كل صلاة'
                          : 'إشعار صامت بدون نغمة الأذان',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _playAdhan,
                    activeThumbColor: primaryColor,
                    onChanged: _onAdhanChanged,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'استقرار الويدجيت والتنبيهات',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: Icon(
                      _isBatteryIgnored ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                      color: _isBatteryIgnored ? Colors.green : Colors.amber,
                    ),
                    title: const Text('تحسين استهلاك البطارية'),
                    subtitle: Text(
                      _isBatteryIgnored
                          ? 'التطبيق معفى من قيود البطارية (الويدجيت والتنبيهات تعمل بأعلى دقة)'
                          : 'اضغط هنا للسماح للويدجيت بالعمل في الخلفية دون قيود',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: _isBatteryIgnored
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                        : TextButton(
                            onPressed: () async {
                              await WidgetService.requestIgnoreBatteryOptimizations();
                            },
                            child: const Text('تفعيل'),
                          ),
                    onTap: _isBatteryIgnored
                        ? null
                        : () async {
                            await WidgetService.requestIgnoreBatteryOptimizations();
                          },
                  ),
                ),
              ],
            ),
    );
  }
}
