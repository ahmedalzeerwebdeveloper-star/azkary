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
