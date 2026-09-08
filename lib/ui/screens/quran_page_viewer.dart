import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/quran_service.dart';
import '../../data/models/quran_models.dart';
import 'quran_index_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadMetadata();
    _checkBookmark();
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

  void _showTafsirBottomSheet() async {
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
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                final data = snapshot.data;
                if (data == null || data.verses.isEmpty) {
                  return const Center(
                    child: Text('لا يتوفر تفسير لهذه الصفحة حالياً'),
                  );
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

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('انتقال إلى صفحة', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo')),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'رقم الصفحة (1 - 604)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(controller.text);
                if (page != null && page >= 1 && page <= 604) {
                  Navigator.pop(ctx);
                  _jumpToPage(page);
                }
              },
              child: const Text('انتقال', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surahName = _pageToSurahMap[_currentPage] ?? '';
    final juzNumber = _pageToJuzMap[_currentPage] ?? 1;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF9F5),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView displaying Quran images (RTL)
            GestureDetector(
              onTap: _toggleControls,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: 604,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/quran_pages/$pageNum.png',
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
                    );
                  },
                ),
              ),
            ),

            // Top Header Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              top: _showControls ? 0 : -90,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

            // Bottom Navigation & Actions Bar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: _showControls ? 0 : -80,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      onPressed: _showTafsirBottomSheet,
                      icon: Icon(Icons.auto_stories, color: primaryColor, size: 20),
                      label: Text(
                        'التفسير',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.withValues(alpha: 0.3)),
                    TextButton.icon(
                      onPressed: _showPageJumpDialog,
                      icon: Icon(Icons.pin_outlined, color: primaryColor, size: 20),
                      label: Text(
                        'الصفحة $_currentPage',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
