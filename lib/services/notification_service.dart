import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'audio_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioService _audioService = AudioService();

  bool _initialized = false;

  static const String _egyptTimeZone = 'Africa/Cairo';
  static const int _notificationHour = 13;
  static const int _notificationMinute = 0;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_egyptTimeZone));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentSound: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required int id,
  }) async {
    if (!_initialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('prayer_road_notifications_enabled') ?? true;
    if (!enabled) return;

    final egyptTimeZone = tz.getLocation(_egyptTimeZone);
    final now = tz.TZDateTime.now(egyptTimeZone);

    var scheduledTime = tz.TZDateTime(
      egyptTimeZone,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_road_channel',
      'طريق الصلاة',
      channelDescription: 'تذكير يومي لإكمال مهام طريق الصلاة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'notification.mp3',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> schedulePrayerRoadNotification({
    required String title,
    required String body,
  }) async {
    await _audioService.playNotificationSound();

    await scheduleDailyNotification(
      hour: _notificationHour,
      minute: _notificationMinute,
      title: title,
      body: body,
      id: 1001,
    );
  }

  Future<void> updateDailyNotification(String title, String body) async {
    try {
      await cancelNotification(1001);
      await schedulePrayerRoadNotification(title: title, body: body);
    } catch (e) {
      print('Error updating daily notification: $e');
    }
  }

  Future<void> sendImmediateNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('prayer_road_notifications_enabled') ?? true;
    if (!enabled) return;

    await _audioService.playNotificationSound();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_road_channel',
      'طريق الصلاة',
      channelDescription: 'تذكير يومي لإكمال مهام طريق الصلاة',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
      sound: 'notification.mp3',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1002,
      title,
      body,
      details,
    );
  }

  // ==================== إشعار عيد الميلاد ====================

  /// جدولة إشعار سنوي متكرر بمناسبة عيد الميلاد
  /// يتم إرساله في الساعة 10 صباحاً من كل عام في نفس تاريخ الميلاد
  Future<void> scheduleBirthdayNotification({
    required String userName,
    required DateTime birthdayDate,
  }) async {
    if (!_initialized) await initialize();

    final egyptTimeZone = tz.getLocation(_egyptTimeZone);

    // وقت الإشعار: الساعة 10 صباحاً
    const int birthdayNotificationHour = 10;
    const int birthdayNotificationMinute = 0;

    final now = tz.TZDateTime.now(egyptTimeZone);

    // تحديد موعد عيد الميلاد القادم
    var scheduledTime = tz.TZDateTime(
      egyptTimeZone,
      now.year,
      birthdayDate.month,
      birthdayDate.day,
      birthdayNotificationHour,
      birthdayNotificationMinute,
    );

    // إذا كان التاريخ قد مر هذه السنة، نذهب للسنة القادمة
    if (scheduledTime.isBefore(now)) {
      scheduledTime = tz.TZDateTime(
        egyptTimeZone,
        now.year + 1,
        birthdayDate.month,
        birthdayDate.day,
        birthdayNotificationHour,
        birthdayNotificationMinute,
      );
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'birthday_channel',
      'تهنئة عيد الميلاد',
      channelDescription: 'تهنئة سنوية بعيد ميلاد المستخدم',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // استخدام matchDateTimeComponents: DateTimeComponents.dateAndTime
      // لتكرار الإشعار سنوياً في نفس التاريخ والوقت
      await _notifications.zonedSchedule(
        2001, // ID ثابت لعيد الميلاد
        '🎉 كل سنة وأنت طيب يا $userName 🎉',
        'نهنئك بعيد ميلادك المبارك! نسأل الله أن يبارك حياتك ويملأها سلاماً وفرحاً.',
        scheduledTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      print('✅ تم جدولة إشعار عيد الميلاد في: $scheduledTime');
    } catch (e) {
      print('❌ خطأ في جدولة إشعار عيد الميلاد: $e');
      // محاولة بديلة بدون matchDateTimeComponents
      try {
        await _notifications.zonedSchedule(
          2001,
          '🎉 كل سنة وأنت طيب يا $userName 🎉',
          'نهنئك بعيد ميلادك المبارك! نسأل الله أن يبارك حياتك ويملأها سلاماً وفرحاً.',
          scheduledTime,
          details,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('✅ تم جدولة إشعار عيد الميلاد (طريقة بديلة)');
      } catch (e2) {
        print('❌ فشل جدولة إشعار عيد الميلاد: $e2');
      }
    }
  }

  /// إلغاء إشعار عيد الميلاد المجدول
  Future<void> cancelBirthdayNotification() async {
    await _notifications.cancel(2001);
    print('🗑️ تم إلغاء إشعار عيد الميلاد');
  }

  /// إرسال إشعار فوري بمناسبة عيد الميلاد (للاستخدام اليدوي)
  Future<void> sendImmediateBirthdayNotification({
    required String userName,
  }) async {
    if (!_initialized) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'birthday_channel',
      'تهنئة عيد الميلاد',
      channelDescription: 'تهنئة بعيد ميلاد المستخدم',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2002,
      '🎉 كل سنة وأنت طيب يا $userName 🎉',
      'نهنئك بعيد ميلادك المبارك! نسأل الله أن يبارك حياتك ويملأها سلاماً وفرحاً.',
      details,
    );
  }

  // ==================== التحقق من عيد الميلاد اليوم ====================

  /// التحقق مما إذا كان اليوم هو عيد ميلاد المستخدم
  /// وإرسال إشعار فوري إذا كان الأمر كذلك
  Future<void> checkAndSendBirthdayNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final birthdayString = prefs.getString('birthday');
      final userName = prefs.getString('userName') ?? 'مستخدم';

      if (birthdayString == null) return;

      final birthday = DateTime.parse(birthdayString);
      final now = DateTime.now();

      // التحقق من تطابق اليوم والشهر
      if (birthday.month == now.month && birthday.day == now.day) {
        // التحقق من عدم إرسال الإشعار اليوم
        final lastBirthdayNotification =
            prefs.getString('last_birthday_notification');
        final todayKey = '${now.year}-${now.month}-${now.day}';

        if (lastBirthdayNotification != todayKey) {
          await sendImmediateBirthdayNotification(userName: userName);
          await prefs.setString('last_birthday_notification', todayKey);
          print('🎂 تم إرسال إشعار عيد الميلاد لـ $userName');
        }
      }
    } catch (e) {
      print('❌ خطأ في التحقق من عيد الميلاد: $e');
    }
  }

  void dispose() {
    _audioService.dispose();
  }
}
