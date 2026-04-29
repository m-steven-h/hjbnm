import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/prayer_road_model.dart';
import '../services/notification_service.dart';

class DayDetailPage extends StatefulWidget {
  final int dayNumber;
  final bool isCompleted;
  final bool isCurrent;

  const DayDetailPage({
    super.key,
    required this.dayNumber,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late PrayerRoadModel _model;
  bool _isLoading = true;
  bool _isCompleting = false;
  int _remainingSeconds = 30;
  Timer? _timer;
  bool _canComplete = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 30;
    _canComplete = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _canComplete = true;
            _remainingSeconds = 0;
          });
        }
      }
    });
  }

  Future<void> _loadData() async {
    _model = PrayerRoadModel();
    await _model.loadData();
    setState(() {
      _isLoading = false;
    });

    final isDayCompleted = _model.completedDays.contains(widget.dayNumber);
    final isCurrentDay = widget.dayNumber == _model.currentDay;
    if (isCurrentDay && !isDayCompleted) {
      _startTimer();
    }
  }

  Future<void> _completeDay() async {
    if (_isCompleting) return;
    if (!_canComplete) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      await _model.completeCurrentDay();

      final notificationService = NotificationService();
      if (_model.notificationsEnabled) {
        await notificationService.updateDailyNotification(
          _model.getNotificationTitle(),
          _model.getNotificationBody(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'أكملت اليوم ${widget.dayNumber} بنجاح',
                    style: GoogleFonts.cairo(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4ADE80),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: ${e.toString()}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
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

        final dayData = _model.getPrayerDay(widget.dayNumber);

        if (dayData == null) {
          return Scaffold(
            backgroundColor: themeProvider.backgroundColor,
            appBar: AppBar(
              backgroundColor: themeProvider.cardColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4ADE80)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'خطأ',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ),
            body: const Center(child: Text('لم يتم العثور على البيانات')),
          );
        }

        final isDayCompleted = _model.completedDays.contains(widget.dayNumber);
        final isCurrentDay = widget.dayNumber == _model.currentDay;
        final showCompleteButton = isCurrentDay && !isDayCompleted;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: themeProvider.backgroundColor,
            appBar: AppBar(
              backgroundColor: themeProvider.cardColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4ADE80)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                dayData.title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * themeProvider.fontScale,
                ),
              ),
              centerTitle: true,
              actions: [
                if (isDayCompleted)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4ADE80), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'مكتمل',
                            style: GoogleFonts.cairo(
                              fontSize: 12 * themeProvider.fontScale,
                              color: const Color(0xFF4ADE80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildContentCard(
                    themeProvider,
                    'آية اليوم',
                    dayData.verse,
                    Icons.auto_stories_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildContentCard(
                    themeProvider,
                    'صلاة اليوم',
                    dayData.prayer,
                    Icons.church_rounded,
                  ),
                  const SizedBox(height: 24),
                  if (showCompleteButton) _buildCompleteButton(themeProvider),
                  if (isDayCompleted && isCurrentDay)
                    _buildCompletionMessage(themeProvider),
                  if (isDayCompleted && !isCurrentDay)
                    _buildAlreadyCompletedMessage(themeProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentCard(
    ThemeProvider themeProvider,
    String title,
    String content,
    IconData icon,
  ) {
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
                child: Icon(icon, color: const Color(0xFF4ADE80), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 18 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 16 * themeProvider.fontScale,
              color: themeProvider.textColor,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(ThemeProvider themeProvider) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _canComplete && !_isCompleting ? _completeDay : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canComplete
                ? const Color(0xFF4ADE80)
                : const Color(0xFF4ADE80).withOpacity(0.5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCompleting)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else if (!_canComplete)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_remainingSeconds',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle_rounded, size: 24),
              const SizedBox(width: 12),
              Text(
                _isCompleting
                    ? 'جاري الإكمال...'
                    : (!_canComplete ? 'انتظر ' : 'تم إكمال اليوم'),
                style: GoogleFonts.cairo(
                  fontSize: 18 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionMessage(ThemeProvider themeProvider) {
    final isLastDay = widget.dayNumber >= 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4ADE80).withOpacity(0.2),
            const Color(0xFF22C55E).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4ADE80), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            isLastDay ? Icons.celebration_rounded : Icons.check_circle_rounded,
            color: const Color(0xFF4ADE80),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isLastDay ? 'أكملت طريق الصلاة بالكامل' : 'اليوم مكتمل',
            style: GoogleFonts.cairo(
              fontSize: 20 * themeProvider.fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4ADE80),
            ),
            textAlign: TextAlign.center,
          ),
          if (!isLastDay) const SizedBox(height: 8),
          Text(
            'شكراً لالتزامك برحلتك الروحية',
            style: GoogleFonts.cairo(
              fontSize: 14 * themeProvider.fontScale,
              color: themeProvider.secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyCompletedMessage(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لقد أكملت هذا اليوم بالفعل',
                  style: GoogleFonts.cairo(
                    fontSize: 15 * themeProvider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'يمكنك مراجعة المحتوى الروحي في أي وقت.',
                  style: GoogleFonts.cairo(
                    fontSize: 13 * themeProvider.fontScale,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
