// lib/services/discussions_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/discussion_model.dart';
import '../secrets.dart';

class DiscussionsService {
  static const String _binId = Secrets.binId;
  static const String _masterKey = Secrets.masterKey;

  // ✅ الرابط الصحيح لقراءة البيانات
  static const String _publicUrl = 'https://api.jsonbin.io/v3/b/$_binId/latest';

  // ✅ الرابط الصحيح لكتابة/تحديث البيانات
  static const String _writeUrl = 'https://api.jsonbin.io/v3/b/$_binId';

  Future<List<DiscussionModel>> getDiscussions() async {
    try {
      print('🌐 جلب المناقشات...');

      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
      );

      print('📥 Status Code: ${response.statusCode}');
      print(
          '📥 Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ استخراج المناقشات من record
        List<dynamic> discussionsJson = [];

        if (data['record'] != null && data['record']['discussions'] != null) {
          discussionsJson = data['record']['discussions'];
        } else if (data['discussions'] != null) {
          discussionsJson = data['discussions'];
        } else {
          // لو مفيش مناقشات خالص، نبدأ بمصفوفة جديدة
          discussionsJson = [];
        }

        print('✅ تم جلب ${discussionsJson.length} مناقشة');

        return discussionsJson.map((json) {
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
      }
      return [];
    } catch (e) {
      print('❌ خطأ في الجلب: $e');
      return [];
    }
  }

  Future<bool> addDiscussion(String userName, String content) async {
    try {
      print('📝 محاولة إضافة مناقشة جديدة...');

      // 1️⃣ جلب المناقشات الحالية
      final currentDiscussions = await getDiscussions();

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

      // 2️⃣ إضافة المناقشة الجديدة
      final newDiscussion = {
        'id': 'disc_${DateTime.now().millisecondsSinceEpoch}',
        'userName': userName,
        'userImage': 'assets/icon/icon.png',
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
      };

      discussionsList.insert(0, newDiscussion);

      // 3️⃣ حفظ البيانات في JSONBin
      final putResponse = await http.put(
        Uri.parse(_writeUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
        },
        body: jsonEncode({
          'discussions': discussionsList,
        }),
      );

      print('📤 حفظ - Status Code: ${putResponse.statusCode}');
      print('📤 حفظ - Response: ${putResponse.body}');

      return putResponse.statusCode == 200;
    } catch (e) {
      print('❌ خطأ في الإضافة: $e');
      return false;
    }
  }

  // ✅ دالة الحذف المعدلة بالكامل
  Future<bool> deleteDiscussion(
      String discussionId, String currentUserName) async {
    try {
      print('🗑️ ===== بدء عملية الحذف =====');
      print('🗑️ ID المناقشة: $discussionId');
      print('👤 المستخدم الحالي: $currentUserName');

      // 1️⃣ جلب البيانات الحالية من API
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
      );

      print('📥 جلب البيانات - Status: ${getResponse.statusCode}');

      if (getResponse.statusCode != 200) {
        print('❌ فشل جلب البيانات');
        return false;
      }

      final data = jsonDecode(getResponse.body);

      // 2️⃣ استخراج المناقشات
      List<dynamic> discussions = [];

      if (data['record'] != null && data['record']['discussions'] != null) {
        discussions = List<dynamic>.from(data['record']['discussions']);
      } else if (data['discussions'] != null) {
        discussions = List<dynamic>.from(data['discussions']);
      } else {
        print('❌ لم يتم العثور على المناقشات');
        return false;
      }

      print('📊 عدد المناقشات قبل الحذف: ${discussions.length}');

      // 3️⃣ البحث عن المناقشة
      int indexToRemove = -1;
      String? discussionOwner;

      for (int i = 0; i < discussions.length; i++) {
        final disc = discussions[i];
        if (disc['id'] == discussionId) {
          indexToRemove = i;
          discussionOwner = disc['userName'];
          break;
        }
      }

      if (indexToRemove == -1) {
        print('❌ لم يتم العثور على المناقشة');
        return false;
      }

      print('👤 صاحب المناقشة: $discussionOwner');
      print('👤 المستخدم الحالي: $currentUserName');

      // 4️⃣ التحقق من الصلاحية
      if (discussionOwner != currentUserName) {
        print('❌ لا صلاحية - المستخدم $currentUserName ليس صاحب المناقشة');
        return false;
      }

      // 5️⃣ حذف المناقشة
      discussions.removeAt(indexToRemove);
      print('✅ تم الحذف - المتبقي: ${discussions.length} مناقشة');

      // 6️⃣ حفظ البيانات
      final putResponse = await http.put(
        Uri.parse(_writeUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
        },
        body: jsonEncode({'discussions': discussions}),
      );

      print('📤 حفظ بعد الحذف - Status: ${putResponse.statusCode}');
      print('📤 حفظ بعد الحذف - Response: ${putResponse.body}');

      if (putResponse.statusCode == 200) {
        print('✅ تم حذف المناقشة بنجاح');
        return true;
      } else {
        print('❌ فشل الحفظ: ${putResponse.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ خطأ في الحذف: $e');
      print('📚 تفاصيل: $stackTrace');
      return false;
    }
  }

  // ✅ دالة مساعدة لحذف أي مناقشة (للمؤسس)
  Future<bool> deleteAnyDiscussion(String discussionId) async {
    try {
      print('🗑️ ===== بدء عملية حذف (للمؤسس) =====');
      print('🗑️ ID المناقشة: $discussionId');

      // جلب البيانات
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
          'Content-Type': 'application/json',
        },
      );

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

      // حذف المناقشة
      discussions.removeWhere((disc) => disc['id'] == discussionId);

      // حفظ البيانات
      final putResponse = await http.put(
        Uri.parse(_writeUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Master-Key': _masterKey,
        },
        body: jsonEncode({'discussions': discussions}),
      );

      print('📤 حفظ بعد الحذف - Status: ${putResponse.statusCode}');
      return putResponse.statusCode == 200;
    } catch (e) {
      print('❌ خطأ في حذف المؤسس: $e');
      return false;
    }
  }

  // دالة مساعدة للتحقق من الاتصال
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {
          'X-Master-Key': _masterKey,
        },
      );
      print('🔍 اختبار الاتصال: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ فشل الاتصال: $e');
      return false;
    }
  }
}
