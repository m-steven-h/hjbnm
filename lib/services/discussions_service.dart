// lib/services/discussions_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/discussion_model.dart';
import '../secrets.dart';

class DiscussionsService {
  static const String _binId = Secrets.binId;
  static const String _masterKey = Secrets.masterKey;
  static const String _publicUrl = 'https://api.jsonbin.io/v3/b/$_binId/latest';
  static const String _writeUrl = 'https://api.jsonbin.io/v3/b/$_binId';

  static const String _cachedDiscussionsKey = 'cached_discussions';
  static const String _lastUpdateKey = 'last_discussions_update';

  // ✅ جلب المناقشات
  Future<List<DiscussionModel>> getDiscussions() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedData = prefs.getString(_cachedDiscussionsKey);
    if (cachedData != null) {
      print('📦 جلب من الكاش');
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.map((json) => DiscussionModel.fromMap(json)).toList();
    }

    return await _fetchFromApi();
  }

  Future<List<DiscussionModel>> _fetchFromApi() async {
    try {
      print('🌐 جلب من API...');
      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> discussionsJson = [];

        if (data['record'] != null && data['record']['discussions'] != null) {
          discussionsJson = data['record']['discussions'];
        } else if (data['discussions'] != null) {
          discussionsJson = data['discussions'];
        }

        final discussions = discussionsJson
            .map((json) => DiscussionModel(
                  id: json['id'].toString(),
                  userId: json['userId']?.toString() ?? '',
                  userName: json['userName']?.toString() ?? 'مستخدم',
                  userImage:
                      json['userImage']?.toString() ?? 'assets/icon/icon.png',
                  content: json['content']?.toString() ?? '',
                  createdAt: json['createdAt'] != null
                      ? DateTime.tryParse(json['createdAt'].toString())
                      : DateTime.now(),
                  isFromUser: false,
                ))
            .toList();

        await _cacheDiscussions(discussions);
        return discussions;
      }
      return [];
    } catch (e) {
      print('❌ فشل الجلب: $e');
      return [];
    }
  }

  Future<void> _cacheDiscussions(List<DiscussionModel> discussions) async {
    final prefs = await SharedPreferences.getInstance();
    final list = discussions.map((d) => d.toMap()).toList();
    await prefs.setString(_cachedDiscussionsKey, jsonEncode(list));
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
  }

  // ✅ إضافة مناقشة - النسخة النهائية
  Future<bool> addDiscussion(
      String userId, String userName, String content) async {
    try {
      print('========================================');
      print('📝 بدء إضافة مناقشة');
      print('🆔 userId: $userId');
      print('👤 userName: $userName');
      print('📝 content: $content');
      print('========================================');

      // 1️⃣ جلب البيانات الحالية من API
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 10));

      print('📥 GET Status: ${getResponse.statusCode}');

      if (getResponse.statusCode != 200) {
        print('❌ فشل جلب البيانات');
        return false;
      }

      final data = jsonDecode(getResponse.body);
      List<dynamic> discussions = [];

      if (data['record'] != null && data['record']['discussions'] != null) {
        discussions = List<dynamic>.from(data['record']['discussions']);
      } else if (data['discussions'] != null) {
        discussions = List<dynamic>.from(data['discussions']);
      }

      print('📊 عدد المناقشات قبل الإضافة: ${discussions.length}');

      // 2️⃣ إنشاء المناقشة الجديدة
      final newDiscussion = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'userName': userName,
        'userImage': 'assets/icon/icon.png',
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      };

      discussions.insert(0, newDiscussion);
      print('📊 عدد المناقشات بعد الإضافة: ${discussions.length}');

      // 3️⃣ حفظ في JSONBin
      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode({'discussions': discussions}),
          )
          .timeout(const Duration(seconds: 15));

      print('📤 PUT Status: ${putResponse.statusCode}');
      print('📤 PUT Response: ${putResponse.body}');

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        // 4️⃣ تحديث الكاش
        await _cacheDiscussions(await _fetchFromApi());
        print('✅ تم إضافة المناقشة بنجاح');
        return true;
      }

      print('❌ فشل الحفظ');
      return false;
    } catch (e) {
      print('❌ استثناء: $e');
      return false;
    }
  }

  // ✅ حذف مناقشة
  Future<bool> deleteDiscussion(
      String discussionId, String currentUserId) async {
    try {
      print('🗑️ حذف مناقشة: $discussionId');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 10));

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(getResponse.body);
      List<dynamic> discussions = [];

      if (data['record'] != null && data['record']['discussions'] != null) {
        discussions = List<dynamic>.from(data['record']['discussions']);
      } else if (data['discussions'] != null) {
        discussions = List<dynamic>.from(data['discussions']);
      } else {
        return false;
      }

      final int oldCount = discussions.length;
      discussions.removeWhere((disc) => disc['id'] == discussionId);

      if (discussions.length == oldCount) return false;

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode({'discussions': discussions}),
          )
          .timeout(const Duration(seconds: 15));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        await _cacheDiscussions(await _fetchFromApi());
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  // ✅ حذف أي مناقشة للمؤسس
  Future<bool> deleteAnyDiscussion(String discussionId) async {
    try {
      print('👑 حذف بواسطة المؤسس: $discussionId');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 10));

      if (getResponse.statusCode != 200) return false;

      final data = jsonDecode(getResponse.body);
      List<dynamic> discussions = [];

      if (data['record'] != null && data['record']['discussions'] != null) {
        discussions = List<dynamic>.from(data['record']['discussions']);
      } else if (data['discussions'] != null) {
        discussions = List<dynamic>.from(data['discussions']);
      } else {
        return false;
      }

      discussions.removeWhere((disc) => disc['id'] == discussionId);

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode({'discussions': discussions}),
          )
          .timeout(const Duration(seconds: 15));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        await _cacheDiscussions(await _fetchFromApi());
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ: $e');
      return false;
    }
  }

  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<bool> testConnection() async {
    return true;
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDiscussionsKey);
    await prefs.remove(_lastUpdateKey);
  }
}
