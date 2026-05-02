import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';

class PrayerDay {
  final int dayNumber;
  final String title;
  final String verse;
  final String reflection;
  final String prayer;
  final String encouragement;
  bool isCompleted;

  PrayerDay({
    required this.dayNumber,
    required this.title,
    required this.verse,
    required this.reflection,
    required this.prayer,
    required this.encouragement,
    this.isCompleted = false,
  });
}

class PrayerRoadModel extends ChangeNotifier {
  static const String _completedDaysKey = 'prayer_road_completed_days_set';
  static const String _currentDayKey = 'prayer_road_current_day';
  static const String _notificationsEnabledKey =
      'prayer_road_notifications_enabled';
  static const String _openDaysKey = 'prayer_road_open_days_set';
  static const String _nextDayOpenTimeKey = 'prayer_road_next_day_open_time';
  static const String _missedDaysKey = 'prayer_road_missed_days_set';

  int _currentDay = 1;
  bool _notificationsEnabled = true;
  Set<int> _completedDays = {};
  Set<int> _openDays = {1};
  Set<int> _missedDays = {}; // <-- أضف هذا السطر
  DateTime? _nextDayOpenTime;
  List<PrayerDay> _allDays = [];
  final AudioService _audioService = AudioService();

  int get currentDay => _currentDay;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isCurrentDayCompleted => _completedDays.contains(_currentDay);
  int get completedDaysCount => _completedDays.length;
  int get openDaysCount => _openDays.length;
  double get totalProgress => _completedDays.length / 60;
  Set<int> get completedDays => _completedDays;
  Set<int> get openDays => _openDays;
  Set<int> get missedDays => _missedDays; // <-- أضف هذا السطر
  DateTime? get nextDayOpenTime => _nextDayOpenTime;

  bool isDayOpen(int dayNumber) => _openDays.contains(dayNumber);
  bool isDayCompleted(int dayNumber) => _completedDays.contains(dayNumber);
  bool canAccessDay(int dayNumber) => _openDays.contains(dayNumber);

  Duration? get timeRemainingToOpenNextDay {
    if (_nextDayOpenTime == null) return null;
    final now = DateTime.now();
    final remaining = _nextDayOpenTime!.difference(now);
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  bool get isWaitingForNextDayToOpen {
    if (_currentDay >= 60) return false;
    if (isCurrentDayCompleted) {
      final nextDay = _currentDay + 1;
      return !_openDays.contains(nextDay) && _nextDayOpenTime != null;
    }
    return false;
  }

  String get waitingMessage {
    final remaining = timeRemainingToOpenNextDay;
    if (remaining == null) return '';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) {
      return 'اليوم الجديد سيفتح بعد $hours ساعة و $minutes دقيقة';
    } else if (minutes > 0) {
      return 'اليوم الجديد سيفتح بعد $minutes دقيقة';
    } else {
      return 'اليوم الجديد سيفتح خلال لحظات';
    }
  }

  PrayerDay? get currentPrayerDay {
    if (_allDays.isEmpty) return null;
    return _allDays.firstWhere(
      (day) => day.dayNumber == _currentDay,
      orElse: () => _allDays[0],
    );
  }

  PrayerDay? getPrayerDay(int dayNumber) {
    if (_allDays.isEmpty) return null;
    return _allDays.firstWhere(
      (day) => day.dayNumber == dayNumber,
      orElse: () => _allDays[0],
    );
  }

  int _getPartForDay(int day) {
    if (day <= 20) return 1;
    if (day <= 40) return 2;
    return 3;
  }

  String getNotificationTitle() {
    final part = _getPartForDay(_currentDay);
    if (!isCurrentDayCompleted) {
      switch (part) {
        case 1:
          return 'اليوم الجديد بدأ';
        case 2:
          return 'اليوم الجديد فتح';
        case 3:
          return 'اليوم الجديد اتفتح';
        default:
          return 'يوم جديد في طريق الصلاة';
      }
    }
    return 'لقد اكملت اليوم بنجاح في طريق الصلاة';
  }

  String getNotificationBody() {
    final part = _getPartForDay(_currentDay);
    if (!isCurrentDayCompleted) {
      switch (part) {
        case 1:
          return 'كمل انت في بداية الطريق - اليوم $_currentDay';
        case 2:
          return 'كمل انت في نص الطريق - اليوم $_currentDay';
        case 3:
          return 'كمل انت في نهاية الطريق - اليوم $_currentDay';
        default:
          return 'متنساش اليوم جديد في طريق الصلاة - اليوم $_currentDay';
      }
    }
    return 'استعد لليوم ${_currentDay + 1} في رحلتك الروحية';
  }

  // ==================== توليد جميع الأيام (فارغة جاهزة للتعبئة) ====================
  void _generateAllDays() {
    _allDays.clear();
    for (int i = 1; i <= 60; i++) {
      final dayContent = _getDayContent(i);
      _allDays.add(PrayerDay(
        dayNumber: i,
        title: dayContent['title']!,
        verse: dayContent['verse']!,
        reflection: dayContent['reflection']!,
        prayer: dayContent['prayer']!,
        encouragement: dayContent['encouragement']!,
        isCompleted: _completedDays.contains(i),
      ));
    }
  }

  // ==================== هنا تقوم بإدخال محتوى الأيام الـ 60 يدوياً ====================
  Map<String, String> _getDayContent(int day) {
    // قائمة بجميع الأيام - يمكنك تعديل أي يوم كما تريد
    switch (day) {
      // ==================== الأيام 1-10 ====================
      case 1:
        return {
          'title': 'بداية الطريق',
          'verse': '"قَرِّبُوا إِلَى اللهِ فَيَقْتَرِبَ إِلَيْكُمْ" يعقوب 4: 8',
          'reflection':
              'الرحلة مع الله لا تبدأ بالكمال، بل تبدأ بقلب صادق يريد أن يقترب. الله لا ينتظر منك قوة كاملة، بل ينتظر خطوة صادقة. حين تقترب منه بإخلاص، تكتشف أنه كان ينتظرك بمحبة وذراعين مفتوحتين.',
          'prayer':
              'يا رب، أبدأ رحلتي معك اليوم بقلب مشتاق، قرّبني إليك أكثر، ثبّت خطواتي في طريقك، املأ قلبي بحضورك، وعلّمني أن أحبك وأتبعك بأمانة كل يوم.',
          'encouragement': 'البداية مع الله تصنع فرقًا كبيرًا.',
        };
      case 2:
        return {
          'title': 'ثقة لا تهتز',
          'verse': '"تَوَكَّلْ عَلَى الرَّبِّ بِكُلِّ قَلْبِكَ" أمثال 3: 5',
          'reflection':
              'الثقة في الله لا تعني أنك تفهم كل شيء، لكنها تعني أنك تؤمن بمن يقودك. حين تختلط الطرق أمامك، يبقى الله ثابتًا. هو يرى الصورة كاملة، ويقودك بحكمة حتى حين لا تفهم ما يحدث.',
          'prayer':
              'يا رب، علّمني أن أثق بك في كل أمر، وأن أطمئن لحكمتك الصالحة، وأسلّم لك خوفي وتفكيري، وأتكل عليك بقلب هادئ يعرف أنك تقودني.',
          'encouragement': 'الله يعرف الطريق حين تحتار.',
        };
      case 3:
        return {
          'title': 'محبة لا تنتهي',
          'verse': '"أَحْبَبْتُكَ مَحَبَّةً أَبَدِيَّةً" إرميا 31: 3',
          'reflection':
              'محبة الله ليست مرتبطة بنجاحك أو فشلك. هي محبة ثابتة، لا تتغير بتغير مشاعرك ولا تنقص بسبب ضعفك. الله لا يحبك حين تكون قويًا فقط، بل يحبك في كل حال، بمحبة لا تنتهي.',
          'prayer':
              'يا رب، املأ قلبي بيقين محبتك، وانزع من داخلي كل خوف وقلق، وعلّمني أن أعيش مطمئنًا في حبك، ثابتًا في نعمتك، واثقًا في قربك.',
          'encouragement': 'أنت محبوب بمحبة ثابتة لا تزول.',
        };
      case 4:
        return {
          'title': 'سلام القلب',
          'verse': '"سَلاَمًا أَتْرُكُ لَكُمْ" يوحنا 14: 27',
          'reflection':
              'سلام المسيح لا يعتمد على هدوء الظروف، بل على حضوره في القلب. قد تضطرب الأيام من حولك، لكن سلامه يظل قادرًا أن يحفظ داخلك. حين يسكن المسيح في القلب، يصير السلام أعمق من القلق.',
          'prayer':
              'يا يسوع، املأ قلبي بسلامك العجيب اليوم، واحفظ أفكاري من القلق، وامنحني راحة داخلية عميقة، وثباتًا فيك، وطمأنينة لا يقدر العالم أن ينزعها.',
          'encouragement': 'سلام الله أعمق من كل اضطراب.',
        };
      case 5:
        return {
          'title': 'نعمة تكفي',
          'verse': '"تَكْفِيكَ نِعْمَتِي" 2 كورنثوس 12: 9',
          'reflection':
              'نعمة الله ليست فكرة جميلة، بل قوة حقيقية تسندك حين تضعف. حين تنفد قوتك، تبدأ نعمته في الظهور بوضوح. الله لا يطلب منك أن تكون كاملًا، بل أن تتكل عليه بقلب صادق.',
          'prayer':
              'يا رب، اسندني بنعمتك اليوم، وامنحني قوة وسط ضعفي، وعلّمني أن أتكئ عليك في كل أمر، وأثق أن نعمتك تكفيني وتكملني.',
          'encouragement': 'نعمة الله تكفيك في كل ضعف.',
        };
      case 6:
        return {
          'title': 'قلب تائب',
          'verse': '"قَلْبًا نَقِيًّا اخْلُقْ فِيَّ يَا اللهُ" مزمور 51: 10',
          'reflection':
              'التوبة ليست رجوعًا إلى الخوف، بل رجوعًا إلى حضن الآب. الله لا يرفض القلب التائب، بل يستقبله برحمة. حين تعود إليه بصدق، تجد غفرانًا يطهّر، ونعمة تبدأ من جديد.',
          'prayer':
              'يا رب، طهّر قلبي من كل خطية، وجدّد روحي فيك، وامنحني قلبًا نقيًا يحبك بصدق، ويرجع إليك دائمًا، ويثبت في نورك.',
          'encouragement': 'الله يفرح بالقلب العائد إليه.',
        };
      case 7:
        return {
          'title': 'غفران يحرر',
          'verse':
              '"إِنْ اعْتَرَفْنَا بِخَطَايَانَا فَهُوَ أَمِينٌ" 1 يوحنا 1: 9',
          'reflection':
              'غفران الله لا يزيل الخطية فقط، بل يرفع ثقلها عن القلب. الله لا يغفر لك بتردد، بل بمحبة كاملة. حين تعترف أمامه بصدق، يسكب على روحك راحة، وعلى قلبك بداية جديدة.',
          'prayer':
              'يا رب، اغفر لي كل خطية، وحرر قلبي من الذنب، واملأني بسلام الغفران، وجدّد داخلي فرح الخلاص، وامنحني بداية جديدة معك.',
          'encouragement': 'غفران الله يفتح باب الحرية.',
        };
      case 8:
        return {
          'title': 'حضور الله',
          'verse': '"هَا أَنَا مَعَكُمْ كُلَّ الأَيَّامِ" متى 28: 20',
          'reflection':
              'حضور الله لا يفارقك في يوم هادئ ولا في يوم ثقيل. هو حاضر في تعبك، في صمتك، في خوفك، وفي رجائك. حين تشعر أنك وحدك، تذكّر أن الله أقرب إليك مما تظن.',
          'prayer':
              'يا رب، افتح عيني لأرى حضورك معي، وامنحني يقينًا ثابتًا أنك قريب، وعلّمني أن أطمئن في وجودك، وأسير كل يوم في سلامك.',
          'encouragement': 'الله معك في كل لحظة.',
        };
      case 9:
        return {
          'title': 'نور الطريق',
          'verse': 'سِرَاجٌ لِرِجْلِي كَلاَمُكَ" مزمور 119: 105',
          'reflection':
              'كلمة الله لا تكشف الطريق كله دفعة واحدة، لكنها تعطيك نورًا كافيًا للخطوة التالية. الله يقودك يومًا بيوم، لا لتعيش في قلق الغد، بل في أمان حضوره اليوم.',
          'prayer':
              'يا رب، أنر طريقي بكلمتك، وامنحني حكمة لخطوتي القادمة، واجعل صوتك واضحًا في قلبي، وقُدني بنورك في كل قرار وخطوة.',
          'encouragement': 'الله ينير الخطوة القادمة.',
        };
      case 10:
        return {
          'title': 'راحة النفوس',
          'verse': '"تَعَالَوْا إِلَيَّ... وَأَنَا أُرِيحُكُمْ" متى 11: 28',
          'reflection':
              'المسيح لا يطلب منك أن تخفي تعبك، بل أن تأتي به إليه. هو لا يثقل قلبك أكثر، بل يريحه. حين تضع حملك عنده، تجد راحة لا يعطيها العالم.',
          'prayer':
              'يا يسوع، أحمل إليك تعبي اليوم، فارح قلبي، وخفف حملي، وامنحني راحة عميقة في حضورك، وسلامًا يهدئ نفسي ويقوّي داخلي.',
          'encouragement': 'راحتك تبدأ حين تقترب من المسيح.',
        };

      // ==================== الأيام 11-20 ====================
      case 11:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 12:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 13:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 14:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 15:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 16:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 17:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 18:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 19:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 20:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };

      // ==================== الأيام 21-30 ====================
      case 21:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 22:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 23:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 24:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 25:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 26:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 27:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 28:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 29:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 30:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };

      // ==================== الأيام 31-40 ====================
      case 31:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 32:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 33:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 34:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 35:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 36:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 37:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 38:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 39:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 40:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };

      // ==================== الأيام 41-50 ====================
      case 41:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 42:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 43:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 44:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 45:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 46:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 47:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 48:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 49:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 50:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };

      // ==================== الأيام 51-60 ====================
      case 51:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 52:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 53:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 54:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 55:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 56:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 57:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 58:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 59:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };
      case 60:
        return {
          'title': '',
          'verse': '',
          'reflection': '',
          'prayer': '',
          'encouragement': '',
        };

      default:
        return {
          'title': '⚠️ لم يتم إدخال محتوى لليوم $day',
          'verse': 'يُرجى إكمال بيانات هذا اليوم',
          'reflection': 'تأكد من إدخال التأمل والصلاة لهذا اليوم',
          'prayer': 'يُرجى إضافة الصلاة',
          'encouragement': 'استمر في إكمال المحتوى!',
        };
    }
  }

  DateTime _calculateNextOpenTime() {
    final now = DateTime.now();
    DateTime targetTime = DateTime(now.year, now.month, now.day, 13, 0, 0);
    if (now.isAfter(targetTime)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    return targetTime;
  }

  Future<bool> _checkAndOpenNextDay() async {
    if (_currentDay >= 60) return false;
    if (!_completedDays.contains(_currentDay)) return false;
    final nextDay = _currentDay + 1;
    if (_openDays.contains(nextDay)) return false;
    if (_nextDayOpenTime == null) {
      _nextDayOpenTime = _calculateNextOpenTime();
      await _saveNextDayOpenTime();
      notifyListeners();
      return false;
    }
    final now = DateTime.now();
    if (now.isAfter(_nextDayOpenTime!)) {
      _openDays.add(nextDay);
      await _saveOpenDays();
      _nextDayOpenTime = null;
      await _saveNextDayOpenTime();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final completedDaysString = prefs.getString(_completedDaysKey);
    if (completedDaysString != null && completedDaysString.isNotEmpty) {
      _completedDays =
          Set<int>.from(completedDaysString.split(',').map(int.parse));
    } else {
      _completedDays = {};
    }
    final openDaysString = prefs.getString(_openDaysKey);
    if (openDaysString != null && openDaysString.isNotEmpty) {
      _openDays = Set<int>.from(openDaysString.split(',').map(int.parse));
    } else {
      _openDays = {1};
    }
    _currentDay = prefs.getInt(_currentDayKey) ?? 1;
    while (_currentDay < 60 &&
        _completedDays.contains(_currentDay) &&
        _openDays.contains(_currentDay + 1)) {
      _currentDay++;
    }
    await prefs.setInt(_currentDayKey, _currentDay);
    final nextDayOpenTimeString = prefs.getString(_nextDayOpenTimeKey);
    if (nextDayOpenTimeString != null) {
      _nextDayOpenTime = DateTime.parse(nextDayOpenTimeString);
    }
    _generateAllDays();
    for (var day in _allDays) {
      day.isCompleted = _completedDays.contains(day.dayNumber);
    }
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    await _checkAndOpenNextDay();
    notifyListeners();
  }

  Future<void> _saveOpenDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_openDaysKey, _openDays.join(','));
  }

  Future<void> _saveNextDayOpenTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (_nextDayOpenTime != null) {
      await prefs.setString(
          _nextDayOpenTimeKey, _nextDayOpenTime!.toIso8601String());
    } else {
      await prefs.remove(_nextDayOpenTimeKey);
    }
  }

  Future<void> completeCurrentDay() async {
    if (isCurrentDayCompleted) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      await _audioService.playCompletionSound();
    } catch (e) {
      print('Error playing completion sound: $e');
    }
    _completedDays.add(_currentDay);
    await prefs.setString(_completedDaysKey, _completedDays.join(','));
    final day = _allDays.firstWhere((d) => d.dayNumber == _currentDay);
    day.isCompleted = true;
    if (_currentDay < 60) {
      _nextDayOpenTime = _calculateNextOpenTime();
      await _saveNextDayOpenTime();
      final now = DateTime.now();
      if (now.isAfter(_nextDayOpenTime!)) {
        final nextDay = _currentDay + 1;
        _openDays.add(nextDay);
        await _saveOpenDays();
        _nextDayOpenTime = null;
        await _saveNextDayOpenTime();
      }
    }
    if (_currentDay < 60 && _openDays.contains(_currentDay + 1)) {
      _currentDay++;
    }
    await prefs.setInt(_currentDayKey, _currentDay);
    notifyListeners();
  }

  Future<void> forceOpenNextDay() async {
    if (_currentDay >= 60) return;
    if (!_completedDays.contains(_currentDay)) return;
    final nextDay = _currentDay + 1;
    if (!_openDays.contains(nextDay)) {
      _openDays.add(nextDay);
      await _saveOpenDays();
      _nextDayOpenTime = null;
      await _saveNextDayOpenTime();
      if (_openDays.contains(_currentDay + 1)) {
        _currentDay++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_currentDayKey, _currentDay);
      }
      notifyListeners();
    }
  }

  Future<void> refreshAndCheck() async {
    await loadData();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    notifyListeners();
  }

  void dispose() {
    _audioService.dispose();
  }
}
