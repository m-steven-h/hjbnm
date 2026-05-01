import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/prayer_road_model.dart';
import '../services/notification_service.dart';

class PrayerRoadNotificationsPage extends StatefulWidget {
  const PrayerRoadNotificationsPage({super.key});

  @override
  State<PrayerRoadNotificationsPage> createState() =>
      _PrayerRoadNotificationsPageState();
}

class _PrayerRoadNotificationsPageState
    extends State<PrayerRoadNotificationsPage>
    with SingleTickerProviderStateMixin {
  late PrayerRoadModel _model;
  bool _isLoading = true;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  Future<void> _loadData() async {
    _model = PrayerRoadModel();
    await _model.loadData();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (_isLoading) {
          return Scaffold(
            backgroundColor: themeProvider.backgroundColor,
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4ADE80),
              ),
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: themeProvider.backgroundColor,
            appBar: AppBar(
              backgroundColor: themeProvider.cardColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4ADE80)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'إشعارات طريق الصلاة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * themeProvider.fontScale,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  FadeTransition(
                    opacity: _fadeAnimations[0],
                    child: SlideTransition(
                      position: _slideAnimations[0],
                      child: _buildNotificationToggleCard(themeProvider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationToggleCard(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'الإشعارات اليومية',
          style: GoogleFonts.cairo(
            fontSize: 18 * themeProvider.fontScale,
            fontWeight: FontWeight.bold,
            color: themeProvider.textColor,
          ),
        ),
        subtitle: Text(
          _model.notificationsEnabled ? 'الإشعارات مفعلة' : 'الإشعارات معطلة',
          style: GoogleFonts.cairo(
            fontSize: 14 * themeProvider.fontScale,
            color: _model.notificationsEnabled
                ? const Color(0xFF4ADE80)
                : themeProvider.secondaryTextColor,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _model.notificationsEnabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: const Color(0xFF4ADE80),
            size: 28,
          ),
        ),
        value: _model.notificationsEnabled,
        activeColor: const Color(0xFF4ADE80),
        onChanged: (value) async {
          _model.setNotificationsEnabled(value);

          final notificationService = NotificationService();
          if (value) {
            await notificationService.initialize();
            await notificationService.schedulePrayerRoadNotification(
              title: _model.getNotificationTitle(),
              body: _model.getNotificationBody(),
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم تفعيل الإشعارات اليومية (الساعة 1:00 ظهراً)',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: const Color(0xFF4ADE80),
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() {});
            }
          } else {
            await notificationService.cancelNotification(1001);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم إيقاف الإشعارات',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: Colors.grey,
                  duration: const Duration(seconds: 2),
                ),
              );
              setState(() {});
            }
          }
        },
      ),
    );
  }

  Widget _buildScheduleInfoCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF4ADE80).withOpacity(0.1),
            const Color(0xFF22C55E).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF4ADE80),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'مواعيد الإشعارات',
                style: GoogleFonts.cairo(
                  fontSize: 18 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            themeProvider,
            Icons.wb_sunny_rounded,
            'الإشعار الصباحي',
            'الساعة 1:00 ظهراً - تذكير ببدء اليوم الجديد',
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            themeProvider,
            Icons.notifications_active_rounded,
            'الإشعار التذكيري',
            'الساعة 8:00 مساءً - تذكير بإكمال اليوم إذا لم تكتمل',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            themeProvider,
            Icons.celebration_rounded,
            'إشعار الإكمال',
            'يتم إرساله فور إكمال اليوم بنجاح',
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeProvider themeProvider,
    IconData icon,
    String title,
    String description,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 14 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.cairo(
                  fontSize: 12 * themeProvider.fontScale,
                  color: themeProvider.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF4ADE80),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات مهمة',
                style: GoogleFonts.cairo(
                  fontSize: 16 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(ThemeProvider themeProvider, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF4ADE80),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(
              fontSize: 13 * themeProvider.fontScale,
              color: themeProvider.secondaryTextColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
