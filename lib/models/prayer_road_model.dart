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
  int _currentDay = 1;
  bool _notificationsEnabled = true;
  Set<int> _completedDays = {};
  Set<int> _openDays = {1};
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

  void _generateAllDays() {
    _allDays.clear();
    for (int i = 1; i <= 60; i++) {
      final part = _getPartForDay(i);
      final dayContent = _getDayContent(i, part);
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

  Map<String, String> _getDayContent(int day, int part) {
    if (part == 1) {
      final List<Map<String, String>> contents = [
        {
          'title': 'بداية الرحلة مع الله',
          'verse':
              'تَوَكَّلْ عَلَى الرَّبِّ بِكُلِّ قَلْبِكَ، وَعَلَى فَهْمِكَ لاَ تَعْتَمِدْ.',
          'reflection':
              'اليوم هو بداية رحلتك مع الله. ثق به في كل خطوة تخطوها.',
          'prayer':
              'يا رب، سلم لي خطواتي في بداية هذا الطريق، وأعطني الثقة بك.',
          'encouragement': 'كل رحلة كبيرة تبدأ بخطوة صغيرة. أنت قادر!',
        },
        {
          'title': 'الثقة في الله',
          'verse':
              'اِطْلُبْ إِلَىَّ فَأُجِيبَكَ، وَأُخْبِرَكَ بِعَظَائِمَ وَأُمُورٍ صَعْبَةٍ لَمْ تَعْرِفْهَا.',
          'reflection': 'الله يسمع صلاتك ويريد أن يجيبك بأعظم مما تتخيل.',
          'prayer': 'أبويا السماوي، علمني أن أثق في استجابتك لصلواتي.',
          'encouragement': 'صلاتك لها قوة عظيمة، استمر!',
        },
        {
          'title': 'محبة الله اللامحدودة',
          'verse':
              'لأَنَّهُ هكَذَا أَحَبَّ اللهُ الْعَالَمَ حَتَّى بَذَلَ ابْنَهُ الْوَحِيدَ، لِكَيْ لاَ يَهْلِكَ كُلُّ مَنْ يُؤْمِنُ بِهِ، بَلْ تَكُونُ لَهُ الْحَيَاةُ الأَبَدِيَّةُ.',
          'reflection': 'محبة الله لك أكبر من أي شيء في هذا العالم.',
          'prayer': 'أشكرك يا رب على محبتك العظيمة لي.',
          'encouragement': 'أنت محبوب من الله أكثر مما تتخيل!',
        },
        {
          'title': 'السلام الداخلي',
          'verse':
              'لاَ تَهْتَمُّوا بِشَيْءٍ، بَلْ فِي كُلِّ شَيْءٍ بِالصَّلاَةِ وَالدُّعَاءِ مَعَ الشُّكْرِ، لِتُعْلَمْ طِلْبَاتُكُمْ لَدَى اللهِ.',
          'reflection': 'الصلاة هي مفتاح السلام الحقيقي في قلبك.',
          'prayer': 'أعطني سلامك يا رب الذي يفوق كل عقل.',
          'encouragement': 'سلام الله معك في كل خطوة!',
        },
        {
          'title': 'النعمة المجانية',
          'verse':
              'لأَنَّكُمْ بِالنِّعْمَةِ مُخَلَّصُونَ، بِالإِيمَانِ، وَذلِكَ لَيْسَ مِنْكُمْ. هُوَ عَطِيَّةُ اللهِ.',
          'reflection': 'خلاصك ليس بجهدك، بل بنعمة الله المجانية.',
          'prayer': 'أشكرك يا رب على نعمتك المجانية التي لا تستحق.',
          'encouragement': 'نعمة الله تكفيك كل يوم!',
        },
      ];
      return contents[(day - 1) % contents.length];
    } else if (part == 2) {
      final List<Map<String, String>> contents = [
        {
          'title': 'قوة الصبر',
          'verse':
              'وَأَمَّا الصَّبْرُ فَلْيَكُنْ لَهُ عَمَلٌ تَامٌّ، لِكَيْ تَكُونُوا تَامِّينَ وَكَامِلِينَ غَيْرَ نَاقِصِينَ فِي شَيْءٍ.',
          'reflection':
              'الصبر يصنع فيك النضج الروحي. أنت في منتصف الطريق، استمر.',
          'prayer': 'يا رب، أعطني صبراً في منتصف هذه الرحلة، وثبت خطواتي.',
          'encouragement': 'أنت قطعت نصف الطريق! أنت أقوى مما تتصور.',
        },
        {
          'title': 'المحبة هي الأساس',
          'verse':
              'وَقَبْلَ كُلِّ شَيْءٍ، لِيَكُنْ لَكُمْ بَعْضُكُمْ لِبَعْضٍ مَحَبَّةٌ حَارَّةٌ، لأَنَّ الْمَحَبَّةَ تَسْتُرُ كَثْرَةً مِنَ الْخَطَايَا.',
          'reflection': 'المحبة هي جوهر العلاقة مع الله ومع الآخرين.',
          'prayer': 'علِّمْني يا رب أن أحب كما أحببت، من قلب نقي.',
          'encouragement': 'المحبة هي أقوى قوة في الكون، استخدمها!',
        },
        {
          'title': 'التجديد اليومي',
          'verse':
              'فَإِنَّنَا لاَ نَفْشَلُ، بَلْ إِنْ كَانَ إِنْسَانُنَا الْخَارِجُ يَفْنَى، فَالدَّاخِلُ يَتَجَدَّدُ يَوْماً فَيَوْماً.',
          'reflection': 'كل يوم هو فرصة جديدة للتجدد والنمو.',
          'prayer': 'جدِّد فيَّ روحاً مستقيماً يا رب.',
          'encouragement': 'كل يوم يجعلك أقوى وأفضل!',
        },
        {
          'title': 'الإيمان في الضيق',
          'verse':
              'كُلَّ شَيْءٍ أَسْتَطِيعُ فِي الْمَسِيحِ الَّذِي يُقَوِّينِي.',
          'reflection': 'قوتك لا تأتي من نفسك، بل من المسيح الذي يقويك.',
          'prayer': 'أعطني قوة لتجاوز الصعاب يا رب.',
          'encouragement': 'مع المسيح تقدر على كل شيء!',
        },
      ];
      return contents[(day - 21) % contents.length];
    } else {
      final List<Map<String, String>> contents = [
        {
          'title': 'الفرح في الرب',
          'verse':
              'اِفْرَحُوا فِي الرَّبِّ كُلَّ حِينٍ، وَأَقُولُ أَيْضًا: افْرَحُوا.',
          'reflection':
              'الفرح ليس ظرفاً، بل هو قرار. اختر أن تفرح في الرب اليوم.',
          'prayer': 'يا رب، املأ قلبي فرحاً لا يتزعزع، مهما كانت الظروف.',
          'encouragement': 'أنت في الأمتار الأخيرة! الفرح قوتك.',
        },
        {
          'title': 'العهد الجديد مع الله',
          'verse':
              'لأَنَّ هذَا هُوَ الْعَهْدُ الَّذِي أَقْطَعُهُ مَعَهُمْ بَعْدَ تِلْكَ الأَيَّامِ، يَقُولُ الرَّبُّ: أَجْعَلُ شَرَائِعِي فِي قُلُوبِهِمْ، وَأَكْتُبُهَا فِي أَذْهَانِهِمْ.',
          'reflection': 'الله يريد أن يكتب كلمته في قلبك، لتعيش بها كل يوم.',
          'prayer': 'اكتب كلمتك في قلبي يا رب، لتكون نبراساً لخطواتي.',
          'encouragement': 'أنت على وشك إكمال الرحلة! لا تستسلم الآن.',
        },
        {
          'title': 'البركة والإكمال',
          'verse':
              'أَمَّا إِلَهُ السَّلاَمِ فَلْيُقَدِّسْكُمْ بِالتَّمَامِ. وَلْتُحْفَظْ رُوحُكُمْ وَنَفْسُكُمْ وَجَسَدُكُمْ كَامِلَةً بِلاَ لَوْمٍ عِنْدَ مَجِيءِ رَبِّنَا يَسُوعَ الْمَسِيحِ.',
          'reflection': 'الله يريد لك البركة الكاملة في كل جوانب حياتك.',
          'prayer': 'باركني يا رب وأكمل عملك الصالح فيَّ.',
          'encouragement': 'النهاية المجيدة تنتظرك! أنت فائز!',
        },
        {
          'title': 'العهد الأبدي',
          'verse':
              'وَأَعْطِيهِمْ حَيَاةً أَبَدِيَّةً، وَلَنْ يَهْلِكُوا إِلَى الأَبَدِ، وَلاَ يَخْطَفُهُمْ أَحَدٌ مِنْ يَدِي.',
          'reflection': 'أنت آمن في يد الله، لا أحد يستطيع أن يخطفك منه.',
          'prayer': 'أشكرك يا رب على الأمان الذي تعطيه لي.',
          'encouragement': 'أنت آمن في يد الله إلى الأبد!',
        },
      ];
      return contents[(day - 41) % contents.length];
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
