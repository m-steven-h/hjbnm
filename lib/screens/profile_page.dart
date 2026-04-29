// screens/profile_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../secrets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'مستخدم دقيقة صلاة';
  bool _isFounder = false;

  // ✅ قائمة بأسماء المؤسسين
  static const List<String> _founderNames = [
    'مؤسس التطبيق',
    'Admin',
    'admin',
    'المؤسس',
    'مدير التطبيق',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'مستخدم دقيقة صلاة';
      _isFounder = prefs.getBool('isFounder') ?? false;
    });
  }

  Future<void> _saveUserData(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await _loadUserData();
  }

  Future<void> _saveFounderStatus(bool isFounder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFounder', isFounder);
    await _loadUserData();
  }

  // ✅ دالة عرض نافذة الكود السري - نسخة مبسطة
  Future<bool> _showSecretCodeDialog(BuildContext context) async {
    final TextEditingController codeController = TextEditingController();

    // نستخدم Completer من dart:async
    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer<ThemeProvider>(
        builder: (context, provider, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: provider.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF4ADE80),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تأكيد صلاحية المؤسس',
                    style: GoogleFonts.cairo(
                      color: provider.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'لتصبح مؤسساً، تحتاج إلى إدخال الكود السري',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: provider.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: provider.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withOpacity(0.3),
                      ),
                    ),
                    child: TextFormField(
                      controller: codeController,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      obscureText: true,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: provider.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل الكود السري',
                        hintStyle: GoogleFonts.cairo(
                          color: provider.secondaryTextColor.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (!completer.isCompleted) {
                      completer.complete(false);
                    }
                    Navigator.pop(dialogContext);
                  },
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final bool isValid = (codeController.text.trim() ==
                        Secrets.founderSecretCode);
                    if (!completer.isCompleted) {
                      completer.complete(isValid);
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('تأكيد'),
                ),
              ],
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  // ✅ دالة التحقق من الاسم الجديد
  Future<bool> _checkAndUpdateName(
      BuildContext context, String newName, String oldName) async {
    // لو الاسم ما اتغيرش
    if (newName == oldName) {
      return false;
    }

    final bool isNewNameFounder = _founderNames.contains(newName.trim());
    final bool wasFounder = _isFounder;

    // حالة 1: المستخدم كان عادي وعايز يبقى مؤسس (باسم مؤسس)
    if (!wasFounder && isNewNameFounder) {
      final bool codeVerified = await _showSecretCodeDialog(context);
      if (codeVerified) {
        await _saveFounderStatus(true);
        await _saveUserData(newName);
        _showSuccessSnackBar(context, 'تم تحديث الاسم وصلاحيات المؤسس');
        return true;
      } else {
        _showErrorSnackBar(context, 'الكود السري غير صحيح، لم يتم تحديث الاسم');
        return false;
      }
    }
    // حالة 2: المستخدم كان مؤسس وعايز يغير اسمه لاسم عادي
    else if (wasFounder && !isNewNameFounder) {
      await _saveFounderStatus(false);
      await _saveUserData(newName);
      _showSuccessSnackBar(context, 'تم تحديث الاسم (أصبحت مستخدم عادي)');
      return true;
    }
    // حالة 3: المستخدم كان مؤسس وعايز يغير اسمه لاسم مؤسس تاني
    else if (wasFounder && isNewNameFounder) {
      await _saveUserData(newName);
      _showSuccessSnackBar(context, 'تم تحديث الاسم');
      return true;
    }
    // حالة 4: المستخدم عادي وعايز يغير اسمه لاسم عادي تاني
    else {
      await _saveUserData(newName);
      _showSuccessSnackBar(context, 'تم تحديث الاسم');
      return true;
    }
  }

  void _showEditDialog(BuildContext context, ThemeProvider provider) {
    final TextEditingController controller =
        TextEditingController(text: _userName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: provider.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'تعديل الاسم',
              style: GoogleFonts.cairo(
                color: provider.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20 * provider.fontScale,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'يمكنك تغيير اسم المستخدم الخاص بك',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: provider.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 16 * provider.fontScale,
                      color: provider.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'أدخل اسمك',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 14 * provider.fontScale,
                        color: provider.secondaryTextColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF4ADE80),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال اسمك';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم قصير جداً';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'إلغاء',
                  style: GoogleFonts.cairo(
                    fontSize: 16 * provider.fontScale,
                    color: Colors.grey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newName = controller.text.trim();
                    // ✅ إغلاق نافذة التعديل أولاً
                    Navigator.pop(dialogContext);

                    // ✅ بعد إغلاق النافذة، نبدأ عملية التحقق
                    // نستخدم Future.microtask عشان نتأكد إن النافذة اتباعت
                    Future.microtask(() async {
                      final success = await _checkAndUpdateName(
                        context,
                        newName,
                        _userName,
                      );
                      if (success && mounted) {
                        await _loadUserData();
                        setState(() {});
                      }
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'حفظ',
                  style: GoogleFonts.cairo(
                    fontSize: 16 * provider.fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF4ADE80),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: provider.backgroundColor,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildProfileCard(provider),
                      const SizedBox(height: 20),
                      _buildEditButton(provider),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeProvider provider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: _isFounder
              ? [const Color(0xFF4ADE80), const Color(0xFF059669)]
              : [const Color(0xFF4ADE80), const Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            if (_isFounder)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'مؤسس التطبيق',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              _userName,
              style: GoogleFonts.cairo(
                fontSize: 28 * provider.fontScale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isFounder ? 'مدير التطبيق' : 'عضو في دقيقة صلاة',
                style: GoogleFonts.cairo(
                  fontSize: 14 * provider.fontScale,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(ThemeProvider provider) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, provider),
      child: Container(
        decoration: BoxDecoration(
          color: provider.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4ADE80).withOpacity(0.15),
                      const Color(0xFF4ADE80).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF4ADE80),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تعديل اسم المستخدم',
                      style: GoogleFonts.cairo(
                        fontSize: 18 * provider.fontScale,
                        fontWeight: FontWeight.w600,
                        color: provider.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يمكنك تغيير اسمك في أي وقت',
                      style: GoogleFonts.cairo(
                        fontSize: 12 * provider.fontScale,
                        color: provider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
