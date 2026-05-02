class PrayerTime {
  final String id;
  final String name;
  final String arabicName;
  final String description;
  final String icon;
  final int hour;
  final int minute;
  final List<String> psalms;
  final List<String> gospels;
  final String prayerText;
  PrayerTime({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.description,
    required this.icon,
    required this.hour,
    required this.minute,
    required this.psalms,
    required this.gospels,
    required this.prayerText,
  });
}