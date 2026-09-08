class SurahModel {
  final int id;
  final String nameAr;
  final String nameSimple;
  final String revelationPlace;
  final int versesCount;
  final int startPage;
  final int endPage;

  const SurahModel({
    required this.id,
    required this.nameAr,
    required this.nameSimple,
    required this.revelationPlace,
    required this.versesCount,
    required this.startPage,
    required this.endPage,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      nameSimple: json['name_simple'] as String,
      revelationPlace: json['revelation_place'] as String,
      versesCount: json['verses_count'] as int,
      startPage: json['start_page'] as int,
      endPage: json['end_page'] as int,
    );
  }
}

class JuzModel {
  final int id;
  final String nameAr;
  final int versesCount;
  final int startPage;

  const JuzModel({
    required this.id,
    required this.nameAr,
    required this.versesCount,
    required this.startPage,
  });

  factory JuzModel.fromJson(Map<String, dynamic> json) {
    return JuzModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      versesCount: json['verses_count'] as int,
      startPage: json['start_page'] as int,
    );
  }
}

class VerseTafsirModel {
  final int sura;
  final int aya;
  final String key;
  final String tafsir;

  const VerseTafsirModel({
    required this.sura,
    required this.aya,
    required this.key,
    required this.tafsir,
  });

  factory VerseTafsirModel.fromJson(Map<String, dynamic> json) {
    return VerseTafsirModel(
      sura: json['sura'] as int,
      aya: json['aya'] as int,
      key: json['key'] as String,
      tafsir: json['tafsir'] as String? ?? '',
    );
  }
}

class PageTafsirModel {
  final int page;
  final int juz;
  final List<int> suras;
  final List<VerseTafsirModel> verses;

  const PageTafsirModel({
    required this.page,
    required this.juz,
    required this.suras,
    required this.verses,
  });

  factory PageTafsirModel.fromJson(Map<String, dynamic> json) {
    return PageTafsirModel(
      page: json['page'] as int,
      juz: json['juz'] as int,
      suras: (json['suras'] as List<dynamic>).map((e) => e as int).toList(),
      verses: (json['verses'] as List<dynamic>)
          .map((e) => VerseTafsirModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AyahBoundModel {
  final int sura;
  final int aya;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final List<List<List<double>>> polygons;

  const AyahBoundModel({
    required this.sura,
    required this.aya,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.polygons = const [],
  });

  factory AyahBoundModel.fromJson(Map<String, dynamic> json) {
    List<List<List<double>>> parsedPolygons = [];
    if (json['polygons'] != null) {
      final rawPolys = json['polygons'] as List<dynamic>;
      for (final p in rawPolys) {
        final pts = (p as List<dynamic>).map((pt) {
          final pair = pt as List<dynamic>;
          return [(pair[0] as num).toDouble(), (pair[1] as num).toDouble()];
        }).toList();
        if (pts.isNotEmpty) {
          parsedPolygons.add(pts);
        }
      }
    }

    return AyahBoundModel(
      sura: json['sura'] as int,
      aya: json['aya'] as int,
      minX: (json['min_x'] as num).toDouble(),
      maxX: (json['max_x'] as num).toDouble(),
      minY: (json['min_y'] as num).toDouble(),
      maxY: (json['max_y'] as num).toDouble(),
      polygons: parsedPolygons,
    );
  }

  /// Checks if point (x, y) is inside the ayah in 456x672 page coordinates
  bool containsPoint(double x, double y) {
    // Fast bounding box check with slight touch tolerance (±4px)
    if (x < (minX - 4) || x > (maxX + 4) || y < (minY - 4) || y > (maxY + 4)) {
      return false;
    }

    // If polygons are available, test each line segment polygon
    if (polygons.isNotEmpty) {
      for (final poly in polygons) {
        if (_pointInPolygon(x, y, poly)) {
          return true;
        }
      }
      return false;
    }

    return true;
  }

  static bool _pointInPolygon(double x, double y, List<List<double>> poly) {
    final n = poly.length;
    if (n < 3) return false;
    bool inside = false;
    double p1x = poly[0][0];
    double p1y = poly[0][1];

    for (int i = 0; i <= n; i++) {
      final p2x = poly[i % n][0];
      final p2y = poly[i % n][1];

      if (y > (p1y < p2y ? p1y : p2y)) {
        if (y <= (p1y > p2y ? p1y : p2y)) {
          if (x <= (p1x > p2x ? p1x : p2x)) {
            if (p1y != p2y) {
              final xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x;
              if (p1x == p2x || x <= xinters) {
                inside = !inside;
              }
            }
          }
        }
      }
      p1x = p2x;
      p1y = p2y;
    }
    return inside;
  }
}
