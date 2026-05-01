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
      try {
        final List<dynamic> decoded = jsonDecode(cachedData);
        return decoded.map((json) => QuestionModel.fromMap(json)).toList();
      } catch (e) {
        print('خطأ في قراءة الكاش: $e');
      }
    }
    return await _fetchFromApi();
  }

  Future<List<QuestionModel>> _fetchFromApi() async {
    try {
      final response = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

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

        final List<QuestionModel> questions = [];
        for (final item in questionsJson) {
          if (item is Map<String, dynamic>) {
            questions.add(QuestionModel.fromMap(item));
          }
        }

        await _cacheQuestions(questions);
        return questions;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _cacheQuestions(List<QuestionModel> questions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> list =
        questions.map((q) => q.toMap()).toList();
    await prefs.setString(_cachedQuestionsKey, jsonEncode(list));
  }

  Future<bool> addQuestion(
      String userId, String userName, String title, String content) async {
    try {
      final getResponse = await http.get(
        Uri.parse(_publicUrl),
        headers: {'X-Master-Key': _masterKey},
      ).timeout(const Duration(seconds: 15));

      if (getResponse.statusCode != 200) {
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
      return false;
    }
  }

  Future<bool> addReply(
      String questionId, String userId, String userName, String content) async {
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

      if (questionIndex == -1) {
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
        return true;
      }
      return false;
    } catch (e) {
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
      return false;
    }
  }

  Future<bool> deleteQuestion(
      String questionId, String currentUserId, bool isFounder) async {
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
      final String questionOwnerId = question['userId']?.toString() ?? '';

      if (!isFounder && questionOwnerId != currentUserId) {
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
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReply(String questionId, String replyId,
      String currentUserId, bool isFounder) async {
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
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedQuestionsKey);
  }
}