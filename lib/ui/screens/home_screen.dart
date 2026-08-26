import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../data/repositories/adhkar_data.dart';
import '../../core/services/location_service.dart';
import '../../core/services/prayer_times_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dhikr_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isLoadingLocation = true;
  PrayerData? _nextPrayer;
  List<PrayerData> _todayPrayers = [];
  Timer? _prayerCheckTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPrayerTimes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prayerCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshWidget();
    }
  }

  Future<void> _refreshWidget() async {
    await WidgetService.updateWidget();
    if (mounted) {
      setState(() {
        _todayPrayers = PrayerTimesService.getTodayPrayers();
        _nextPrayer = PrayerTimesService.getNextPrayer();
      });
    }
  }

  Future<void> _initPrayerTimes() async {
    try {
      await Permission.notification.request().timeout(const Duration(seconds: 5));
      await Permission.scheduleExactAlarm.request().timeout(const Duration(seconds: 3));

      var position = await LocationService.getCurrentPosition().timeout(const Duration(seconds: 8));
      position ??= Position(
        latitude: 30.0444,
        longitude: 31.2357,
        timestamp: DateTime.now(),
        accuracy: 100.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      PrayerTimesService.init(position);

      await WidgetService.updateWidget().timeout(const Duration(seconds: 8));
      await NotificationService.schedulePrayerNotifications();

      if (mounted) {
        setState(() {
          _todayPrayers = PrayerTimesService.getTodayPrayers();
          _nextPrayer = PrayerTimesService.getNextPrayer();
        });
        _startPrayerCheck();
      }
    } catch (e) {
      debugPrint('Error initializing prayer times: $e');
      if (mounted) {
        setState(() {
          _todayPrayers = PrayerTimesService.getTodayPrayers();
          _nextPrayer = PrayerTimesService.getNextPrayer();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _startPrayerCheck() {
    _prayerCheckTimer?.cancel();
    
    final nextPrayer = PrayerTimesService.getNextPrayer();
    if (nextPrayer == null) return;

    final now = DateTime.now();
    final durationUntilNext = nextPrayer.time.difference(now);

    // Schedule timer to trigger right at prayer time (or in 10 minutes max to stay fresh)
    final delay = durationUntilNext.isNegative 
        ? const Duration(seconds: 5)
        : (durationUntilNext > const Duration(minutes: 10) 
            ? const Duration(minutes: 10) 
            : durationUntilNext + const Duration(seconds: 1));

    _prayerCheckTimer = Timer(delay, () async {
      if (!mounted) return;

      PrayerTimesService.refreshIfDayChanged();
      final updatedNextPrayer = PrayerTimesService.getNextPrayer();

      if (updatedNextPrayer != null && _nextPrayer != null && 
          (updatedNextPrayer.name != _nextPrayer!.name || updatedNextPrayer.time != _nextPrayer!.time)) {
        
        String body = updatedNextPrayer.name == 'الفجر'
            ? 'الصلاة خير من النوم - قم ولبِّ نداء الله'
            : 'حان الآن موعد صلاة ${updatedNextPrayer.name} - أقم صلاتك تسعد حياتك';

        NotificationService.triggerPrayerNotification(updatedNextPrayer.name, body);
        await WidgetService.updateWidget();

        if (mounted) {
          setState(() {
            _nextPrayer = updatedNextPrayer;
            _todayPrayers = PrayerTimesService.getTodayPrayers();
          });
        }
      }
      _startPrayerCheck(); // Schedule next check
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكاري'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            _buildPrayerHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: AdhkarData.categories.length,
                  itemBuilder: (context, index) {
                    final category = AdhkarData.categories[index];
                    return _CategoryCard(
                      title: category.title,
                      iconData: _getIconForCategory(category.icon),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DhikrScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerHeader() {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;

    if (_isLoadingLocation) {
      return Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
        ),
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_nextPrayer == null) {
      return Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
        ),
        child: Center(child: Text('يرجى تفعيل الموقع لمعرفة أوقات الصلاة', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))),
      );
    }

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [const Color(0xFFC58B43), const Color(0xFFA66E28)]
              : [const Color(0xFF1E2D42), const Color(0xFF111A28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withValues(alpha: isLight ? 0.3 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? primaryColor.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  Text(
                    _nextPrayer!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'متبقي',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                  ),
                  _PrayerCountdown(nextPrayer: _nextPrayer),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _todayPrayers.map((prayer) {
                final isNext = prayer.name == _nextPrayer!.name;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isNext
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNext ? Colors.white.withValues(alpha: 0.6) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        prayer.name,
                        style: TextStyle(
                          color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(prayer.time).replaceAll('AM', 'ص').replaceAll('PM', 'م'),
                        style: TextStyle(
                          color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.7),
                          fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'moon':
        return Icons.nights_stay_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'beads':
        return Icons.auto_awesome_rounded;
      case 'bed':
        return Icons.bed_rounded;
      case 'quran':
        return Icons.auto_stories_rounded;
      case 'pray':
        return Icons.self_improvement_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'travel':
        return Icons.explore_rounded;
      case 'rain':
        return Icons.thunderstorm_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'water':
        return Icons.water_drop_rounded;
      case 'heart':
        return Icons.favorite_rounded;
      case 'shield':
        return Icons.shield_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class _PrayerCountdown extends StatefulWidget {
  final PrayerData? nextPrayer;

  const _PrayerCountdown({required this.nextPrayer});

  @override
  State<_PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<_PrayerCountdown> {
  Timer? _timer;
  late final ValueNotifier<Duration> _durationNotifier;

  @override
  void initState() {
    super.initState();
    _durationNotifier = ValueNotifier<Duration>(Duration.zero);
    _startCountdown();
  }

  @override
  void didUpdateWidget(_PrayerCountdown old) {
    super.didUpdateWidget(old);
    if (old.nextPrayer != widget.nextPrayer) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (!mounted) return;
    if (widget.nextPrayer != null) {
      final now = DateTime.now();
      if (now.isAfter(widget.nextPrayer!.time)) {
        _durationNotifier.value = Duration.zero;
      } else {
        _durationNotifier.value = widget.nextPrayer!.time.difference(now);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _durationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: _durationNotifier,
      builder: (context, duration, _) {
        return Text(
          _formatDuration(duration),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class _CategoryCard extends StatefulWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.iconData,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: primaryColor.withValues(alpha: isLight ? 0.2 : 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? primaryColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.18),
                      primaryColor.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.iconData,
                  size: 38,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
