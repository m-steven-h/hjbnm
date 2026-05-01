import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ContentService {
  static const String _gistUrl =
      'https://gist.githubusercontent.com/m-steven-h/4f2bc283fe0bc174a2bca860c6d482ce/raw/fac413e08c907faead90b32bd0819b7edc7877cb/benefit_words.json';

  static const String _savedWordsKey = 'saved_benefit_words';
  static const String _savedVersionKey = 'saved_version';

  Future<List<Map<String, dynamic>>> getBenefitWords() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      print('محاولة جلب البيانات من الإنترنت...');
      final response = await http
          .get(Uri.parse(_gistUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await prefs.setString(_savedWordsKey, response.body);
        await prefs.setInt(_savedVersionKey, data['version'] ?? 1);

        print('تم جلب وحفظ البيانات الجديدة');
        return List<Map<String, dynamic>>.from(data['words']);
      }
    } catch (e) {
      print('لا يوجد اتصال بالإنترنت: $e');
    }

    final savedData = prefs.getString(_savedWordsKey);
    if (savedData != null) {
      print('جلب البيانات من التخزين المحلي');
      final data = jsonDecode(savedData);
      return List<Map<String, dynamic>>.from(data['words']);
    }

    print('لا توجد بيانات متاحة');
    return [];
  }

  Future<void> refreshManually() async {
    try {
      final response = await http
          .get(Uri.parse(_gistUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedWordsKey, response.body);

        final data = jsonDecode(response.body);
        await prefs.setInt(_savedVersionKey, data['version'] ?? 1);
        print('تم التحديث اليدوي بنجاح');
      }
    } catch (e) {
      print('فشل التحديث: $e');
    }
  }
}