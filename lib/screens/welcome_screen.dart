// screens/welcome_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../providers/theme_provider.dart';
import '../secrets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _showNameInput = false;
  bool _showSecretInput = false;
  bool _showSuccessAnimation = false;
  Timer? _timer;

  // ✅ قائمة بأسماء المؤسسين
  static const List<String> _founderNames = [
    'مؤسس التطبيق',
    'Admin',
    'admin',
    'المؤسس',
    'مدير التطبيق',
  ];

  // ✅ دالة لتوليد ID فريد للمستخدم
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'user_${timestamp}_$random';
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _animationController.forward().then((_) {
          setState(() {
            _showNameInput = true;
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _nameController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  // ✅ دالة للتحقق من الاسم
  Future<bool> _checkIfFounder(String userName) async {
    return _founderNames.contains(userName.trim());
  }

  // ✅ دالة لعرض نافذة الكود
  Future<bool> _showSecretCodeDialog(BuildContext context) async {
    final completer = Completer<bool>();
    _secretCodeController.clear();

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
                    'كود المؤسس',
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
                    'هذا الاسم محجوز للمؤسس\nأدخل الكود السري للمتابعة',
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
                      controller: _secretCodeController,
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
                    final bool isValid = (_secretCodeController.text.trim() ==
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

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      final String userName = _nameController.text.trim();
      final bool isPotentialFounder = await _checkIfFounder(userName);

      // ✅ لو الاسم من أسماء المؤسسين، نطلب الكود
      if (isPotentialFounder) {
        final bool codeValid = await _showSecretCodeDialog(context);
        if (!codeValid) {
          _showErrorSnackBar('الكود السري غير صحيح');
          return;
        }
      }

      // ✅ تحديد إذا كان مستخدم عادي أم مؤسس
      final bool isFounder = isPotentialFounder;

      setState(() {
        _showNameInput = false;
        _showSuccessAnimation = true;
      });

      final prefs = await SharedPreferences.getInstance();

      // ✅ إنشاء userId فريد للمستخدم (مرة واحدة فقط)
      String? userId = prefs.getString('userId');
      if (userId == null) {
        userId = _generateUserId();
        await prefs.setString('userId', userId);
      }

      await prefs.setString('userName', userName);
      await prefs.setBool('isFirstTime', false);
      await prefs.setBool('isFounder', isFounder);

      print('👤 المستخدم: $userName');
      print('🆔 User ID: $userId');
      print('👑 هل هو مؤسس؟ $isFounder');

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: themeProvider.backgroundColor,
                  ),
                ),
                ..._buildBackgroundCircles(themeProvider),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_showNameInput && !_showSuccessAnimation)
                          _buildNameInput(themeProvider),
                        if (_showSuccessAnimation)
                          _buildSuccessAnimation(themeProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNameInput(ThemeProvider themeProvider) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4ADE80).withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.church_rounded,
                            color: Color(0xFF4ADE80),
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'ما اسمك؟',
                    style: GoogleFonts.cairo(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'دعنا نتعرف عليك لتبدأ رحلتك الروحية',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: themeProvider.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: themeProvider.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextFormField(
                              controller: _nameController,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.cairo(
                                fontSize: 18,
                                color: themeProvider.textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'اكتب اسمك هنا',
                                hintStyle: GoogleFonts.cairo(
                                  color: themeProvider.secondaryTextColor
                                      .withOpacity(0.5),
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
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
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, double value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: ElevatedButton(
                            onPressed: _saveUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ADE80),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                              shadowColor:
                                  const Color(0xFF4ADE80).withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'متابعة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessAnimation(ThemeProvider themeProvider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ADE80).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, double angle, child) {
                        return Transform.rotate(
                          angle: angle * 2 * 3.14159,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4ADE80).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFF4ADE80),
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    const Icon(
                      Icons.church_rounded,
                      color: Color(0xFF4ADE80),
                      size: 100,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Column(
                  children: [
                    Text(
                      'مرحباً بك',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nameController.text.trim(),
                      style: GoogleFonts.cairo(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4ADE80),
                        shadows: const [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'نتمنى لك رحلة روحية ممتعة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 50),
        Column(
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFF4ADE80),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'جاري التحميل...',
              style: GoogleFonts.cairo(
                fontSize: 12,
                color: themeProvider.secondaryTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildBackgroundCircles(ThemeProvider themeProvider) {
    final circles = <Widget>[];
    final positions = [
      const Offset(50, 100),
      const Offset(-30, 200),
      const Offset(300, 150),
      const Offset(-20, 500),
      const Offset(320, 600),
      const Offset(100, 700),
    ];
    final sizes = [120.0, 80.0, 150.0, 100.0, 90.0, 130.0];

    for (int i = 0; i < positions.length; i++) {
      circles.add(
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, double value, child) {
            return Positioned(
              left: positions[i].dx,
              top: positions[i].dy - (20 * value),
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  width: sizes[i],
                  height: sizes[i],
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4ADE80).withOpacity(0.05),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
    return circles;
  }
}
