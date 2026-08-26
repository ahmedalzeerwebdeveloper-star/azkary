import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/notification_service.dart';
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _playAdhan = true;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final playAdhan = await SettingsService.getPlayAdhan();
    final themeMode = await SettingsService.getThemeMode();
    if (mounted) {
      setState(() {
        _playAdhan = playAdhan;
        _themeMode = themeMode;
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
              ],
            ),
    );
  }
}
