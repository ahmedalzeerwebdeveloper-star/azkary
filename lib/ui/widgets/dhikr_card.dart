import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../data/models/dhikr_model.dart';
import '../../core/services/prayer_times_service.dart';

class DhikrCard extends StatefulWidget {
  final Dhikr dhikr;
  final VoidCallback? onCompleted;

  const DhikrCard({super.key, required this.dhikr, this.onCompleted});

  @override
  State<DhikrCard> createState() => _DhikrCardState();
}

class _DhikrCardState extends State<DhikrCard> {
  late int remainingCount;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    int initialCount = widget.dhikr.count;
    
    // Dynamic count for specific dhikr based on time (Fajr/Maghrib)
    if (widget.dhikr.text.contains('يُحيـي وَيُمـيتُ وهُوَ على كُلّ شيءٍ قدير')) {
      final now = DateTime.now();
      final prayers = PrayerTimesService.getTodayPrayers();
      
      if (prayers.isNotEmpty) {
        DateTime? fajr, dhuhr, maghrib, isha;
        for (var p in prayers) {
          if (p.name == 'الفجر') fajr = p.time;
          if (p.name == 'الظهر') dhuhr = p.time;
          if (p.name == 'المغرب') maghrib = p.time;
          if (p.name == 'العشاء') isha = p.time;
        }
        
        bool isFajrPeriod = fajr != null && dhuhr != null && now.isAfter(fajr) && now.isBefore(dhuhr);
        bool isMaghribPeriod = maghrib != null && isha != null && now.isAfter(maghrib) && now.isBefore(isha);
        
        if (isFajrPeriod || isMaghribPeriod) {
          initialCount = 10;
        } else {
          initialCount = 1;
        }
      } else {
        // Fallback if prayer times aren't loaded yet
        int hour = now.hour;
        if ((hour >= 4 && hour <= 9) || (hour >= 15 && hour <= 19)) {
          initialCount = 10;
        } else {
          initialCount = 1;
        }
      }
    }
    
    remainingCount = initialCount;
  }

  void _onTap() {
    if (remainingCount > 0) {
      setState(() => _isPressed = true);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isPressed = false);
      });
      setState(() {
        remainingCount--;
      });
      if (remainingCount == 0) {
        try { HapticFeedback.heavyImpact(); } catch (_) {}
        widget.onCompleted?.call();
      } else {
        try { HapticFeedback.lightImpact(); } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = remainingCount == 0;

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.dhikr.reference != null) ...[
                        Text(
                          widget.dhikr.reference!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        widget.dhikr.text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isCompleted ? AppTheme.textSecondary : AppTheme.textPrimary,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.dhikr.description != null && widget.dhikr.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.star_border_rounded, color: AppTheme.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.dhikr.description!,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: isCompleted ? 1.0 : (widget.dhikr.count - remainingCount) / widget.dhikr.count,
                          strokeWidth: 6,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? AppTheme.primary : AppTheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 40)
                                : Text(
                                    '$remainingCount',
                                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
