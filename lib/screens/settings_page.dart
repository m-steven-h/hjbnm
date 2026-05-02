import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'about_page.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return AnimatedTheme(
          data: ThemeData(
            brightness: provider.currentThemeMode == ThemeModeType.dark
                ? Brightness.dark
                : Brightness.light,
          ),
          duration: const Duration(milliseconds: 500),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: provider.backgroundColor,
              body: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 20),
                        // البطاقة الأولى - حجم الخط
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildSettingsCard(
                            context: context,
                            provider: provider,
                            title: 'حجم الخط',
                            icon: Icons.text_fields_rounded,
                            child: Column(
                              children: [
                                _buildFontSizeOption(
                                  context: context,
                                  provider: provider,
                                  title: 'صغير (20%)',
                                  value: FontSize.small,
                                  description: 'الحجم الافتراضي',
                                ),
                                _buildDivider(provider),
                                _buildFontSizeOption(
                                  context: context,
                                  provider: provider,
                                  title: 'وسط (50%)',
                                  value: FontSize.medium,
                                  description: 'أكبر من الافتراضي',
                                ),
                                _buildDivider(provider),
                                _buildFontSizeOption(
                                  context: context,
                                  provider: provider,
                                  title: 'كبير (100%)',
                                  value: FontSize.large,
                                  description: 'أكبر حجم',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // البطاقة الثانية - المظهر
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildSettingsCard(
                            context: context,
                            provider: provider,
                            title: 'المظهر',
                            icon: Icons.palette_rounded,
                            child: Column(
                              children: [
                                _buildThemeOption(
                                  context: context,
                                  provider: provider,
                                  title: 'فاتح',
                                  icon: Icons.light_mode_rounded,
                                  value: ThemeModeType.light,
                                  color: Color(0xFF4ADE80),
                                  backgroundColor: Colors.white,
                                ),
                                _buildDivider(provider),
                                _buildThemeOption(
                                  context: context,
                                  provider: provider,
                                  title: 'داكن',
                                  icon: Icons.dark_mode_rounded,
                                  value: ThemeModeType.dark,
                                  color: Color(0xFF4ADE80),
                                  backgroundColor: const Color(0xFF1E1E1E),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // البطاقة الثالثة - عن التطبيق
                        TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildAboutButton(context, provider),
                        ),
                        const SizedBox(height: 100),
                      ]),
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

  Widget _buildSettingsCard({
    required BuildContext context,
    required ThemeProvider provider,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
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
                  child: Icon(
                    icon,
                    color: const Color(0xFF4ADE80),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 22 * provider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: provider.textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: child,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFontSizeOption({
    required BuildContext context,
    required ThemeProvider provider,
    required String title,
    required FontSize value,
    required String description,
  }) {
    final isSelected = provider.currentFontSize == value;

    return InkWell(
      onTap: () {
        provider.setFontSize(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? (provider.currentThemeMode == ThemeModeType.dark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade100)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.cairo(
                      fontSize: 16 * provider.fontScale,
                      fontWeight: FontWeight.w600,
                      color: provider.textColor,
                    ),
                    child: Text(title),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.cairo(
                      fontSize: 12 * provider.fontScale,
                      color: provider.secondaryTextColor,
                    ),
                    child: Text(description),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider provider,
    required String title,
    required IconData icon,
    required ThemeModeType value,
    required Color color,
    required Color backgroundColor,
  }) {
    final isSelected = provider.currentThemeMode == value;

    return InkWell(
      onTap: () {
        provider.setThemeMode(value);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? (provider.currentThemeMode == ThemeModeType.dark
                  ? Colors.grey.shade800.withOpacity(0.3)
                  : Colors.grey.shade100)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: AnimatedScale(
                scale: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4ADE80)
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: AnimatedRotation(
                turns: isSelected ? 0.125 : 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.cairo(
                  fontSize: 16 * provider.fontScale,
                  fontWeight: FontWeight.w600,
                  color: provider.textColor,
                ),
                child: Text(title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutButton(BuildContext context, ThemeProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AboutPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFF4ADE80),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'عن التطبيق',
                  style: GoogleFonts.cairo(
                    fontSize: 18 * provider.fontScale,
                    fontWeight: FontWeight.w600,
                    color: provider.textColor,
                  ),
                ),
              ),
              AnimatedRotation(
                turns: 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: provider.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 1,
      color: provider.currentThemeMode == ThemeModeType.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
    );
  }
}
