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

  // ✅ مفاتيح التخزين المحلي
  static const String _cachedDiscussionsKey = 'cached_discussions';
  static const String _lastUpdateKey = 'last_discussions_update';

  // ✅ جلب المناقشات (مع التخزين المحلي)
  Future<List<DiscussionModel>> getDiscussions(
      {bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ لو مش forcRefresh، جرب تجيب من الكاش أولاً
    if (!forceRefresh) {
      final cachedData = prefs.getString(_cachedDiscussionsKey);
      if (cachedData != null) {
        print('📦 جلب المناقشات من التخزين المحلي');
        final List<dynamic> decoded = jsonDecode(cachedData);
        final discussions =
            decoded.map((json) => DiscussionModel.fromMap(json)).toList();

        // ✅ لو في نت، نحاول نجلب بيانات جديدة في الخلفية (silent update)
        _fetchAndCacheInBackground();

        return discussions;
      }
    }

    // ✅ جلب من الإنترنت
    try {
      print('🌐 جلب المناقشات من الإنترنت...');

      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> discussionsJson = [];

        if (data['record'] != null && data['record']['discussions'] != null) {
          discussionsJson = data['record']['discussions'];
        } else if (data['discussions'] != null) {
          discussionsJson = data['discussions'];
        } else {
          discussionsJson = [];
        }

        print('✅ تم جلب ${discussionsJson.length} مناقشة من الإنترنت');

        // ✅ تحويل البيانات
        final discussions = discussionsJson.map((json) {
          return DiscussionModel(
            id: json['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            userName: json['userName']?.toString() ?? 'مستخدم',
            userImage: json['userImage']?.toString() ?? 'assets/icon/icon.png',
            content: json['content']?.toString() ?? '',
            createdAt: json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString())
                : DateTime.now(),
            isFromUser: false,
          );
        }).toList();

        // ✅ حفظ في التخزين المحلي
        await _cacheDiscussions(discussions);

        return discussions;
      } else {
        print('⚠️ خطأ في الاستجابة: ${response.statusCode}');
        // ✅ لو فشل الجلب من النت، جرب الكاش
        return _getCachedDiscussions();
      }
    } catch (e) {
      print('⚠️ فشل الاتصال بالإنترنت: $e');
      // ✅ لو مفيش نت، جيب من الكاش
      return _getCachedDiscussions();
    }
  }

  // ✅ دالة لجلب البيانات من الكاش
  Future<List<DiscussionModel>> _getCachedDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedDiscussionsKey);

    if (cachedData != null) {
      print('📦 جلب من الكاش (بدون نت)');
      final List<dynamic> decoded = jsonDecode(cachedData);
      return decoded.map((json) => DiscussionModel.fromMap(json)).toList();
    }

    print('❌ لا توجد بيانات مخزنة محلياً');
    return [];
  }

  // ✅ دالة لحفظ المناقشات في الكاش
  Future<void> _cacheDiscussions(List<DiscussionModel> discussions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> discussionsMap =
        discussions.map((d) => d.toMap()).toList();
    await prefs.setString(_cachedDiscussionsKey, jsonEncode(discussionsMap));
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    print('💾 تم حفظ ${discussions.length} مناقشة في التخزين المحلي');
  }

  // ✅ دالة لتحديث الكاش في الخلفية (silent update)
  Future<void> _fetchAndCacheInBackground() async {
    try {
      print('🔄 تحديث الخلفي للمناقشات...');

      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> discussionsJson = [];

        if (data['record'] != null && data['record']['discussions'] != null) {
          discussionsJson = data['record']['discussions'];
        } else if (data['discussions'] != null) {
          discussionsJson = data['discussions'];
        }

        final discussions = discussionsJson.map((json) {
          return DiscussionModel(
            id: json['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            userName: json['userName']?.toString() ?? 'مستخدم',
            userImage: json['userImage']?.toString() ?? 'assets/icon/icon.png',
            content: json['content']?.toString() ?? '',
            createdAt: json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString())
                : DateTime.now(),
            isFromUser: false,
          );
        }).toList();

        await _cacheDiscussions(discussions);
        print('✅ تحديث الخلفي ناجح - ${discussions.length} مناقشة');
      }
    } catch (e) {
      print('⚠️ فشل التحديث الخلفي: $e');
    }
  }

  // ✅ إضافة مناقشة جديدة (مع تحديث الكاش)
  Future<bool> addDiscussion(String userName, String content) async {
    try {
      print('📝 محاولة إضافة مناقشة جديدة...');

      // جلب المناقشات الحالية
      final currentDiscussions = await getDiscussions(forceRefresh: true);

      List<Map<String, dynamic>> discussionsList =
          currentDiscussions.map((disc) {
        return {
          'id': disc.id,
          'userName': disc.userName,
          'userImage': disc.userImage,
          'content': disc.content,
          'createdAt': disc.createdAt?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        };
      }).toList();

      // إضافة المناقشة الجديدة
      final newDiscussion = {
        'id': 'disc_${DateTime.now().millisecondsSinceEpoch}',
        'userName': userName,
        'userImage': 'assets/icon/icon.png',
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      };

      discussionsList.insert(0, newDiscussion);

      // حفظ في JSONBin
      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode({
              'discussions': discussionsList,
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📤 حفظ - Status Code: ${putResponse.statusCode}');

      if (putResponse.statusCode == 200) {
        // ✅ تحديث الكاش بعد الإضافة
        final newDiscussions = await getDiscussions(forceRefresh: true);
        await _cacheDiscussions(newDiscussions);
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ في الإضافة: $e');
      return false;
    }
  }

  // ✅ حذف مناقشة (مع تحديث الكاش)
  Future<bool> deleteDiscussion(
      String discussionId, String currentUserName) async {
    try {
      print('🗑️ بدء عملية الحذف');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
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

      int indexToRemove = -1;
      for (int i = 0; i < discussions.length; i++) {
        if (discussions[i]['id'] == discussionId) {
          if (discussions[i]['userName'] == currentUserName) {
            indexToRemove = i;
            break;
          } else {
            return false;
          }
        }
      }

      if (indexToRemove == -1) return false;

      discussions.removeAt(indexToRemove);

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

      if (putResponse.statusCode == 200) {
        // ✅ تحديث الكاش بعد الحذف
        final newDiscussions = await getDiscussions(forceRefresh: true);
        await _cacheDiscussions(newDiscussions);
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ في الحذف: $e');
      return false;
    }
  }

  // ✅ حذف أي مناقشة (للمؤسس) مع تحديث الكاش
  Future<bool> deleteAnyDiscussion(String discussionId) async {
    try {
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
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

      if (putResponse.statusCode == 200) {
        // ✅ تحديث الكاش بعد الحذف
        final newDiscussions = await getDiscussions(forceRefresh: true);
        await _cacheDiscussions(newDiscussions);
        return true;
      }

      return false;
    } catch (e) {
      print('❌ خطأ في حذف المؤسس: $e');
      return false;
    }
  }

  // ✅ دالة لمسح الكاش (ممكن تستخدمها في الإعدادات)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedDiscussionsKey);
    await prefs.remove(_lastUpdateKey);
    print('🗑️ تم مسح الكاش');
  }

  // ✅ دالة لمعرفة آخر تحديث
  Future<DateTime?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  // دالة مساعدة للتحقق من الاتصال
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
        },
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
