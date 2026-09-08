import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/audio_service.dart';
import '../../data/models/quran_models.dart';
import 'quran_index_screen.dart';

enum QuranColorFilterMode {
  normal,
  sepia,
  dark,
}

class QuranPageViewer extends StatefulWidget {
  final int initialPage;

  const QuranPageViewer({
    super.key,
    this.initialPage = 1,
  });

  @override
  State<QuranPageViewer> createState() => _QuranPageViewerState();
}

class _QuranPageViewerState extends State<QuranPageViewer> {
  late PageController _pageController;
  late int _currentPage;
  bool _showControls = false;
  bool _isBookmarked = false;
  Map<int, String> _pageToSurahMap = {};
  Map<int, int> _pageToJuzMap = {};

  // Interactive Ayah bounds
  final Map<int, List<AyahBoundModel>> _cachedBounds = {};
  
  // Reading mode filter
  QuranColorFilterMode _colorMode = QuranColorFilterMode.normal;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadMetadata();
    _checkBookmark();
    _loadBoundsForPage(_currentPage);
    QuranService.saveLastReadPage(_currentPage);
  }

  Future<void> _loadMetadata() async {
    final surahs = await QuranService.getSurahs();
    final juzs = await QuranService.getJuzs();

    final surahMap = <int, String>{};
    for (final s in surahs) {
      for (int p = s.startPage; p <= s.endPage; p++) {
        surahMap[p] = s.nameAr;
      }
    }

    final juzMap = <int, int>{};
    for (int i = 0; i < juzs.length; i++) {
      final cur = juzs[i];
      final nextStart = (i + 1 < juzs.length) ? juzs[i + 1].startPage : 605;
      for (int p = cur.startPage; p < nextStart; p++) {
        juzMap[p] = cur.id;
      }
    }

    if (mounted) {
      setState(() {
        _pageToSurahMap = surahMap;
        _pageToJuzMap = juzMap;
      });
    }
  }

  Future<void> _loadBoundsForPage(int page) async {
    if (_cachedBounds.containsKey(page)) return;
    final bounds = await QuranService.getPageAyahBounds(page);
    if (mounted) {
      setState(() {
        _cachedBounds[page] = bounds;
      });
    }
  }

  Future<void> _checkBookmark() async {
    final bookmarked = await QuranService.isBookmarked(_currentPage);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  void _onPageChanged(int index) {
    final newPage = index + 1;
    setState(() {
      _currentPage = newPage;
    });
    _checkBookmark();
    _loadBoundsForPage(newPage);
    QuranService.saveLastReadPage(newPage);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _jumpToPage(int page) {
    final target = page.clamp(1, 604);
    _pageController.jumpToPage(target - 1);
  }

  void _handlePageTap(TapUpDetails details, BoxConstraints constraints) {
    final bounds = _cachedBounds[_currentPage] ?? [];
    if (bounds.isEmpty) {
      _toggleControls();
      return;
    }

    final localPos = details.localPosition;
    // Map local coordinates (based on 456 x 672 standard page viewBox)
    final renderWidth = constraints.maxWidth;
    final renderHeight = constraints.maxHeight;

    const sourceWidth = 456.0;
    const sourceHeight = 672.0;

    // Aspect ratio fit calculation (BoxFit.contain)
    final scale = (renderWidth / sourceWidth < renderHeight / sourceHeight)
        ? renderWidth / sourceWidth
        : renderHeight / sourceHeight;

    final displayedWidth = sourceWidth * scale;
    final displayedHeight = sourceHeight * scale;

    final offsetX = (renderWidth - displayedWidth) / 2;
    final offsetY = (renderHeight - displayedHeight) / 2;

    final imageX = (localPos.dx - offsetX) / scale;
    final imageY = (localPos.dy - offsetY) / scale;

    if (imageX < 0 || imageX > sourceWidth || imageY < 0 || imageY > sourceHeight) {
      _toggleControls();
      return;
    }

    // Direct image coordinate check using pre-transformed 456x672 page coordinates
    AyahBoundModel? foundAyah;
    for (final b in bounds) {
      if (b.containsPoint(imageX, imageY)) {
        foundAyah = b;
        break;
      }
    }

    if (foundAyah != null) {
      HapticFeedback.selectionClick();
      _showSingleAyahTafsirModal(foundAyah);
    } else {
      _toggleControls();
    }
  }

  void _showSingleAyahTafsirModal(AyahBoundModel ayahBound) async {
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahName = _pageToSurahMap[_currentPage] ?? '';

    final tafsir = await QuranService.getSingleAyahTafsir(
      ayahBound.sura,
      ayahBound.aya,
      _currentPage,
    );

    final hasInternet = await QuranAudioService.hasInternetConnection();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isAudioPlaying = QuranAudioService.isAyahPlaying(ayahBound.sura, ayahBound.aya);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$surahName • الآية ${ayahBound.aya}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (tafsir != null && tafsir.tafsir.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              tooltip: 'نسخ التفسير',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                  text: 'سورة $surahName - الآية ${ayahBound.aya}:\n${tafsir.tafsir}',
                                ));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ تفسير الآية', style: TextStyle(fontFamily: 'Cairo')),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // زر الاستماع لتلاوة الآية - يظهر فقط في حال وجود اتصال بالإنترنت
                  if (hasInternet) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (isAudioPlaying) {
                            await QuranAudioService.stop();
                            setModalState(() {});
                          } else {
                            await QuranAudioService.playAyah(
                              sura: ayahBound.sura,
                              aya: ayahBound.aya,
                              onStateChanged: (_) {
                                if (context.mounted) {
                                  setModalState(() {});
                                }
                              },
                            );
                            setModalState(() {});
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAudioPlaying
                                ? primaryColor.withValues(alpha: 0.18)
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAudioPlaying
                                  ? primaryColor
                                  : primaryColor.withValues(alpha: 0.25),
                              width: isAudioPlaying ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isAudioPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                                  color: isDark ? Colors.black : Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAudioPlaying ? 'جاري الاستماع للآية...' : 'استمع لتلاوة الآية',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isAudioPlaying
                                            ? primaryColor
                                            : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                                      ),
                                    ),
                                    Text(
                                      'بصوت الشيخ عبدالباسط عبدالصمد (مرتل)',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isAudioPlaying ? Icons.volume_up_rounded : Icons.headphones_rounded,
                                color: primaryColor.withValues(alpha: 0.8),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.40,
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        (tafsir != null && tafsir.tafsir.isNotEmpty)
                            ? tafsir.tafsir
                            : 'جاري تحميل التفسير أو لا يتوفر تفسير حالياً.',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          height: 1.85,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      QuranAudioService.stop();
    });
  }

  void _showFullPageTafsir() {
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = Theme.of(context).cardTheme.color ?? AppTheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<PageTafsirModel?>(
              future: QuranService.getPageTafsir(_currentPage),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final data = snapshot.data;
                if (data == null || data.verses.isEmpty) {
                  return const Center(child: Text('لا يتوفر تفسير لهذه الصفحة حالياً'));
                }

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book, color: primaryColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'التفسير الميسر - صفحة $_currentPage',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        itemCount: data.verses.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final v = data.verses[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'الآية ${v.aya}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                v.tafsir.isNotEmpty ? v.tafsir : 'لا يوجد تفسير متوفر لهذه الآية',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  height: 1.8,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showColorFilterDialog() {
    final primaryColor = Theme.of(context).primaryColor;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('وضع قراءة المصحف', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('الوضع الطبيعي', style: TextStyle(fontFamily: 'Cairo')),
                trailing: _colorMode == QuranColorFilterMode.normal ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  setState(() => _colorMode = QuranColorFilterMode.normal);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('الوضع المريح (ورق كلاسيكي)', style: TextStyle(fontFamily: 'Cairo')),
                trailing: _colorMode == QuranColorFilterMode.sepia ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  setState(() => _colorMode = QuranColorFilterMode.sepia);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('الوضع الليلي الداكن', style: TextStyle(fontFamily: 'Cairo')),
                trailing: _colorMode == QuranColorFilterMode.dark ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  setState(() => _colorMode = QuranColorFilterMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _applyColorFilter(Widget child) {
    switch (_colorMode) {
      case QuranColorFilterMode.normal:
        return child;
      case QuranColorFilterMode.sepia:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.90, 0.05, 0.05, 0, 15,
            0.05, 0.85, 0.05, 0, 15,
            0.05, 0.05, 0.75, 0, 0,
            0,    0,    0,    1, 0,
          ]),
          child: child,
        );
      case QuranColorFilterMode.dark:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            -1,  0,  0, 0, 255,
             0, -1,  0, 0, 255,
             0,  0, -1, 0, 255,
             0,  0,  0, 1, 0,
          ]),
          child: child,
        );
    }
  }

  @override
  void dispose() {
    QuranAudioService.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahName = _pageToSurahMap[_currentPage] ?? '';
    final juzNumber = _pageToJuzMap[_currentPage] ?? 1;

    Color screenBgColor;
    if (_colorMode == QuranColorFilterMode.dark) {
      screenBgColor = Colors.black;
    } else if (_colorMode == QuranColorFilterMode.sepia) {
      screenBgColor = const Color(0xFFF7F3E8);
    } else {
      screenBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFBF9F5);
    }

    return Scaffold(
      backgroundColor: screenBgColor,
      body: Stack(
        children: [
          // PageView displaying Quran images (RTL) with interactive touch & pinch-zoom (Full Screen)
          Positioned.fill(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 604,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapUp: (details) => _handlePageTap(details, constraints),
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 3.0,
                          child: Center(
                            child: _applyColorFilter(
                              Image.asset(
                                'assets/quran_pages/$pageNum.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 60, color: Colors.grey.shade400),
                                        const SizedBox(height: 12),
                                        Text(
                                          'صفحة $pageNum غير متوفرة',
                                          style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Top Header Bar (Floating overlay with SafeArea)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showControls ? 0 : -140,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.surface : AppTheme.lightSurface).withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: primaryColor,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              surahName.isNotEmpty ? surahName : 'المصحف الشريف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Text(
                              'الجزء $juzNumber • صفحة $_currentPage',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.palette_outlined),
                        color: primaryColor,
                        tooltip: 'وضع القراءة',
                        onPressed: _showColorFilterDialog,
                      ),
                      IconButton(
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? primaryColor : null,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final res = await QuranService.toggleBookmark(_currentPage);
                          if (!mounted) return;
                          setState(() {
                            _isBookmarked = res;
                          });
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                res ? 'تمت إضافة العلامة لصفحة $_currentPage' : 'تم حذف العلامة',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.list_alt),
                        color: primaryColor,
                        onPressed: () async {
                          final selectedPage = await Navigator.push<int>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuranIndexScreen(currentPage: _currentPage),
                            ),
                          );
                          if (selectedPage != null) {
                            _jumpToPage(selectedPage);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom Navigation & Fast Page Slider Bar (Floating overlay with SafeArea)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showControls ? 0 : -160,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? AppTheme.surface : AppTheme.lightSurface).withValues(alpha: 0.95),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fast Page Slider
                      Row(
                        children: [
                          Text(
                            '1',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: primaryColor,
                                thumbColor: primaryColor,
                                inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: _currentPage.toDouble(),
                                min: 1,
                                max: 604,
                                onChanged: (val) {
                                  _jumpToPage(val.round());
                                },
                              ),
                            ),
                          ),
                          Text(
                            '604',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: _showFullPageTafsir,
                            icon: Icon(Icons.auto_stories, color: primaryColor, size: 20),
                            label: Text(
                              'تفسير الصفحة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          Container(height: 20, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                          Text(
                            'اضغط على أي آية لعرض تفسيرها',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
