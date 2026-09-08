import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quran_models.dart';

class QuranService {
  static List<SurahModel>? _surahs;
  static List<JuzModel>? _juzs;
  static Map<String, dynamic>? _rawTafsirData;
  static Map<String, dynamic>? _rawBoundsData;

  static const String _lastPageKey = 'quran_last_read_page';
  static const String _bookmarksKey = 'quran_bookmarked_pages';

  static Future<List<SurahModel>> getSurahs() async {
    if (_surahs != null) return _surahs!;
    final jsonStr = await rootBundle.loadString('assets/quran_surahs.json');
    final List<dynamic> list = json.decode(jsonStr);
    _surahs = list.map((e) => SurahModel.fromJson(e as Map<String, dynamic>)).toList();
    return _surahs!;
  }

  static Future<List<JuzModel>> getJuzs() async {
    if (_juzs != null) return _juzs!;
    final jsonStr = await rootBundle.loadString('assets/quran_juzs.json');
    final List<dynamic> list = json.decode(jsonStr);
    _juzs = list.map((e) => JuzModel.fromJson(e as Map<String, dynamic>)).toList();
    return _juzs!;
  }

  static Future<PageTafsirModel?> getPageTafsir(int page) async {
    if (_rawTafsirData == null) {
      final jsonStr = await rootBundle.loadString('assets/quran_tafsir.json');
      _rawTafsirData = json.decode(jsonStr) as Map<String, dynamic>;
    }
    final pageData = _rawTafsirData?[page.toString()];
    if (pageData == null) return null;
    return PageTafsirModel.fromJson(pageData as Map<String, dynamic>);
  }

  static Future<List<AyahBoundModel>> getPageAyahBounds(int page) async {
    if (_rawBoundsData == null) {
      final jsonStr = await rootBundle.loadString('assets/quran_ayah_bounds.json');
      _rawBoundsData = json.decode(jsonStr) as Map<String, dynamic>;
    }
    final list = _rawBoundsData?[page.toString()] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => AyahBoundModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<VerseTafsirModel?> getSingleAyahTafsir(int sura, int aya, int page) async {
    final pageTafsir = await getPageTafsir(page);
    if (pageTafsir == null) return null;
    for (final v in pageTafsir.verses) {
      if (v.sura == sura && v.aya == aya) {
        return v;
      }
    }
    return null;
  }

  static Future<int> getLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPageKey) ?? 1;
  }

  static Future<void> saveLastReadPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPageKey, page);
  }

  static Future<Set<int>> getBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    return list.map((e) => int.tryParse(e) ?? 1).toSet();
  }

  static Future<bool> toggleBookmark(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getBookmarks();
    final isBookmarked = bookmarks.contains(page);
    if (isBookmarked) {
      bookmarks.remove(page);
    } else {
      bookmarks.add(page);
    }
    await prefs.setStringList(
      _bookmarksKey,
      bookmarks.map((e) => e.toString()).toList(),
    );
    return !isBookmarked;
  }

  static Future<bool> isBookmarked(int page) async {
    final bookmarks = await getBookmarks();
    return bookmarks.contains(page);
  }
}
