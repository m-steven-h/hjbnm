// lib/services/gist_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discussion_model.dart';

class GistService {
  // 🔴🔴🔴 حط الرابط الخام (Raw) بتاع Gist بتاعك هنا 🔴🔴🔴
  static const String _benefitWordsUrl =
      'https://gist.githubusercontent.com/m-steven-h/4f2bc283fe0bc174a2bca860c6d482ce/raw/benefit_words.json';
  static const String _discussionsUrl =
      'https://gist.githubusercontent.com/m-steven-h/daeac40fbdb1171d69787ff66684fa64/raw/c9c883fe813771e114e92c23ece3be1e9be98246/discussions.json';

  // مفاتيح التخزين المحلي
  static const String _savedBenefitWordsKey = 'saved_benefit_words';
  static const String _savedDiscussionsKey = 'saved_discussions';
  static const String _savedBenefitVersionKey = 'saved_benefit_version';
  static const String _savedDiscussionsVersionKey = 'saved_discussions_version';
  static const String _userDiscussionsKey = 'user_discussions';

  // Cache للبيانات (تحسين الأداء)
  static List<Map<String, dynamic>>? _cachedBenefitWords;
  static List<DiscussionModel>? _cachedDiscussions;
  static DateTime? _lastBenefitFetch;
  static DateTime? _lastDiscussionsFetch;
  static const _cacheDuration = Duration(minutes: 30);

  // ==================== كلمات المنفعة ====================

  Future<List<Map<String, dynamic>>> getBenefitWords() async {
    // استخدام cache لو لسه مخلصش
    if (_cachedBenefitWords != null &&
        _lastBenefitFetch != null &&
        DateTime.now().difference(_lastBenefitFetch!) < _cacheDuration) {
      print('📦 استخدام cache لكلمات المنفعة');
      return _cachedBenefitWords!;
    }

    final prefs = await SharedPreferences.getInstance();

    try {
      print('🌐 جاري جلب كلمات المنفعة من Gist...');
      final response = await http
          .get(Uri.parse(_benefitWordsUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // حفظ في SharedPreferences
        await prefs.setString(_savedBenefitWordsKey, response.body);
        await prefs.setInt(_savedBenefitVersionKey, data['version'] ?? 1);

        final words = List<Map<String, dynamic>>.from(data['words']);

        // حفظ في cache
        _cachedBenefitWords = words;
        _lastBenefitFetch = DateTime.now();

        print('✅ تم جلب ${words.length} كلمة منفعة');
        return words;
      }
    } catch (e) {
      print('⚠️ لا يوجد اتصال بالإنترنت لكلمات المنفعة: $e');
    }

    // جلب من التخزين المحلي
    final savedData = prefs.getString(_savedBenefitWordsKey);
    if (savedData != null) {
      print('📦 جلب كلمات المنفعة من التخزين المحلي');
      final Map<String, dynamic> data = jsonDecode(savedData);
      final words = List<Map<String, dynamic>>.from(data['words']);

      // حفظ في cache
      _cachedBenefitWords = words;
      _lastBenefitFetch = DateTime.now();

      return words;
    }

    return [];
  }

  Future<bool> refreshBenefitWords() async {
    try {
      print('🔄 تحديث كلمات المنفعة...');
      final response = await http
          .get(Uri.parse(_benefitWordsUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedBenefitWordsKey, response.body);

        final data = jsonDecode(response.body);
        await prefs.setInt(_savedBenefitVersionKey, data['version'] ?? 1);

        // تحديث cache
        _cachedBenefitWords = List<Map<String, dynamic>>.from(data['words']);
        _lastBenefitFetch = DateTime.now();

        print('✅ تم تحديث كلمات المنفعة');
        return true;
      }
    } catch (e) {
      print('❌ فشل تحديث كلمات المنفعة: $e');
    }
    return false;
  }

  // ==================== المناقشات ====================

  Future<List<DiscussionModel>> getDiscussions() async {
    // استخدام cache لو لسه مخلصش
    if (_cachedDiscussions != null &&
        _lastDiscussionsFetch != null &&
        DateTime.now().difference(_lastDiscussionsFetch!) < _cacheDuration) {
      print('📦 استخدام cache للمناقشات');
      return _cachedDiscussions!;
    }

    final prefs = await SharedPreferences.getInstance();
    List<DiscussionModel> allDiscussions = [];

    // 1. جلب المناقشات الأساسية من Gist
    try {
      print('🌐 جاري جلب المناقشات من Gist...');
      final response = await http
          .get(Uri.parse(_discussionsUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> discussionsJson = data['discussions'];

        final baseDiscussions = discussionsJson.map((json) {
          return DiscussionModel(
            id: json['id'],
            userName: json['userName'],
            userImage: json['userImage'],
            content: json['content'],
            createdAt: DateTime.parse(json['createdAt']),
            isFromUser: false,
          );
        }).toList();

        // حفظ في SharedPreferences
        await prefs.setString(_savedDiscussionsKey,
            jsonEncode(baseDiscussions.map((d) => d.toMap()).toList()));
        await prefs.setInt(_savedDiscussionsVersionKey, data['version'] ?? 1);

        allDiscussions.addAll(baseDiscussions);
        print('✅ تم جلب ${baseDiscussions.length} مناقشة من Gist');
      }
    } catch (e) {
      print('⚠️ لا يوجد اتصال بالإنترنت للمناقشات: $e');

      // جلب من التخزين المحلي
      final savedDiscussions = prefs.getString(_savedDiscussionsKey);
      if (savedDiscussions != null) {
        final List<dynamic> savedJson = jsonDecode(savedDiscussions);
        final savedDiscussionsList =
            savedJson.map((json) => DiscussionModel.fromMap(json)).toList();
        allDiscussions.addAll(savedDiscussionsList);
        print('📦 جلب ${savedDiscussionsList.length} مناقشة من التخزين المحلي');
      }
    }

    // 2. جلب المناقشات اللي أضافها المستخدم محلياً
    final userDiscussions = prefs.getString(_userDiscussionsKey);
    if (userDiscussions != null) {
      final List<dynamic> userJson = jsonDecode(userDiscussions);
      final userDiscussionsList =
          userJson.map((json) => DiscussionModel.fromMap(json)).toList();
      allDiscussions.addAll(userDiscussionsList);
      print('👤 جلب ${userDiscussionsList.length} مناقشة من المستخدم');
    }

    // ترتيب حسب التاريخ (الأحدث أولاً)

    // حفظ في cache
    _cachedDiscussions = allDiscussions;
    _lastDiscussionsFetch = DateTime.now();

    return allDiscussions;
  }

  // دالة التحديث للمناقشات (دي اللي بتناديها من الصفحة)
  Future<bool> refreshDiscussions() async {
    try {
      print('🔄 تحديث المناقشات...');
      final response = await http
          .get(Uri.parse(_discussionsUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> discussionsJson = data['discussions'];

        final baseDiscussions = discussionsJson.map((json) {
          return DiscussionModel(
            id: json['id'],
            userName: json['userName'],
            userImage: json['userImage'],
            content: json['content'],
            createdAt: DateTime.parse(json['createdAt']),
            isFromUser: false,
          );
        }).toList();

        await prefs.setString(_savedDiscussionsKey,
            jsonEncode(baseDiscussions.map((d) => d.toMap()).toList()));
        await prefs.setInt(_savedDiscussionsVersionKey, data['version'] ?? 1);

        // تحديث cache
        _cachedDiscussions = null; // مسح cache عشان يتجدد
        _lastDiscussionsFetch = null;

        print('✅ تم تحديث المناقشات');
        return true;
      }
    } catch (e) {
      print('❌ فشل تحديث المناقشات: $e');
    }
    return false;
  }

  // دالة عامة للتحديث (بتنادي الاتنين)
  Future<bool> refreshData() async {
    final benefitResult = await refreshBenefitWords();
    final discussionsResult = await refreshDiscussions();
    return benefitResult || discussionsResult;
  }

  // إضافة مناقشة جديدة من المستخدم
  Future<bool> addDiscussion(String userName, String content) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // جلب المناقشات الحالية للمستخدم
      final existingUserDiscussions = prefs.getString(_userDiscussionsKey);
      List<DiscussionModel> userDiscussions = [];

      if (existingUserDiscussions != null) {
        final List<dynamic> existingJson = jsonDecode(existingUserDiscussions);
        userDiscussions =
            existingJson.map((json) => DiscussionModel.fromMap(json)).toList();
      }

      // إنشاء مناقشة جديدة
      final newDiscussion = DiscussionModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        userName: userName,
        userImage: 'assets/icon/icon.png',
        content: content,
        createdAt: DateTime.now(),
        isFromUser: true,
      );

      // إضافة إلى القائمة
      userDiscussions.insert(0, newDiscussion);

      // حفظ فقط آخر 50 مناقشة (عشان ما تكبرش المساحة)
      if (userDiscussions.length > 50) {
        userDiscussions = userDiscussions.take(50).toList();
      }

      // حفظ في SharedPreferences
      await prefs.setString(_userDiscussionsKey,
          jsonEncode(userDiscussions.map((d) => d.toMap()).toList()));

      // تحديث cache
      _cachedDiscussions = null;

      print('✅ تم إضافة مناقشة جديدة من $userName');
      return true;
    } catch (e) {
      print('❌ فشل إضافة المناقشة: $e');
      return false;
    }
  }

  // حذف مناقشة (للمستخدم بس)
  Future<bool> deleteDiscussion(String discussionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final existingUserDiscussions = prefs.getString(_userDiscussionsKey);
      if (existingUserDiscussions == null) return false;

      List<dynamic> existingJson = jsonDecode(existingUserDiscussions);
      existingJson.removeWhere((json) => json['id'] == discussionId);

      await prefs.setString(_userDiscussionsKey, jsonEncode(existingJson));

      // تحديث cache
      _cachedDiscussions = null;

      print('✅ تم حذف المناقشة');
      return true;
    } catch (e) {
      print('❌ فشل حذف المناقشة: $e');
      return false;
    }
  }

  // مسح cache (ممكن تستخدمه عند التحديد)
  void clearCache() {
    _cachedBenefitWords = null;
    _cachedDiscussions = null;
    _lastBenefitFetch = null;
    _lastDiscussionsFetch = null;
  }
}
