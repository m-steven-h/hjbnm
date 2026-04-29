import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'prayer_road_page.dart';
import 'agpeya_page.dart';
import 'meditations_list_page.dart';
import '../providers/theme_provider.dart';
import 'benefit_words_page.dart';
import 'discussions_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  final List<Widget> _pages = [
    const ProfilePage(),
    const MainContentPage(),
    const SettingsPage(),
  ];
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4ADE80).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color:
                    isSelected ? const Color(0xFF4ADE80) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              style: GoogleFonts.cairo(
                color:
                    isSelected ? const Color(0xFF4ADE80) : Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: provider.backgroundColor,
            extendBody: true,
            appBar: AppBar(
              backgroundColor: provider.cardColor,
              elevation: 0,
              centerTitle: true,
              title: Text(
                _selectedIndex == 0
                    ? 'الملف الشخصي'
                    : (_selectedIndex == 1 ? 'دقيقة صلاة' : 'الإعدادات'),
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4ADE80),
                  fontSize: 20 * provider.fontScale,
                ),
              ),
            ),
            body: _pages[_selectedIndex],
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        index: 0,
                        icon: Icons.person_rounded,
                        title: 'حسابي',
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.home_rounded,
                        title: 'الرئيسية',
                      ),
                      _buildNavItem(
                        index: 2,
                        icon: Icons.settings_rounded,
                        title: 'الإعدادات',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MainContentPage extends StatelessWidget {
  const MainContentPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            bottom: 100.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WelcomeCard(provider: provider),
              const SizedBox(height: 20),
              DailyVerseCard(provider: provider),
              const SizedBox(height: 25),
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: Color(0xFF4ADE80), thickness: 2),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'الأقسام',
                      style: GoogleFonts.cairo(
                        fontSize: 22 * provider.fontScale,
                        fontWeight: FontWeight.bold,
                        color: provider.textColor,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: Color(0xFF4ADE80), thickness: 2),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              AppSectionsList(provider: provider),
            ],
          ),
        );
      },
    );
  }
}

class WelcomeCard extends StatelessWidget {
  final ThemeProvider provider;
  const WelcomeCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ADE80).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'اهلا بيك',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 28 * provider.fontScale,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'خلينا نبدا اليوم بدقيقة صلاة مع ربنا',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white.withOpacity(0.95),
              fontSize: 18 * provider.fontScale,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyVerseCard extends StatelessWidget {
  final ThemeProvider provider;
  const DailyVerseCard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF4ADE80).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Center(
            child: Text(
              'آية التطبيق',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '"قَلْبًا نَقِيًّا اخْلُقْ فِيَّ يَا اَللهُ، وَرُوحًا مُسْتَقِيمًا جَدِّدْ فِي دَاخِلِي."',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18 * provider.fontScale,
              fontStyle: FontStyle.italic,
              color: provider.textColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'مز 51: 10',
              style: TextStyle(
                color: Color(0xFF4ADE80),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppSectionsList extends StatelessWidget {
  final ThemeProvider provider;
  const AppSectionsList({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionItem(
          context,
          Icons.auto_stories_rounded,
          'الكتاب المقدس',
          () {
            _showComingSoon(context, provider);
          },
        ),
        _buildSectionItem(
          context,
          Icons.shield_rounded,
          'محارب العادة',
          () {
            _showComingSoon(context, provider);
          },
        ),
        _buildSectionItem(
          context,
          Icons.menu_book_rounded,
          'الأجبية المقدسة',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AgpeyaPage()),
            );
          },
        ),
        _buildSectionItem(
          context,
          Icons.navigation_rounded,
          'طريق الصلاة',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrayerRoadPage()),
            );
          },
        ),
        _buildSectionItem(
          context,
          Icons.spa_rounded,
          'صلوات قصيرة',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MeditationsListPage()),
            );
          },
        ),
        _buildSectionItem(
          context,
          Icons.chat_rounded,
          'مناقشات',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DiscussionsPage()),
            );
          },
        ),
        _buildSectionItem(
          context,
          Icons.favorite,
          'كلمة منفعة',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BenefitWordsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: provider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Icon(icon, color: const Color(0xFF4ADE80), size: 28),
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
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: const Color(0xFF4ADE80)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, ThemeProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'سيتم إضافة هذا القسم قريباً',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF4ADE80),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
