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
  late final ValueNotifier<int> _remainingNotifier;
  late final ValueNotifier<bool> _isPressedNotifier;
  late final int _targetCount;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.dhikr.getTargetCount();
    _remainingNotifier = ValueNotifier<int>(_targetCount);
    _isPressedNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _remainingNotifier.dispose();
    _isPressedNotifier.dispose();
    super.dispose();
  }

  void _onTap() {
    if (_remainingNotifier.value > 0) {
      _isPressedNotifier.value = true;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) _isPressedNotifier.value = false;
      });

      _remainingNotifier.value--;

      if (_remainingNotifier.value == 0) {
        try { HapticFeedback.heavyImpact(); } catch (_) {}
        widget.onCompleted?.call();
      } else {
        try { HapticFeedback.lightImpact(); } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isPressedNotifier,
        builder: (context, isPressed, child) {
          return AnimatedScale(
            scale: isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: child,
          );
        },
        child: ValueListenableBuilder<int>(
          valueListenable: _remainingNotifier,
          builder: (context, remainingCount, _) {
            final bool isCompleted = remainingCount == 0;
            final double progress = _targetCount > 0
                ? (isCompleted ? 1.0 : (_targetCount - remainingCount) / _targetCount)
                : 1.0;

            final primaryColor = Theme.of(context).primaryColor;
            final cardColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isCompleted ? primaryColor.withValues(alpha: 0.1) : cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isCompleted ? primaryColor.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? primaryColor.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.2),
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
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            widget.dhikr.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: isCompleted
                                  ? Theme.of(context).textTheme.bodySmall?.color
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                              height: 1.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.dhikr.description != null && widget.dhikr.description!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.star_border_rounded, color: primaryColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.dhikr.description!,
                                      textAlign: TextAlign.start,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        width: 110,
                        height: 110,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: primaryColor.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted ? primaryColor : cardColor,
                                border: Border.all(
                                  color: isCompleted
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : primaryColor.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: isCompleted ? 0.4 : 0.2),
                                    blurRadius: isCompleted ? 20 : 12,
                                    spreadRadius: isCompleted ? 3 : 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 44)
                                    : Text(
                                        '$remainingCount',
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 34,
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
            );
          },
        ),
      ),
    );
  }
}
