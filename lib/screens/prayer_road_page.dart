import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/prayer_road_model.dart';
import 'day_detail_page.dart';
import 'prayer_road_notifications_page.dart';

class PrayerRoadPage extends StatefulWidget {
  const PrayerRoadPage({super.key});

  @override
  State<PrayerRoadPage> createState() => _PrayerRoadPageState();
}

class _PrayerRoadPageState extends State<PrayerRoadPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late PrayerRoadModel _model;
  bool _isInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _model = PrayerRoadModel();
    _initData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _initData() async {
    await _model.loadData();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && _isInitialized) {
        _model.refreshAndCheck();
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _model,
      child: Consumer2<ThemeProvider, PrayerRoadModel>(
        builder: (context, themeProvider, prayerModel, child) {
          if (!_isInitialized) {
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
                    'طريق الصلاة',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4ADE80),
                      fontSize: 20 * themeProvider.fontScale,
                    ),
                  ),
                ),
                body: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
            );
          }

          final remaining = prayerModel.timeRemainingToOpenNextDay;
          final waitingHours = remaining?.inHours ?? 0;

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
                  'طريق الصلاة',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4ADE80),
                    fontSize: 20 * themeProvider.fontScale,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      prayerModel.notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: const Color(0xFF4ADE80),
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PrayerRoadNotificationsPage(),
                        ),
                      ).then((_) {
                        prayerModel.refreshAndCheck();
                        setState(() {});
                      });
                    },
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async => prayerModel.refreshAndCheck(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          _buildProgressBar(themeProvider, prayerModel),
                          const SizedBox(height: 16),
                          _buildHeaderText(themeProvider, prayerModel),
                          const SizedBox(height: 8),
                          if (prayerModel.isWaitingForNextDayToOpen)
                            _buildWaitingTimer(themeProvider, waitingHours),
                          const SizedBox(height: 12),
                          _buildDaysGrid(themeProvider, prayerModel),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(ThemeProvider themeProvider, PrayerRoadModel model) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الرحلة الروحية',
                style: GoogleFonts.cairo(
                  fontSize: 16 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(model.totalProgress * 100).toInt()}%',
                style: GoogleFonts.cairo(
                  fontSize: 20 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: model.totalProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText(ThemeProvider themeProvider, PrayerRoadModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'أيام الطريق',
            style: GoogleFonts.cairo(
              fontSize: 18 * themeProvider.fontScale,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 14, color: const Color(0xFF4ADE80)),
                const SizedBox(width: 4),
                Text(
                  'المكتمل: ${model.completedDaysCount}/60',
                  style: GoogleFonts.cairo(
                    fontSize: 12 * themeProvider.fontScale,
                    color: const Color(0xFF4ADE80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTimer(ThemeProvider themeProvider, int hours) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4ADE80).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_rounded,
                  color: Color(0xFF4ADE80), size: 24),
              const SizedBox(width: 12),
              Text(
                'انتظار فتح اليوم الجديد',
                style: GoogleFonts.cairo(
                  fontSize: 16 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  hours.toString().padLeft(2, '0'),
                  style: GoogleFonts.cairo(
                    fontSize: 32 * themeProvider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ساعة متبقية',
                  style: GoogleFonts.cairo(
                    fontSize: 12 * themeProvider.fontScale,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Color(0xFF4ADE80), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ اليوم الجديد سيفتح تلقائياً بعد انتهاء الوقت',
                    style: GoogleFonts.cairo(
                      fontSize: 12 * themeProvider.fontScale,
                      color: const Color(0xFF4ADE80),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(ThemeProvider themeProvider, PrayerRoadModel model) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: 60,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final isCompleted = model.isDayCompleted(dayNumber);
        final isOpen = model.isDayOpen(dayNumber);
        final isCurrent = dayNumber == model.currentDay;

        return _buildDayCard(
          themeProvider,
          dayNumber,
          isCompleted,
          isCurrent,
          isOpen,
          model,
        );
      },
    );
  }

  Widget _buildDayCard(
    ThemeProvider themeProvider,
    int dayNumber,
    bool isCompleted,
    bool isCurrent,
    bool isOpen,
    PrayerRoadModel model,
  ) {
    return GestureDetector(
      onTap: () {
        if (isOpen) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DayDetailPage(
                dayNumber: dayNumber,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              ),
            ),
          ).then((_) {
            model.refreshAndCheck();
            setState(() {});
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFF4ADE80).withOpacity(0.15)
              : !isOpen
                  ? themeProvider.secondaryTextColor.withOpacity(0.1)
                  : themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent && !isCompleted && isOpen
                ? const Color(0xFF4ADE80)
                : isCompleted
                    ? const Color(0xFF4ADE80).withOpacity(0.5)
                    : Colors.transparent,
            width: isCurrent ? 2 : 0,
          ),
          boxShadow: [
            if (isOpen && !isCompleted)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompleted)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF4ADE80),
                  size: 32,
                )
              else if (!isOpen)
                Icon(
                  Icons.lock_rounded,
                  color: themeProvider.secondaryTextColor.withOpacity(0.5),
                  size: 28,
                )
              else
                Text(
                  '$dayNumber',
                  style: GoogleFonts.cairo(
                    fontSize: 24 * themeProvider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'يوم',
                style: GoogleFonts.cairo(
                  fontSize: 12 * themeProvider.fontScale,
                  color: isCompleted
                      ? const Color(0xFF4ADE80)
                      : !isOpen
                          ? themeProvider.secondaryTextColor.withOpacity(0.5)
                          : themeProvider.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
