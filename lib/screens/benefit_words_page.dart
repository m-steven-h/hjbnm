import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'benefit_word_detail_page.dart';
import '../services/gist_service.dart';

class BenefitWordsPage extends StatefulWidget {
  const BenefitWordsPage({super.key});

  @override
  State<BenefitWordsPage> createState() => _BenefitWordsPageState();
}

class _BenefitWordsPageState extends State<BenefitWordsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _benefitWords = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;
  final GistService _gistService = GistService();

  @override
  void initState() {
    super.initState();
    _loadBenefitWords();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  void _startAnimations(int itemCount) {
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

  Future<void> _loadBenefitWords() async {
    setState(() {
      _isLoading = true;
    });

    // جلب البيانات في الخلفية
    final words = await _gistService.getBenefitWords();

    setState(() {
      _benefitWords = words.where((word) {
        return word['title'] != null &&
            word['title'].toString().isNotEmpty &&
            word['content'] != null &&
            word['content'].toString().isNotEmpty;
      }).toList();
      _isLoading = false;
    });

    // تشغيل الأنيميشن بعد ما البيانات تجيب
    if (_benefitWords.isNotEmpty) {
      _startAnimations(_benefitWords.length);
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    final success = await _gistService.refreshData();
    if (success) {
      final words = await _gistService.getBenefitWords();
      setState(() {
        _benefitWords = words.where((word) {
          return word['title'] != null &&
              word['title'].toString().isNotEmpty &&
              word['content'] != null &&
              word['content'].toString().isNotEmpty;
        }).toList();
      });

      // إعادة تشغيل الأنيميشن للبيانات الجديدة
      _animationController.reset();
      _startAnimations(_benefitWords.length);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث كلمات المنفعة'),
            backgroundColor: Color(0xFF4ADE80),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    setState(() {
      _isRefreshing = false;
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
                'كلمة منفعة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
              actions: [
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
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF4ADE80),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'جاري تحميل كلمات المنفعة...',
                            style: GoogleFonts.cairo(
                              color: provider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _benefitWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: provider.secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد كلمات منفعة',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  color: provider.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadBenefitWords,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4ADE80),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('حاول مرة أخرى'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _benefitWords.length,
                          itemBuilder: (context, index) {
                            final word = _benefitWords[index];
                            return FadeTransition(
                              opacity: _fadeAnimations[index],
                              child: SlideTransition(
                                position: _slideAnimations[index],
                                child: _buildBenefitCard(
                                  context,
                                  provider,
                                  word['title'] as String,
                                  word['content'] as String,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitCard(
    BuildContext context,
    ThemeProvider provider,
    String title,
    String content,
  ) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BenefitWordDetailPage(
                  title: title,
                  content: content,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
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
                  child: const Center(
                    child: Icon(
                      Icons.favorite,
                      size: 28,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18 * provider.fontScale,
                      fontWeight: FontWeight.bold,
                      color: provider.textColor,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: const Color(0xFF4ADE80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
