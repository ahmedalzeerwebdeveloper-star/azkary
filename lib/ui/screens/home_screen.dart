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
  int _testTapCount = 0;

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
    _prayerCheckTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) return;

      PrayerTimesService.refreshIfDayChanged();

      final nextPrayer = PrayerTimesService.getNextPrayer();
      if (nextPrayer == null) return;

      final now = DateTime.now();
      final needsUpdate = _nextPrayer == null ||
          now.isAfter(_nextPrayer!.time) ||
          nextPrayer.name != _nextPrayer!.name;

      if (needsUpdate) {
        if (_nextPrayer != null && now.isAfter(_nextPrayer!.time) && now.difference(_nextPrayer!.time).inSeconds < 20) {
          String body;
          if (_nextPrayer!.name == 'الفجر') {
            body = 'الصلاة خير من النوم - قم ولبِّ نداء الله';
          } else {
            body = 'حان الآن موعد صلاة ${_nextPrayer!.name} - أقم صلاتك تسعد حياتك';
          }
          NotificationService.triggerPrayerNotification(_nextPrayer!.name, body);
        }
        await WidgetService.updateWidget();
        if (!mounted) return;
        setState(() {
          _nextPrayer = nextPrayer;
          _todayPrayers = PrayerTimesService.getTodayPrayers();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أذكاري'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surface,
            ],
          ),
        ),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                  _testTapCount++;
                  if (_testTapCount >= 5) {
                    _testTapCount = 0;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('إشعار فوري - تم التطوير بواسطة أحمد علي الزير'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    NotificationService.testNotification();
                  }
                  Future.delayed(const Duration(seconds: 5), () {
                    _testTapCount = 0;
                  });
                },
                onLongPress: () {
                  _testTapCount = 0;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('اختبار الإشعار المجدول... انتظر 15 ثانية'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                  NotificationService.scheduleDebugTimerTest();
                },
                child: Text(
                  'Ahmed Alzeer',
                  style: TextStyle(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerHeader() {
    if (_isLoadingLocation) {
      return Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_nextPrayer == null) {
      return Container(
        height: 220,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: const Center(child: Text('يرجى تفعيل الموقع لمعرفة أوقات الصلاة', style: TextStyle(color: AppTheme.textPrimary))),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _todayPrayers.map((prayer) {
                final isNext = prayer.name == _nextPrayer!.name;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Text(
                        prayer.name,
                        style: TextStyle(
                          color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.6),
                          fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('hh:mm a').format(prayer.time),
                        style: TextStyle(
                          color: isNext ? Colors.white : Colors.white.withValues(alpha: 0.6),
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
        return Icons.flutter_dash_rounded;
      case 'bed':
        return Icons.bed_rounded;
      case 'quran':
        return Icons.auto_stories_rounded;
      case 'pray':
        return Icons.self_improvement_rounded;
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
  Duration _timeUntilNextPrayer = Duration.zero;

  @override
  void initState() {
    super.initState();
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
        setState(() => _timeUntilNextPrayer = Duration.zero);
      } else {
        setState(() => _timeUntilNextPrayer = widget.nextPrayer!.time.difference(now));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_timeUntilNextPrayer),
      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final IconData iconData;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
