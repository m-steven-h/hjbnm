// lib/services/questions_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';
import '../secrets.dart';

class QuestionsService {
  static const String _binId = Secrets.binId;
  static const String _masterKey = Secrets.masterKey;
  static const String _publicUrl = 'https://api.jsonbin.io/v3/b/$_binId/latest';
  static const String _writeUrl = 'https://api.jsonbin.io/v3/b/$_binId';

  static const String _cachedQuestionsKey = 'cached_questions';

  Future<List<QuestionModel>> getQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cachedQuestionsKey);

    if (cachedData != null) {
      print('📦 جلب الأسئلة من الكاش');
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        return decoded.map((json) => QuestionModel.fromMap(json)).toList();
      } catch (e) {
        print('❌ خطأ في قراءة الكاش: $e');
      }
    }
    return await _fetchFromApi();
  }

  Future<List<QuestionModel>> _fetchFromApi() async {
    try {
      print('🌐 جلب الأسئلة من API...');
      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      print('📥 GET Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        List<dynamic> questionsJson = [];

        if (data.containsKey('record') && data['record'] != null) {
          final dynamic record = data['record'];
          if (record is Map<String, dynamic>) {
            if (record.containsKey('questions') &&
                record['questions'] != null) {
              final dynamic questionsData = record['questions'];
              if (questionsData is List) {
                questionsJson = questionsData;
              }
            }
          } else if (record is List) {
            questionsJson = record;
          }
        } else if (data.containsKey('questions') && data['questions'] != null) {
          final dynamic questionsData = data['questions'];
          if (questionsData is List) {
            questionsJson = questionsData;
          }
        }

        print('📊 عدد الأسئلة المستلمة: ${questionsJson.length}');

        final List<QuestionModel> questions = [];
        for (final item in questionsJson) {
          if (item is Map<String, dynamic>) {
            questions.add(QuestionModel.fromMap(item));
          }
        }

        await _cacheQuestions(questions);
        return questions;
      }
      print('❌ فشل GET: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ فشل الجلب: $e');
      return [];
    }
  }

  Future<void> _cacheQuestions(List<QuestionModel> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> list =
        questions.map((q) => q.toMap()).toList();
    await prefs.setString(_cachedQuestionsKey, jsonEncode(list));
    print('💾 تم تخزين ${questions.length} سؤال في الكاش');
  }

  Future<bool> addQuestion(
      String userId, String userName, String title, String content) async {
    try {
      print('========================================');
      print('📝 بدء إضافة سؤال جديد');
      print('👤 userId: $userId');
      print('🏷️ title: $title');
      print('========================================');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      print('📥 GET Status: ${getResponse.statusCode}');

      if (getResponse.statusCode != 200) {
        print('❌ فشل جلب البيانات الحالية');
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(getResponse.body);

      List<dynamic> questions = [];

      if (data.containsKey('record') && data['record'] != null) {
        final dynamic record = data['record'];
        if (record is Map<String, dynamic>) {
          if (record.containsKey('questions') && record['questions'] != null) {
            final dynamic questionsData = record['questions'];
            if (questionsData is List) {
              questions = questionsData;
            }
          }
        }
      } else if (data.containsKey('questions') && data['questions'] != null) {
        final dynamic questionsData = data['questions'];
        if (questionsData is List) {
          questions = questionsData;
        }
      }

      print('📊 عدد الأسئلة الحالي: ${questions.length}');

      final Map<String, dynamic> newQuestion = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'userName': userName,
        'title': title,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'likedBy': <String>[],
        'replies': <dynamic>[],
      };

      questions.insert(0, newQuestion);
      print('📊 عدد الأسئلة بعد الإضافة: ${questions.length}');

      final Map<String, dynamic> newData = {
        'questions': questions,
      };

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode(newData),
          )
          .timeout(const Duration(seconds: 20));

      print('📤 PUT Status: ${putResponse.statusCode}');

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        final updatedQuestions = await _fetchFromApi();
        await _cacheQuestions(updatedQuestions);
        print('✅ تم إضافة السؤال بنجاح');
        return true;
      }

      print('❌ فشل الحفظ في JSONBin');
      return false;
    } catch (e) {
      print('❌ استثناء في addQuestion: $e');
      return false;
    }
  }

  Future<bool> addReply(
      String questionId, String userId, String userName, String content) async {
    try {
      print('💬 بدء إضافة رد على السؤال: $questionId');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      if (getResponse.statusCode != 200) return false;

      final Map<String, dynamic> data = jsonDecode(getResponse.body);

      List<dynamic> questions = [];

      if (data.containsKey('record') && data['record'] != null) {
        final dynamic record = data['record'];
        if (record is Map<String, dynamic>) {
          if (record.containsKey('questions') && record['questions'] != null) {
            final dynamic questionsData = record['questions'];
            if (questionsData is List) {
              questions = questionsData;
            }
          }
        }
      } else if (data.containsKey('questions') && data['questions'] != null) {
        final dynamic questionsData = data['questions'];
        if (questionsData is List) {
          questions = questionsData;
        }
      } else {
        return false;
      }

      int questionIndex = -1;
      for (int i = 0; i < questions.length; i++) {
        final Map<String, dynamic> q = questions[i] as Map<String, dynamic>;
        if (q['id'] == questionId) {
          questionIndex = i;
          break;
        }
      }

      if (questionIndex == -1) {
        print('❌ لم يتم العثور على السؤال');
        return false;
      }

      final Map<String, dynamic> newReply = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'userName': userName,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'likedBy': <String>[],
      };

      final Map<String, dynamic> question =
          questions[questionIndex] as Map<String, dynamic>;
      if (question['replies'] == null) {
        question['replies'] = <dynamic>[];
      }
      (question['replies'] as List<dynamic>).insert(0, newReply);

      final Map<String, dynamic> newData = {
        'questions': questions,
      };

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode(newData),
          )
          .timeout(const Duration(seconds: 20));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        final updatedQuestions = await _fetchFromApi();
        await _cacheQuestions(updatedQuestions);
        print('✅ تم إضافة الرد بنجاح');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في addReply: $e');
      return false;
    }
  }

  Future<bool> toggleLike(String questionId, String userId,
      {String? replyId}) async {
    try {
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      if (getResponse.statusCode != 200) return false;

      final Map<String, dynamic> data = jsonDecode(getResponse.body);

      List<dynamic> questions = [];

      if (data.containsKey('record') && data['record'] != null) {
        final dynamic record = data['record'];
        if (record is Map<String, dynamic>) {
          if (record.containsKey('questions') && record['questions'] != null) {
            final dynamic questionsData = record['questions'];
            if (questionsData is List) {
              questions = questionsData;
            }
          }
        }
      } else if (data.containsKey('questions') && data['questions'] != null) {
        final dynamic questionsData = data['questions'];
        if (questionsData is List) {
          questions = questionsData;
        }
      } else {
        return false;
      }

      int questionIndex = -1;
      for (int i = 0; i < questions.length; i++) {
        final Map<String, dynamic> q = questions[i] as Map<String, dynamic>;
        if (q['id'] == questionId) {
          questionIndex = i;
          break;
        }
      }
      if (questionIndex == -1) return false;

      final Map<String, dynamic> question =
          questions[questionIndex] as Map<String, dynamic>;

      if (replyId == null) {
        List<dynamic> likedBy = (question['likedBy'] as List<dynamic>?) ?? [];
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }
        question['likedBy'] = likedBy;
      } else {
        final List<dynamic> replies =
            (question['replies'] as List<dynamic>?) ?? [];
        int replyIndex = -1;
        for (int i = 0; i < replies.length; i++) {
          final Map<String, dynamic> r = replies[i] as Map<String, dynamic>;
          if (r['id'] == replyId) {
            replyIndex = i;
            break;
          }
        }
        if (replyIndex == -1) return false;

        final Map<String, dynamic> reply =
            replies[replyIndex] as Map<String, dynamic>;
        List<dynamic> likedBy = (reply['likedBy'] as List<dynamic>?) ?? [];
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }
        reply['likedBy'] = likedBy;
      }

      final Map<String, dynamic> newData = {
        'questions': questions,
      };

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode(newData),
          )
          .timeout(const Duration(seconds: 20));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        final updatedQuestions = await _fetchFromApi();
        await _cacheQuestions(updatedQuestions);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في toggleLike: $e');
      return false;
    }
  }

  Future<bool> deleteQuestion(
      String questionId, String currentUserId, bool isFounder) async {
    try {
      print('🗑️ حذف سؤال: $questionId');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      if (getResponse.statusCode != 200) return false;

      final Map<String, dynamic> data = jsonDecode(getResponse.body);

      List<dynamic> questions = [];

      if (data.containsKey('record') && data['record'] != null) {
        final dynamic record = data['record'];
        if (record is Map<String, dynamic>) {
          if (record.containsKey('questions') && record['questions'] != null) {
            final dynamic questionsData = record['questions'];
            if (questionsData is List) {
              questions = questionsData;
            }
          }
        }
      } else if (data.containsKey('questions') && data['questions'] != null) {
        final dynamic questionsData = data['questions'];
        if (questionsData is List) {
          questions = questionsData;
        }
      } else {
        return false;
      }

      int questionIndex = -1;
      for (int i = 0; i < questions.length; i++) {
        final Map<String, dynamic> q = questions[i] as Map<String, dynamic>;
        if (q['id'] == questionId) {
          questionIndex = i;
          break;
        }
      }
      if (questionIndex == -1) return false;

      final Map<String, dynamic> question =
          questions[questionIndex] as Map<String, dynamic>;
      final String questionOwnerId = question['userId']?.toString() ?? '';

      if (!isFounder && questionOwnerId != currentUserId) {
        print('❌ غير مصرح بالحذف');
        return false;
      }

      questions.removeAt(questionIndex);

      final Map<String, dynamic> newData = {
        'questions': questions,
      };

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode(newData),
          )
          .timeout(const Duration(seconds: 20));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        final updatedQuestions = await _fetchFromApi();
        await _cacheQuestions(updatedQuestions);
        print('✅ تم حذف السؤال');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في deleteQuestion: $e');
      return false;
    }
  }

  Future<bool> deleteReply(String questionId, String replyId,
      String currentUserId, bool isFounder) async {
    try {
      print('🗑️ حذف رد: $replyId');

      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      if (getResponse.statusCode != 200) return false;

      final Map<String, dynamic> data = jsonDecode(getResponse.body);

      List<dynamic> questions = [];

      if (data.containsKey('record') && data['record'] != null) {
        final dynamic record = data['record'];
        if (record is Map<String, dynamic>) {
          if (record.containsKey('questions') && record['questions'] != null) {
            final dynamic questionsData = record['questions'];
            if (questionsData is List) {
              questions = questionsData;
            }
          }
        }
      } else if (data.containsKey('questions') && data['questions'] != null) {
        final dynamic questionsData = data['questions'];
        if (questionsData is List) {
          questions = questionsData;
        }
      } else {
        return false;
      }

      int questionIndex = -1;
      for (int i = 0; i < questions.length; i++) {
        final Map<String, dynamic> q = questions[i] as Map<String, dynamic>;
        if (q['id'] == questionId) {
          questionIndex = i;
          break;
        }
      }
      if (questionIndex == -1) return false;

      final Map<String, dynamic> question =
          questions[questionIndex] as Map<String, dynamic>;
      final String questionOwnerId = question['userId']?.toString() ?? '';

      final List<dynamic> replies =
          (question['replies'] as List<dynamic>?) ?? [];
      int replyIndex = -1;
      for (int i = 0; i < replies.length; i++) {
        final Map<String, dynamic> r = replies[i] as Map<String, dynamic>;
        if (r['id'] == replyId) {
          replyIndex = i;
          break;
        }
      }
      if (replyIndex == -1) return false;

      final Map<String, dynamic> reply =
          replies[replyIndex] as Map<String, dynamic>;
      final String replyOwnerId = reply['userId']?.toString() ?? '';

      if (!isFounder &&
          replyOwnerId != currentUserId &&
          questionOwnerId != currentUserId) {
        print('❌ غير مصرح بحذف الرد');
        return false;
      }

      replies.removeAt(replyIndex);
      question['replies'] = replies;

      final Map<String, dynamic> newData = {
        'questions': questions,
      };

      final putResponse = await http
          .put(
            Uri.parse(_writeUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Master-Key': _masterKey,
            },
            body: jsonEncode(newData),
          )
          .timeout(const Duration(seconds: 20));

      if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
        final updatedQuestions = await _fetchFromApi();
        await _cacheQuestions(updatedQuestions);
        print('✅ تم حذف الرد');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ خطأ في deleteReply: $e');
      return false;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedQuestionsKey);
    print('🗑️ تم مسح الكاش');
  }
}
