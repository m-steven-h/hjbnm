import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../providers/theme_provider.dart';
import '../secrets.dart';
import '../services/notification_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _secretCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Step management
  int _currentStep = 0; // 0: الاسم, 1: تاريخ الميلاد, 2: الإعدادات

  // Birthday - التاريخ الافتراضي هو اليوم الحالي
  DateTime _selectedBirthday = DateTime.now();

  // Settings
  ThemeModeType _selectedTheme = ThemeModeType.light;
  FontSize _selectedFontSize = FontSize.small;

  bool _isLoading = false;
  Timer? _timer;

  static const List<String> _founderNames = [
    'M STEVEN H',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _nameController.dispose();
    _secretCodeController.dispose();
    super.dispose();
  }

  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'user_${timestamp}_$random';
  }

  Future<bool> _checkIfFounder(String userName) async {
    return _founderNames.contains(userName.trim());
  }

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

  // ✅ دالة اختيار التاريخ باستخدام CalendarDatePicker
  Future<void> _selectBirthday(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: themeProvider.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.cake_rounded,
                  color: const Color(0xFF4ADE80), size: 28),
              const SizedBox(width: 12),
              Text(
                'اختر تاريخ ميلادك',
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          content: SizedBox(
            height: 320,
            width: 300,
            child: CalendarDatePicker(
              initialDate: _selectedBirthday,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              onDateChanged: (DateTime newDate) {
                setState(() {
                  _selectedBirthday = newDate;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
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
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate() && _currentStep == 0) {
      final String userName = _nameController.text.trim();
      final bool isPotentialFounder = await _checkIfFounder(userName);

      if (isPotentialFounder) {
        final bool codeValid = await _showSecretCodeDialog(context);
        if (!codeValid) {
          _showErrorSnackBar('الكود السري غير صحيح');
          return;
        }
      }

      final bool isFounder = isPotentialFounder;
      final prefs = await SharedPreferences.getInstance();

      String? userId = prefs.getString('userId');
      if (userId == null) {
        userId = _generateUserId();
        await prefs.setString('userId', userId);
      }

      await prefs.setString('userName', userName);
      await prefs.setBool('isFounder', isFounder);

      setState(() {
        _currentStep = 1;
      });
    }
  }

  Future<void> _saveBirthdayAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('birthday', _selectedBirthday.toIso8601String());

    // جدولة إشعار عيد الميلاد السنوي
    await _scheduleBirthdayNotification(_selectedBirthday);

    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _scheduleBirthdayNotification(DateTime birthday) async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    final now = DateTime.now();
    DateTime nextBirthday = DateTime(now.year, birthday.month, birthday.day);

    if (nextBirthday.isBefore(now)) {
      nextBirthday = DateTime(now.year + 1, birthday.month, birthday.day);
    }

    await notificationService.scheduleBirthdayNotification(
      userName: _nameController.text.trim(),
      birthdayDate: nextBirthday,
    );
  }

  Future<void> _saveSettingsAndFinish() async {
    setState(() => _isLoading = true);

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.setThemeMode(_selectedTheme);
    await themeProvider.setFontSize(_selectedFontSize);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
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
                ..._buildBackgroundCircles(themeProvider),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _currentStep == 0
                          ? _buildNameStep(themeProvider)
                          : (_currentStep == 1
                              ? _buildBirthdayStep(themeProvider)
                              : _buildSettingsStep(themeProvider)),
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

  // ==================== Step 1: إدخال الاسم ====================
  Widget _buildNameStep(ThemeProvider themeProvider) {
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
                  _buildLogo(themeProvider),
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
                  _buildNameTextField(themeProvider),
                  const SizedBox(height: 40),
                  _buildNextButton(
                    themeProvider,
                    onPressed: _saveUserData,
                    label: 'التالي',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== Step 2: تاريخ الميلاد (بدون تخطي) ====================
  Widget _buildBirthdayStep(ThemeProvider themeProvider) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBirthdayLogo(themeProvider),
                const SizedBox(height: 40),
                Text(
                  'عيد ميلادك متى؟',
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_nameController.text.trim()}، أخبرنا بتاريخ ميلادك\nلنحتفل معك في يومك المميز',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 40),
                _buildBirthdayPicker(themeProvider),
                const SizedBox(height: 40),
                _buildNextButton(
                  themeProvider,
                  onPressed: _saveBirthdayAndContinue,
                  label: 'التالي',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== Step 3: الإعدادات (بدون دوائر) ====================
  Widget _buildSettingsStep(ThemeProvider themeProvider) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSettingsLogo(themeProvider),
                    const SizedBox(height: 30),
                    Text(
                      'خصص تجربتك',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر الإعدادات التي تناسبك',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // خيارات المظهر
                    _buildSettingsCard(
                      themeProvider,
                      title: 'المظهر',
                      icon: Icons.palette_rounded,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildThemeOption(
                              themeProvider,
                              title: 'فاتح',
                              icon: Icons.light_mode_rounded,
                              value: ThemeModeType.light,
                              isSelected: _selectedTheme == ThemeModeType.light,
                              onTap: () {
                                setState(() {
                                  _selectedTheme = ThemeModeType.light;
                                });
                                themeProvider.setThemeMode(ThemeModeType.light);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildThemeOption(
                              themeProvider,
                              title: 'داكن',
                              icon: Icons.dark_mode_rounded,
                              value: ThemeModeType.dark,
                              isSelected: _selectedTheme == ThemeModeType.dark,
                              onTap: () {
                                setState(() {
                                  _selectedTheme = ThemeModeType.dark;
                                });
                                themeProvider.setThemeMode(ThemeModeType.dark);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // خيارات حجم الخط
                    _buildSettingsCard(
                      themeProvider,
                      title: 'حجم الخط',
                      icon: Icons.text_fields_rounded,
                      child: Column(
                        children: [
                          _buildFontSizeOption(
                            themeProvider,
                            title: 'صغير',
                            value: FontSize.small,
                            isSelected: _selectedFontSize == FontSize.small,
                            onTap: () {
                              setState(() {
                                _selectedFontSize = FontSize.small;
                              });
                              themeProvider.setFontSize(FontSize.small);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildFontSizeOption(
                            themeProvider,
                            title: 'وسط',
                            value: FontSize.medium,
                            isSelected: _selectedFontSize == FontSize.medium,
                            onTap: () {
                              setState(() {
                                _selectedFontSize = FontSize.medium;
                              });
                              themeProvider.setFontSize(FontSize.medium);
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildFontSizeOption(
                            themeProvider,
                            title: 'كبير',
                            value: FontSize.large,
                            isSelected: _selectedFontSize == FontSize.large,
                            onTap: () {
                              setState(() {
                                _selectedFontSize = FontSize.large;
                              });
                              themeProvider.setFontSize(FontSize.large);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFinishButton(themeProvider),
                    const SizedBox(height: 20), // مسافة إضافية في الأسفل
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== Widgets المساعدة ====================

  Widget _buildLogo(ThemeProvider themeProvider) {
    return Container(
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
    );
  }

  Widget _buildBirthdayLogo(ThemeProvider themeProvider) {
    return Container(
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
        Icons.cake_rounded,
        color: Color(0xFF4ADE80),
        size: 60,
      ),
    );
  }

  Widget _buildSettingsLogo(ThemeProvider themeProvider) {
    return Container(
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
        Icons.settings_rounded,
        color: Color(0xFF4ADE80),
        size: 60,
      ),
    );
  }

  Widget _buildNameTextField(ThemeProvider themeProvider) {
    return Container(
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
            color: themeProvider.secondaryTextColor.withOpacity(0.5),
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
    );
  }

  Widget _buildBirthdayPicker(ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => _selectBirthday(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF4ADE80).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF4ADE80),
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              _formatDate(_selectedBirthday),
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.textColor,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF4ADE80),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(ThemeProvider themeProvider,
      {required VoidCallback onPressed, required String label}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4ADE80),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
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
    );
  }

  Widget _buildFinishButton(ThemeProvider themeProvider) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveSettingsAndFinish,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4ADE80),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ابدأ الرحلة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsCard(ThemeProvider themeProvider,
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF4ADE80), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // خيارات المظهر (بدون دوائر)
  Widget _buildThemeOption(ThemeProvider themeProvider,
      {required String title,
      required IconData icon,
      required ThemeModeType value,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4ADE80).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4ADE80)
                : themeProvider.secondaryTextColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AnimatedRotation(
              turns: isSelected ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF4ADE80) : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF4ADE80)
                    : themeProvider.secondaryTextColor,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // خيارات حجم الخط (بدون دوائر)
  Widget _buildFontSizeOption(ThemeProvider themeProvider,
      {required String title,
      required FontSize value,
      required bool isSelected,
      required VoidCallback onTap}) {
    // حجم المعاينة بناءً على القيمة
    double previewSize;
    switch (value) {
      case FontSize.small:
        previewSize = 14;
        break;
      case FontSize.medium:
        previewSize = 18;
        break;
      case FontSize.large:
        previewSize = 22;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4ADE80).withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4ADE80)
                : themeProvider.secondaryTextColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // أيقونة حجم الخط
                Icon(
                  value == FontSize.small
                      ? Icons.text_fields_rounded
                      : (value == FontSize.medium
                          ? Icons.text_increase_rounded
                          : Icons.text_fields),
                  color: isSelected ? const Color(0xFF4ADE80) : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF4ADE80)
                        : themeProvider.textColor,
                  ),
                ),
              ],
            ),
            // معاينة حجم الخط التي تتغير فوراً
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.cairo(
                fontSize: previewSize,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF4ADE80)
                    : themeProvider.secondaryTextColor,
              ),
              child: Text('نموذج'),
            ),
          ],
        ),
      ),
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
        Positioned(
          left: positions[i].dx,
          top: positions[i].dy,
          child: Opacity(
            opacity: 0.05,
            child: Container(
              width: sizes[i],
              height: sizes[i],
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4ADE80),
              ),
            ),
          ),
        ),
      );
    }
    return circles;
  }
}
