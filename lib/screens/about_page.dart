// screens/about_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/theme_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@dakikatsalah.com',
      query: 'subject=استفسار عن تطبيق دقيقة صلاة',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  // ✅ دالة لفتح موقع المطور
  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://m-steven-h.netlify.app');
    try {
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching website: $e');
    }
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
                'عن التطبيق',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ✅ شعار التطبيق
                  _buildLogoSection(provider),

                  const SizedBox(height: 24),

                  // ✅ بطاقة الرؤية والرسالة
                  _buildMissionVisionCard(provider),

                  const SizedBox(height: 20),

                  // ✅ قصة التطبيق
                  _buildStoryCard(provider),

                  const SizedBox(height: 20),

                  // ✅ المميزات الرئيسية
                  _buildFeaturesCard(provider),

                  const SizedBox(height: 20),

                  // ✅ المحتوى الروحي
                  _buildContentCard(provider),

                  const SizedBox(height: 20),

                  // ✅ الفريق والمطور
                  _buildTeamCard(provider),

                  const SizedBox(height: 20),

                  // ✅ معلومات التواصل
                  _buildContactCard(provider),

                  const SizedBox(height: 20),

                  // ✅ أرقام وإحصائيات
                  _buildStatsCard(provider),

                  const SizedBox(height: 20),

                  // ✅ حقوق النشر
                  _buildCopyrightCard(provider),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== شعار التطبيق ====================

  Widget _buildLogoSection(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.church_rounded,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'دقيقة صلاة',
            style: GoogleFonts.cairo(
              fontSize: 32 * provider.fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'الإصدار 2.0.0',
              style: GoogleFonts.cairo(
                fontSize: 14 * provider.fontScale,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== بطاقة الرؤية والرسالة ====================

  Widget _buildMissionVisionCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.visibility_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'رؤيتنا ورسالتنا',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '🎯 رؤيتنا',
            style: GoogleFonts.cairo(
              fontSize: 18 * provider.fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'نسعى لنكون شريكاً روحياً يومياً للمسيحيين العرب، نساعدهم على بناء علاقة أعمق مع الله من خلال الصلاة والتأمل في كلمته، في أي وقت ومن أي مكان.',
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '💚 رسالتنا',
            style: GoogleFonts.cairo(
              fontSize: 18 * provider.fontScale,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4ADE80),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تقديم محتوى أرثوذكسي أصيل بأسلوب عصري ومبسط، يساعد المستخدمين على الالتزام بصلواتهم اليومية، وفهم الإيمان بعمق، والنمو روحياً خطوة بخطوة من خلال رحلة "طريق الصلاة" التي تمتد لـ60 يوماً.',
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== قصة التطبيق ====================

  Widget _buildStoryCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'قصة التطبيق',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'بدأت فكرة "دقيقة صلاة" في عام 2024، من رغبة عميقة في مساعدة المسيحيين على الالتزام بحياة الصلاة اليومية وسط انشغالات الحياة العصرية.',
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'لاحظ فريق العمل أن الكثير من المؤمنين يجدون صعوبة في تنظيم أوقات صلواتهم، وقراءة الأجبية، والتمسك بعادات روحية ثابتة. من هنا، جاءت فكرة إنشاء تطبيق يجمع بين الأصالة والمعاصرة، يقدم الأجبية المقدسة كاملة، وطريقاً منظماً للصلاة لمدة 60 يوماً، بالإضافة إلى كلمات منفعة وصلوات قصيرة.',
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اليوم، وبفضل الله، يستخدم التطبيق آلاف المستخدمين حول العالم، ونعمل باستمرار على تطويره وإضافة المزيد من المميزات والمحتوى الروحي القيم.',
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== المميزات الرئيسية ====================

  Widget _buildFeaturesCard(ThemeProvider provider) {
    final features = [
      {'icon': Icons.menu_book_rounded, 'title': 'الأجبية كاملة'},
      {'icon': Icons.navigation_rounded, 'title': 'طريق الصلاة (60 يوم)'},
      {'icon': Icons.favorite_rounded, 'title': 'كلمات منفعة (200+ كلمة)'},
      {'icon': Icons.spa_rounded, 'title': 'صلوات قصيرة'},
      {'icon': Icons.help_outline_rounded, 'title': 'لحظة فهم (مجتمع أسئلة)'},
      {'icon': Icons.notifications_active_rounded, 'title': 'إشعارات يومية'},
      {'icon': Icons.palette_rounded, 'title': 'وضع ليلي ونهاري'},
      {'icon': Icons.text_fields_rounded, 'title': 'تحكم بحجم الخط'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'مميزات التطبيق',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4ADE80).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(feature['icon'] as IconData,
                        color: const Color(0xFF4ADE80), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feature['title'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 12 * provider.fontScale,
                          fontWeight: FontWeight.w600,
                          color: provider.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== المحتوى الروحي ====================

  Widget _buildContentCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.library_books_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'المحتوى الروحي',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContentItem(
            provider,
            '📖 الأجبية المقدسة',
            'نصوص صلوات السبع ساعات كاملة: باكر، الثالثة، السادسة، التاسعة، الغروب، النوم، بالإضافة إلى صلوات منتصف الليل.'
                'محتوياتها: المزامير، الإنجيل، القطَع، التحاليل، قانون الإيمان، التسبحة.'
                'كل صلاة مرتبة في أقسام سهلة التصفح بكبسة زر واحدة.',
          ),
          const SizedBox(height: 16),
          _buildContentItem(
            provider,
            '🛤️ طريق الصلاة',
            'رحلة روحانية مدتها 60 يوماً تساعدك على بناء حياة صلاة منتظمة.'
                'كل يوم يحتوي على: آية من الكتاب المقدس + صلاة خاصة + تأمل + تشجيع روحي.'
                'نظام متقدم يتيح فتح الأيام تلقائياً - يوم جديد يفتح كل يوم الساعة 1 ظهراً بعد إكمال اليوم السابق.'
                'نسبة إنجاز ورحلة مرئية تحفزك على الاستمرار.',
          ),
          const SizedBox(height: 16),
          _buildContentItem(
            provider,
            '💚 كلمة منفعة',
            'أكثر من 200 كلمة روحية تغطي موضوعات: الهدوء، الصلاة، الصوم، التوبة، المحبة، التواضع، الغضب، العناد، الحكمة، وغيرها الكثير.'
                'كل كلمة هي مقال روحي عميق مستوحى من تعاليم الآباء والكتاب المقدس.'
                'يمكنك مشاركة الكلمات مع أصدقائك عبر وسائل التواصل الاجتماعي.',
          ),
          const SizedBox(height: 16),
          _buildContentItem(
            provider,
            '🙏 صلوات قصيرة',
            'تشمل: صلاة الصباح، صلاة المساء، صلاة الطلبة، صلاة قبل الطعام وبعده، صلاة الاعتراف بالخطية، قانون الإيمان، وغيرها من الصلوات اليومية.'
                'نصوص من تراث الكنيسة القبطية الأرثوذكسية.',
          ),
          const SizedBox(height: 16),
          _buildContentItem(
            provider,
            '❓ لحظة فهم',
            'مجتمع أسئلة وأجوبة داخل التطبيق.'
                'يمكنك طرح أسئلتك الروحية، والإجابة على أسئلة الآخرين.'
                'نظام إعجاب وردود وتفاعل كامل.'
                'إمكانية حذف الأسئلة للمستخدمين والمشرفين.',
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(
    ThemeProvider provider,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 16 * provider.fontScale,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF4ADE80),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: GoogleFonts.cairo(
            fontSize: 14 * provider.fontScale,
            color: provider.textColor,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ==================== الفريق والمطور ====================

  Widget _buildTeamCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.people_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'الفريق والمطور',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.code_rounded,
                    color: Color(0xFF4ADE80), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المطور',
                      style: GoogleFonts.cairo(
                        fontSize: 14 * provider.fontScale,
                        color: provider.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Steven Hany',
                      style: GoogleFonts.cairo(
                        fontSize: 20 * provider.fontScale,
                        fontWeight: FontWeight.bold,
                        color: provider.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مطور ومصمم تطبيقات، مهتم بتقديم محتوى مسيحي بجودة عالية وتقنية حديثة.',
                      style: GoogleFonts.cairo(
                        fontSize: 14 * provider.fontScale,
                        color: provider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF4ADE80), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'نشكر كل من ساهم في إخراج هذا التطبيق إلى النور، وكل مستخدم يخصص وقتاً للصلاة والتأمل من خلاله.',
                    style: GoogleFonts.cairo(
                      fontSize: 14 * provider.fontScale,
                      color: provider.textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== معلومات التواصل ====================

  Widget _buildContactCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.contact_mail_rounded,
                    color: Color(0xFF4ADE80), size: 28),
              ),
              const SizedBox(width: 16),
              Text(
                'تواصل معنا',
                style: GoogleFonts.cairo(
                  fontSize: 22 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: provider.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ✅ رابط البريد الإلكتروني
          GestureDetector(
            onTap: _launchEmail,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.email_rounded,
                        color: Color(0xFF4ADE80), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'البريد الإلكتروني',
                          style: GoogleFonts.cairo(
                            fontSize: 12 * provider.fontScale,
                            color: provider.secondaryTextColor,
                          ),
                        ),
                        Text(
                          'steven.hany.194@gmail.com',
                          style: GoogleFonts.cairo(
                            fontSize: 16 * provider.fontScale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      color: Color(0xFF4ADE80), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ✅ رابط موقع المطور (جديد)
          GestureDetector(
            onTap: _launchWebsite,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.web_rounded,
                        color: Color(0xFF4ADE80), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'موقع المطور',
                          style: GoogleFonts.cairo(
                            fontSize: 12 * provider.fontScale,
                            color: provider.secondaryTextColor,
                          ),
                        ),
                        Text(
                          'm-steven-h.netlify.app',
                          style: GoogleFonts.cairo(
                            fontSize: 16 * provider.fontScale,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      color: Color(0xFF4ADE80), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== أرقام وإحصائيات ====================

  Widget _buildStatsCard(ThemeProvider provider) {
    final stats = [
      {'number': '200+', 'label': 'كلمة منفعة', 'icon': Icons.favorite_rounded},
      {'number': '60', 'label': 'يوم روحاني', 'icon': Icons.navigation_rounded},
      {
        'number': '7',
        'label': 'صلوات الأجبية',
        'icon': Icons.menu_book_rounded
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'إحصائيات سريعة',
            style: GoogleFonts.cairo(
              fontSize: 20 * provider.fontScale,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(stat['icon'] as IconData,
                        color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      stat['number'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 24 * provider.fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12 * provider.fontScale,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== حقوق النشر ====================

  Widget _buildCopyrightCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'جميع الحقوق محفوظة © ${DateTime.now().year}',
            style: GoogleFonts.cairo(
              fontSize: 14 * provider.fontScale,
              color: provider.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
