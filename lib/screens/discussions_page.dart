// screens/discussions_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/discussions_service.dart';
import '../models/discussion_model.dart';

class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({super.key});

  @override
  State<DiscussionsPage> createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage>
    with SingleTickerProviderStateMixin {
  List<DiscussionModel> _discussions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isAdding = false;
  String _currentUser = '';
  bool _isFounder = false; // ✅ جديد: هل المستخدم هو المؤسس؟
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  final DiscussionsService _discussionsService = DiscussionsService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadDiscussions();
    _setupAnimations();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUser = prefs.getString('userName') ?? 'مستخدم';
        _isFounder = prefs.getBool('isFounder') ?? false; // ✅ جلب حالة المؤسس
      });
      print('👤 المستخدم الحالي: $_currentUser');
      print('👑 هل هو مؤسس؟ $_isFounder');
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _startAnimations(int itemCount) {
    if (itemCount == 0) return;

    _fadeAnimations = List.generate(itemCount, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(itemCount, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.05, 1.0, curve: Curves.easeOut),
        ),
      );
    });

    _animationController.forward();
  }

  Future<void> _loadDiscussions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final discussions = await _discussionsService.getDiscussions();

      if (mounted) {
        setState(() {
          _discussions = discussions;
          _isLoading = false;
        });

        if (_discussions.isNotEmpty) {
          _startAnimations(_discussions.length);
        }
      }
    } catch (e) {
      print('❌ خطأ في تحميل المناقشات: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('فشل تحميل المناقشات');
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final discussions = await _discussionsService.getDiscussions();

      if (mounted) {
        setState(() {
          _discussions = discussions;
          _isRefreshing = false;
        });

        _animationController.reset();
        if (_discussions.isNotEmpty) {
          _startAnimations(_discussions.length);
        }
      }
    } catch (e) {
      print('❌ خطأ في التحديث: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        _showErrorSnackBar('فشل تحديث المناقشات');
      }
    }
  }

  void _showAddDiscussionDialog() {
    final TextEditingController _contentController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
                      Icons.edit_rounded,
                      color: Color(0xFF4ADE80),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'أضف مناقشة جديدة',
                    style: GoogleFonts.cairo(
                      color: provider.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: provider.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFF4ADE80),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentUser,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: provider.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 5,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: provider.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'شاركنا بخاطرك...',
                        hintStyle: GoogleFonts.cairo(
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
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الرجاء كتابة محتوى المناقشة';
                        }
                        if (value.trim().length < 5) {
                          return 'المحتوى قصير جداً (5 أحرف على الأقل)';
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
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      await _performAddDiscussion(
                        _currentUser,
                        _contentController.text.trim(),
                      );
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

  Future<void> _performAddDiscussion(String userName, String content) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4ADE80),
        ),
      ),
    );

    try {
      final success =
          await _discussionsService.addDiscussion(userName, content);

      if (mounted) Navigator.pop(context);

      if (success) {
        await _refresh();
        if (mounted) {
          _showSuccessSnackBar('تم إضافة المناقشة بنجاح');
        }
      } else {
        if (mounted) {
          _showErrorSnackBar('حدث خطأ، حاول مرة أخرى');
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('❌ خطأ غير متوقع: $e');
      if (mounted) {
        _showErrorSnackBar('حدث خطأ: ${e.toString()}');
      }
    }
  }

  void _showDeleteConfirmation(DiscussionModel discussion) {
    // ✅ المؤسس يقدر يحذف أي مناقشة، المستخدم العادي يحذف مناقشاته بس
    final bool canDelete = _isFounder || (discussion.userName == _currentUser);

    if (!canDelete) {
      _showErrorSnackBar('لا يمكنك حذف مناقشات الآخرين');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(dialogContext).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'حذف المناقشة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _isFounder
              ? 'أنت كمؤسس، هل أنت متأكد من حذف هذه المناقشة؟'
              : 'هل أنت متأكد من حذف هذه المناقشة؟',
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          TextButton(
            onPressed: () async {
              // ✅ إغلاق ديالوج التأكيد
              Navigator.pop(dialogContext);

              // ✅ إظهار مؤقت التحميل
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4ADE80)),
                ),
              );

              try {
                bool success;

                if (_isFounder) {
                  // ✅ المؤسس: يستخدم deleteAnyDiscussion
                  print('👑 حذف بواسطة المؤسس');
                  success = await _discussionsService
                      .deleteAnyDiscussion(discussion.id);
                } else {
                  // ✅ المستخدم العادي: يستخدم deleteDiscussion العادية
                  print('👤 حذف بواسطة مستخدم عادي');
                  success = await _discussionsService.deleteDiscussion(
                    discussion.id,
                    _currentUser,
                  );
                }

                print('✅ نتيجة الحذف: $success');

                // ✅ إغلاق مؤقت التحميل
                if (mounted) Navigator.pop(context);

                if (success) {
                  // ✅ إعادة تحميل البيانات
                  await _refresh();
                  if (mounted) {
                    _showSuccessSnackBar('تم حذف المناقشة بنجاح');
                  }
                } else {
                  if (mounted) {
                    _showErrorSnackBar('فشل حذف المناقشة');
                  }
                }
              } catch (e) {
                print('❌ خطأ في الحذف: $e');
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  _showErrorSnackBar('حدث خطأ: ${e.toString()}');
                }
              }
            },
            child: Text(
              'حذف',
              style: GoogleFonts.cairo(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }

  void _showSuccessSnackBar(String message) {
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
  void dispose() {
    _animationController.dispose();
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
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF4ADE80),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'المناقشات',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
              actions: [
                // ✅ إظهار شارة المؤسس في الـ AppBar
                if (_isFounder)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFF4ADE80),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'مؤسس',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: const Color(0xFF4ADE80),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF4ADE80),
                  ),
                  onPressed: _isAdding ? null : _showAddDiscussionDialog,
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
            body: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFF4ADE80),
              child: _buildBody(provider),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(ThemeProvider provider) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF4ADE80),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري تحميل المناقشات...',
              style: GoogleFonts.cairo(
                color: provider.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_discussions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: provider.secondaryTextColor,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد مناقشات حالياً',
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: provider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'كن أول من يشارك!',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: provider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddDiscussionDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('أضف مناقشة جديدة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _discussions.length,
      itemBuilder: (context, index) {
        final discussion = _discussions[index];
        // ✅ المستخدم العادي يشوف زر الحذف لمناقشاته بس، المؤسس يشوفه على كل المناقشات
        final bool canDelete =
            _isFounder || (discussion.userName == _currentUser);

        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: provider.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // الصورة الرمزية
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4ADE80).withOpacity(0.15),
                            const Color(0xFF4ADE80).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: Color(0xFF4ADE80),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // المحتوى
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                discussion.userName,
                                style: GoogleFonts.cairo(
                                  fontSize: 16 * provider.fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: (discussion.userName == _currentUser)
                                      ? const Color(0xFF4ADE80)
                                      : provider.textColor,
                                ),
                              ),
                              if (discussion.userName == _currentUser) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4ADE80)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'أنت',
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: const Color(0xFF4ADE80),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (discussion.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(discussion.createdAt),
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: provider.secondaryTextColor,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            discussion.content,
                            style: GoogleFonts.cairo(
                              fontSize: 15 * provider.fontScale,
                              color: provider.textColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ زر الحذف - يظهر للمؤسس أو لصاحب المناقشة
                    if (canDelete)
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(discussion),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
