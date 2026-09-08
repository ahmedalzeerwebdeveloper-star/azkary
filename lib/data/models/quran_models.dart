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
