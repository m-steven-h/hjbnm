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

    // بدء المؤقت فقط إذا كان اليوم هو اليوم الحالي وغير مكتمل
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
        try {
          await notificationService.updateDailyNotification(
            _model.getNotificationTitle(),
            _model.getNotificationBody(),
          );
        } catch (e) {
          print('Error updating notification: $e');
          // الإشعارات ليست ضرورية لإكمال اليوم
        }
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
                    'أكملت اليوم ${widget.dayNumber} بنجاح!',
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
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.orange, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    '⚠️ لم يتم العثور على بيانات اليوم ${widget.dayNumber}',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: themeProvider.secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                    ),
                    child: const Text('العودة'),
                  ),
                ],
              ),
            ),
          );
        }

        final isDayCompleted = _model.completedDays.contains(widget.dayNumber);
        final isDayMissed = _model.missedDays.contains(widget.dayNumber);
        final isCurrentDay = widget.dayNumber == _model.currentDay;
        final showCompleteButton =
            isCurrentDay && !isDayCompleted && !isDayMissed;

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
                dayData.title.isNotEmpty
                    ? dayData.title
                    : 'اليوم ${widget.dayNumber}',
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
                    padding: const EdgeInsets.only(left: 16),
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
                            '✓ مكتمل',
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
                if (isDayMissed)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '⚠️ فائت',
                            style: GoogleFonts.cairo(
                              fontSize: 12 * themeProvider.fontScale,
                              color: Colors.orange,
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
                  _buildReflectionCard(themeProvider, dayData),
                  const SizedBox(height: 16),
                  _buildPrayerCard(themeProvider, dayData),
                  const SizedBox(height: 16),
                  _buildEncouragementCard(themeProvider, dayData),
                  const SizedBox(height: 24),
                  if (showCompleteButton) _buildCompleteButton(themeProvider),
                  if (isDayCompleted && isCurrentDay)
                    _buildCompletionMessage(themeProvider),
                  if (isDayCompleted && !isCurrentDay)
                    _buildAlreadyCompletedMessage(themeProvider),
                  if (isDayMissed)
                    _buildMissedDayMessage(themeProvider, dayData),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReflectionCard(ThemeProvider themeProvider, PrayerDay dayData) {
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
                child: const Icon(Icons.auto_stories_rounded,
                    color: Color(0xFF4ADE80), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'تأمل اليوم',
                style: GoogleFonts.cairo(
                  fontSize: 18 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dayData.verse.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeProvider.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${dayData.verse}"',
                style: GoogleFonts.cairo(
                  fontSize: 16 * themeProvider.fontScale,
                  fontStyle: FontStyle.italic,
                  color: themeProvider.textColor,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          if (dayData.reflection.isNotEmpty)
            Text(
              dayData.reflection,
              style: GoogleFonts.cairo(
                fontSize: 15 * themeProvider.fontScale,
                color: themeProvider.secondaryTextColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          if (dayData.verse.isEmpty && dayData.reflection.isEmpty)
            _buildEmptyContent(
                themeProvider, 'لم يتم إضافة محتوى لهذا اليوم بعد'),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(ThemeProvider themeProvider, PrayerDay dayData) {
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
                child: const Icon(Icons.church_rounded,
                    color: Color(0xFF4ADE80), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'صلاة اليوم',
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
            dayData.prayer.isNotEmpty
                ? dayData.prayer
                : 'لم يتم إضافة صلاة لهذا اليوم بعد',
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

  Widget _buildEncouragementCard(
      ThemeProvider themeProvider, PrayerDay dayData) {
    if (dayData.encouragement.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions_rounded,
              color: Color(0xFF4ADE80), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dayData.encouragement,
              style: GoogleFonts.cairo(
                fontSize: 14 * themeProvider.fontScale,
                color: const Color(0xFF4ADE80),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(ThemeProvider themeProvider, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '⚠️ $message',
          style: GoogleFonts.cairo(
            fontSize: 14 * themeProvider.fontScale,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
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
            minimumSize: const Size(double.infinity, 56),
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
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_remainingSeconds',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle_rounded, size: 28),
              const SizedBox(width: 12),
              Text(
                _isCompleting
                    ? 'جاري الإكمال...'
                    : (!_canComplete ? 'انتظر' : 'اكمل اليوم'),
                style: GoogleFonts.cairo(
                  fontSize: 18 * themeProvider.fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'انتظر 30 ثانية لاكمال اليوم',
            style: GoogleFonts.cairo(
              fontSize: 12 * themeProvider.fontScale,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
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
        border: Border.all(color: const Color(0xFF4ADE80), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isLastDay ? Icons.celebration_rounded : Icons.check_circle_rounded,
            color: const Color(0xFF4ADE80),
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            isLastDay
                ? '🎉 أكملت طريق الصلاة بالكامل! 🎉'
                : '✨ اليوم مكتمل بنجاح ✨',
            style: GoogleFonts.cairo(
              fontSize: 20 * themeProvider.fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4ADE80),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isLastDay
                ? 'شكراً لالتزامك برحلتك الروحية طوال 60 يوماً\nالله يبارك حياتك'
                : 'شكراً لالتزامك برحلتك الروحية\nاستعد لليوم القادم',
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
              color: Color(0xFF4ADE80), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ لقد أكملت هذا اليوم بالفعل',
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

  Widget _buildMissedDayMessage(
      ThemeProvider themeProvider, PrayerDay dayData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.orange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '⚠️ لم تتمكن من إكمال هذا اليوم في وقته',
                  style: GoogleFonts.cairo(
                    fontSize: 16 * themeProvider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'لا تيأس! يمكنك الاستمرار في الأيام القادمة بقوة.\n'
            'الله لا يريد مناك الكمال، يريد قلبك.',
            style: GoogleFonts.cairo(
              fontSize: 14 * themeProvider.fontScale,
              color: themeProvider.secondaryTextColor,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '💪 "لأنه إن سقط الصديق لا يصرع، لأن الرب يسنده" (مزمور 37:24)',
              style: GoogleFonts.cairo(
                fontSize: 12 * themeProvider.fontScale,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
