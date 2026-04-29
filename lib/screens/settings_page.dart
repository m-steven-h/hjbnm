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
        return Directionality(
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
                      _buildSettingsCard(
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
                      const SizedBox(height: 20),
                      _buildSettingsCard(
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
                              color: Colors.amber,
                              backgroundColor: Colors.white,
                            ),
                            _buildDivider(provider),
                            _buildThemeOption(
                              context: context,
                              provider: provider,
                              title: 'داكن',
                              icon: Icons.dark_mode_rounded,
                              value: ThemeModeType.dark,
                              color: Colors.deepPurple,
                              backgroundColor: const Color(0xFF1E1E1E),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAboutButton(context, provider),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
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
      onTap: () => provider.setFontSize(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
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
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16 * provider.fontScale,
                      fontWeight: FontWeight.w600,
                      color: provider.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.cairo(
                      fontSize: 12 * provider.fontScale,
                      color: provider.secondaryTextColor,
                    ),
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
      onTap: () => provider.setThemeMode(value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
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
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 16 * provider.fontScale,
                  fontWeight: FontWeight.w600,
                  color: provider.textColor,
                ),
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
          MaterialPageRoute(builder: (context) => const AboutPage()),
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: provider.secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider provider) {
    return Divider(
      height: 1,
      thickness: 1,
      color: provider.currentThemeMode == ThemeModeType.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
    );
  }
}
