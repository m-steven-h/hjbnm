// screens/questions_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/questions_service.dart';
import '../models/question_model.dart';
import 'question_detail_page.dart';

class QuestionsPage extends StatefulWidget {
  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage>
    with SingleTickerProviderStateMixin {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _currentUserId = '';
  String _currentUserName = '';
  bool _isFounder = false;
  final QuestionsService _questionsService = QuestionsService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadQuestions();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString('userId') ?? '';
        _currentUserName = prefs.getString('userName') ?? 'مستخدم';
        _isFounder = prefs.getBool('isFounder') ?? false;
      });
    }
  }

  Future<void> _loadQuestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final questions = await _questionsService.getQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('فشل تحميل الأسئلة');
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await _questionsService.clearCache();
      final questions = await _questionsService.getQuestions();

      if (mounted) {
        setState(() {
          _questions = questions;
          _isRefreshing = false;
        });
        _showSuccessSnackBar('تم تحديث الأسئلة');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _showErrorSnackBar('فشل تحديث الأسئلة');
      }
    }
  }

  Future<void> _toggleLikeInstant(QuestionModel question, int index) async {
    final bool wasLiked = question.isLikedBy(_currentUserId);
    final List<String> newLikedBy = List.from(question.likedBy);

    if (wasLiked) {
      newLikedBy.remove(_currentUserId);
    } else {
      newLikedBy.add(_currentUserId);
    }

    final QuestionModel updatedQuestion =
        question.copyWith(likedBy: newLikedBy);

    setState(() {
      _questions[index] = updatedQuestion;
    });

    _questionsService.toggleLike(question.id, _currentUserId).then((success) {
      if (!success && mounted) {
        setState(() {
          _questions[index] = question;
        });
        _showErrorSnackBar('فشل تحديث الإعجاب');
      }
    });
  }

  void _showAddQuestionDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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
                    child: const Icon(Icons.help_outline_rounded,
                        color: Color(0xFF4ADE80)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'اسأل سؤالك',
                    style: GoogleFonts.cairo(
                      color: provider.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(color: provider.textColor),
                      decoration: InputDecoration(
                        hintText: 'عنوان السؤال',
                        hintStyle: GoogleFonts.cairo(
                            color: provider.secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true
                          ? 'أدخل عنوان السؤال'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: contentController,
                      maxLines: 5,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(color: provider.textColor),
                      decoration: InputDecoration(
                        hintText: 'التفاصيل...',
                        hintStyle: GoogleFonts.cairo(
                            color: provider.secondaryTextColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) => value?.trim().isEmpty ?? true
                          ? 'أدخل تفاصيل سؤالك'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('إلغاء', style: GoogleFonts.cairo()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      _showLoadingSnackBar('جاري النشر...');
                      final success = await _questionsService.addQuestion(
                        _currentUserId,
                        _currentUserName,
                        titleController.text.trim(),
                        contentController.text.trim(),
                      );
                      if (success && mounted) {
                        await _refresh();
                        _showSuccessSnackBar('تم نشر سؤالك');
                      } else if (mounted) {
                        _showErrorSnackBar('فشل النشر، حاول مرة أخرى');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('نشر'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 7) return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  void _showLoadingSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.cairo())),
        ]),
        backgroundColor: const Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: GoogleFonts.cairo())),
        ]),
        backgroundColor: const Color(0xFF4ADE80),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteQuestionDialog(QuestionModel question, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text('حذف السؤال', style: GoogleFonts.cairo()),
        content: Text(
            _isFounder
                ? 'أنت كمؤسس، هل تريد حذف هذا السؤال؟'
                : 'هل تريد حذف سؤالك؟',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              _showLoadingSnackBar('جاري حذف السؤال...');

              final success = await _questionsService.deleteQuestion(
                  question.id, _currentUserId, _isFounder);

              if (success && mounted) {
                setState(() {
                  _questions.removeAt(index);
                });
                _showSuccessSnackBar('تم حذف السؤال بنجاح');

                await _questionsService.clearCache();
                final refreshedQuestions =
                    await _questionsService.getQuestions();
                if (mounted) {
                  setState(() {
                    _questions = refreshedQuestions;
                  });
                }
              } else if (mounted) {
                _showErrorSnackBar('فشل حذف السؤال');
              }
            },
            child: Text('حذف', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateQuestionInList(QuestionModel updatedQuestion) {
    final index = _questions.indexWhere((q) => q.id == updatedQuestion.id);
    if (index != -1 && mounted) {
      setState(() {
        _questions[index] = updatedQuestion;
      });
    }
  }

  void _removeQuestionFromList(String questionId) {
    setState(() {
      _questions.removeWhere((q) => q.id == questionId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: provider.backgroundColor,
            appBar: AppBar(
              backgroundColor: provider.cardColor,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF4ADE80)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'لحظة فهم',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF4ADE80)),
                  onPressed: _showAddQuestionDialog,
                ),
                IconButton(
                  icon: AnimatedRotation(
                    duration: const Duration(milliseconds: 500),
                    turns: _isRefreshing ? 1.0 : 0.0,
                    child: Icon(
                      _isRefreshing
                          ? Icons.hourglass_empty_rounded
                          : Icons.refresh_rounded,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                  onPressed: _isRefreshing ? null : _refresh,
                ),
              ],
            ),
            body: _isLoading
                ? _buildSkeletonScreen(provider)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: const Color(0xFF4ADE80),
                    child: _buildBody(provider),
                  ),
          ),
        );
      },
    );
  }

  // ==================== Skeleton Widgets ====================

  Widget _buildSkeletonScreen(ThemeProvider provider) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildSkeletonCard(provider),
    );
  }

  Widget _buildSkeletonCard(ThemeProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المستخدم والاسم
          Row(
            children: [
              _buildShimmerEffect(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerEffect(
                      child: Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildShimmerEffect(
                      child: Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // عنوان السؤال
          _buildShimmerEffect(
            child: Container(
              width: 200,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // محتوى السؤال (سطرين)
          _buildShimmerEffect(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildShimmerEffect(
            child: Container(
              width: 150,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // أزرار الإعجاب والتعليقات
          Row(
            children: [
              _buildShimmerEffect(
                child: Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _buildShimmerEffect(
                child: Container(
                  width: 50,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect({required Widget child}) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment(-1.5, 0),
          end: Alignment(1.5, 0),
          colors: [
            Colors.transparent,
            Colors.white70,
            Colors.transparent,
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcATop,
      child: child,
    );
  }

  // ==================== Body Widget ====================

  Widget _buildBody(ThemeProvider provider) {
    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.question_answer_outlined,
                size: 64, color: provider.secondaryTextColor),
            const SizedBox(height: 16),
            Text('لا توجد أسئلة حالياً',
                style: GoogleFonts.cairo(
                    fontSize: 16, color: provider.secondaryTextColor)),
            const SizedBox(height: 16),
            Text('كن أول من يسأل!',
                style: GoogleFonts.cairo(
                    fontSize: 14, color: provider.secondaryTextColor)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddQuestionDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('اسأل سؤالاً جديداً'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _questions.length,
      itemBuilder: (context, index) {
        final question = _questions[index];
        final isLiked = question.isLikedBy(_currentUserId);
        final isOwner = question.userId == _currentUserId;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuestionDetailPage(
                  question: question,
                  currentUserId: _currentUserId,
                  currentUserName: _currentUserName,
                  isFounder: _isFounder,
                  onQuestionUpdated: _updateQuestionInList,
                  onQuestionDeleted: () => _removeQuestionFromList(question.id),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: provider.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4ADE80).withOpacity(0.15),
                              const Color(0xFF4ADE80).withOpacity(0.05)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                            child: Icon(Icons.person_rounded,
                                color: Color(0xFF4ADE80), size: 24)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(question.userName,
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    color: provider.textColor)),
                            Text(_formatDate(question.createdAt),
                                style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: provider.secondaryTextColor)),
                          ],
                        ),
                      ),
                      if (isOwner || _isFounder)
                        GestureDetector(
                          onTap: () =>
                              _showDeleteQuestionDialog(question, index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(question.title,
                      style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: provider.textColor)),
                  const SizedBox(height: 8),
                  Text(question.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                          fontSize: 14, color: provider.secondaryTextColor)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLikeInstant(question, index),
                        child: Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(isLiked),
                                color: isLiked ? Colors.red : Colors.grey,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text('${question.likesCount}',
                                style: GoogleFonts.cairo(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 4),
                          Text('${question.repliesCount}',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
