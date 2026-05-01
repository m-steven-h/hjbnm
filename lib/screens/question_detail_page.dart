// screens/question_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/questions_service.dart';
import '../models/question_model.dart';

class QuestionDetailPage extends StatefulWidget {
  final QuestionModel question;
  final String currentUserId;
  final String currentUserName;
  final bool isFounder;
  final Function(QuestionModel) onQuestionUpdated;
  final VoidCallback? onQuestionDeleted;

  const QuestionDetailPage({
    super.key,
    required this.question,
    required this.currentUserId,
    required this.currentUserName,
    required this.isFounder,
    required this.onQuestionUpdated,
    this.onQuestionDeleted,
  });

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  late QuestionModel _question;
  final QuestionsService _questionsService = QuestionsService();
  final TextEditingController _replyController = TextEditingController();
  bool _isAddingReply = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _question = widget.question;
  }

  Future<void> _addReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isAddingReply = true);
    final success = await _questionsService.addReply(
      _question.id,
      widget.currentUserId,
      widget.currentUserName,
      _replyController.text.trim(),
    );

    if (success && mounted) {
      _replyController.clear();
      final refreshedQuestions = await _questionsService.getQuestions();
      final updatedQuestion = refreshedQuestions
          .firstWhere((q) => q.id == _question.id, orElse: () => _question);
      if (mounted) {
        setState(() => _question = updatedQuestion);
        widget.onQuestionUpdated(updatedQuestion);
        _showSuccessSnackBar('تم إضافة ردك');
      }
    } else if (mounted) {
      _showErrorSnackBar('فشل إضافة الرد');
    }
    if (mounted) setState(() => _isAddingReply = false);
  }

  Future<void> _toggleLikeQuestionInstant() async {
    final bool wasLiked = _question.isLikedBy(widget.currentUserId);
    final List<String> newLikedBy = List.from(_question.likedBy);

    if (wasLiked) {
      newLikedBy.remove(widget.currentUserId);
    } else {
      newLikedBy.add(widget.currentUserId);
    }

    final QuestionModel updatedQuestion =
        _question.copyWith(likedBy: newLikedBy);

    setState(() {
      _question = updatedQuestion;
    });
    widget.onQuestionUpdated(updatedQuestion);

    _questionsService
        .toggleLike(_question.id, widget.currentUserId)
        .then((success) {
      if (!success && mounted) {
        setState(() {
          _question = widget.question;
        });
        widget.onQuestionUpdated(widget.question);
        _showErrorSnackBar('فشل تحديث الإعجاب');
      }
    });
  }

  Future<void> _toggleLikeReplyInstant(ReplyModel reply, int replyIndex) async {
    final bool wasLiked = reply.isLikedBy(widget.currentUserId);
    final List<String> newLikedBy = List.from(reply.likedBy);

    if (wasLiked) {
      newLikedBy.remove(widget.currentUserId);
    } else {
      newLikedBy.add(widget.currentUserId);
    }

    final ReplyModel updatedReply = reply.copyWith(likedBy: newLikedBy);
    final List<ReplyModel> newReplies = List.from(_question.replies);
    newReplies[replyIndex] = updatedReply;

    final QuestionModel updatedQuestion =
        _question.copyWith(replies: newReplies);

    setState(() {
      _question = updatedQuestion;
    });
    widget.onQuestionUpdated(updatedQuestion);

    _questionsService
        .toggleLike(_question.id, widget.currentUserId, replyId: reply.id)
        .then((success) {
      if (!success && mounted) {
        setState(() {
          final List<ReplyModel> oldReplies = List.from(_question.replies);
          oldReplies[replyIndex] = reply;
          _question = _question.copyWith(replies: oldReplies);
        });
        widget.onQuestionUpdated(_question);
        _showErrorSnackBar('فشل تحديث الإعجاب');
      }
    });
  }

  Future<void> _deleteQuestion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text('حذف السؤال', style: GoogleFonts.cairo()),
        content: Text(
          widget.isFounder
              ? 'أنت كمؤسس، هل تريد حذف هذا السؤال؟'
              : 'هل تريد حذف سؤالك؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('حذف', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    _showLoadingSnackBar('جاري حذف السؤال...');

    final success = await _questionsService.deleteQuestion(
        _question.id, widget.currentUserId, widget.isFounder);

    if (success && mounted) {
      _showSuccessSnackBar('تم حذف السؤال');

      if (widget.onQuestionDeleted != null) {
        widget.onQuestionDeleted!();
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      setState(() => _isDeleting = false);
      _showErrorSnackBar('فشل حذف السؤال');
    }
  }

  Future<void> _deleteReply(ReplyModel reply, int replyIndex) async {
    if (!widget.isFounder &&
        reply.userId != widget.currentUserId &&
        _question.userId != widget.currentUserId) {
      _showErrorSnackBar('لا يمكنك حذف هذا الرد');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('حذف الرد', style: GoogleFonts.cairo()),
        content: Text('هل تريد حذف هذا الرد؟', style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('حذف', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _showLoadingSnackBar('جاري حذف الرد...');

    final success = await _questionsService.deleteReply(
        _question.id, reply.id, widget.currentUserId, widget.isFounder);

    if (success && mounted) {
      final refreshedQuestions = await _questionsService.getQuestions();
      final updatedQuestion = refreshedQuestions
          .firstWhere((q) => q.id == _question.id, orElse: () => _question);
      setState(() => _question = updatedQuestion);
      widget.onQuestionUpdated(updatedQuestion);
      _showSuccessSnackBar('تم حذف الرد');
    } else if (mounted) {
      _showErrorSnackBar('فشل حذف الرد');
    }
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
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
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

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        final isQuestionLiked = _question.isLikedBy(widget.currentUserId);

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
                'تفاصيل السؤال',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
              actions: [
                if (!_isDeleting &&
                    (widget.isFounder ||
                        _question.userId == widget.currentUserId))
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: _deleteQuestion,
                  ),
                if (_isDeleting)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: provider.cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [
                                        const Color(0xFF4ADE80)
                                            .withOpacity(0.15),
                                        const Color(0xFF4ADE80)
                                            .withOpacity(0.05)
                                      ]),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Center(
                                        child: Icon(Icons.person_rounded,
                                            color: Color(0xFF4ADE80),
                                            size: 28)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_question.userName,
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                color: provider.textColor)),
                                        Text(_formatDate(_question.createdAt),
                                            style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                color: provider
                                                    .secondaryTextColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(_question.title,
                                  style: GoogleFonts.cairo(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: provider.textColor)),
                              const SizedBox(height: 12),
                              Text(_question.content,
                                  style: GoogleFonts.cairo(
                                      fontSize: 16,
                                      color: provider.textColor,
                                      height: 1.5)),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _toggleLikeQuestionInstant,
                                child: Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Icon(
                                        isQuestionLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        key: ValueKey(isQuestionLiked),
                                        color: isQuestionLiked
                                            ? Colors.red
                                            : Colors.grey,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${_question.likesCount}',
                                        style: GoogleFonts.cairo(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('${_question.replies.length} ردود',
                            style: GoogleFonts.cairo(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: provider.textColor)),
                        const SizedBox(height: 12),
                        ..._question.replies.asMap().entries.map((entry) {
                          final replyIndex = entry.key;
                          final reply = entry.value;
                          final isReplyLiked =
                              reply.isLikedBy(widget.currentUserId);
                          final canDeleteReply = widget.isFounder ||
                              reply.userId == widget.currentUserId ||
                              _question.userId == widget.currentUserId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: provider.cardColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          const Color(0xFF4ADE80)
                                              .withOpacity(0.15),
                                          const Color(0xFF4ADE80)
                                              .withOpacity(0.05)
                                        ]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                          child: Icon(Icons.person_rounded,
                                              color: Color(0xFF4ADE80),
                                              size: 20)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(reply.userName,
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.bold,
                                                  color: provider.textColor)),
                                          const SizedBox(width: 8),
                                          Text(_formatDate(reply.createdAt),
                                              style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  color: provider
                                                      .secondaryTextColor)),
                                        ],
                                      ),
                                    ),
                                    if (canDeleteReply)
                                      GestureDetector(
                                        onTap: () =>
                                            _deleteReply(reply, replyIndex),
                                        child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red,
                                            size: 18),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(reply.content,
                                    style: GoogleFonts.cairo(
                                        fontSize: 14,
                                        color: provider.textColor)),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _toggleLikeReplyInstant(
                                      reply, replyIndex),
                                  child: Row(
                                    children: [
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          isReplyLiked
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          key: ValueKey(isReplyLiked),
                                          color: isReplyLiked
                                              ? Colors.red
                                              : Colors.grey,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${reply.likedBy.length}',
                                          style:
                                              GoogleFonts.cairo(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: provider.cardColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(color: provider.textColor),
                          decoration: InputDecoration(
                            hintText: 'اكتب ردك...',
                            hintStyle: GoogleFonts.cairo(
                                color: provider.secondaryTextColor),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _isAddingReply ? null : _addReply,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: _isAddingReply
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
