class Dhikr {
  final String text;
  final int count;
  final String? reference; // e.g. "سورة البقرة"
  final String? description; // e.g. "من قالها حين يصبح..."

  const Dhikr({
    required this.text,
    required this.count,
    this.reference,
    this.description,
  });

  int getTargetCount() {
    if (text.contains('يُحيـي وَيُمـيتُ وهُوَ على كُلّ شيءٍ قدير')) {
      final now = DateTime.now();
      final hour = now.hour;
      // After Fajr (approx 4-9) or Maghrib (approx 15-19)
      if ((hour >= 4 && hour <= 9) || (hour >= 15 && hour <= 19)) {
        return 10;
      }
      return 1;
    }
    return count;
  }
}

class DhikrCategory {
  final String id;
  final String title;
  final String icon;
  final List<Dhikr> adhkar;

  const DhikrCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.adhkar,
  });
}
