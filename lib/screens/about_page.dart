import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
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
                  const SizedBox(height: 20),
                  _buildInfoCard(provider),
                  const SizedBox(height: 20),
                  _buildDeveloperCard(provider),
                  const SizedBox(height: 20),
                  _buildVersionCard(provider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  Widget _buildInfoCard(ThemeProvider provider) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.church_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'دقيقة صلاة',
            style: GoogleFonts.cairo(
              fontSize: 28 * provider.fontScale,
              fontWeight: FontWeight.bold,
              color: provider.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تطبيق يساعدك على التقرب من الله من خلال الصلاة والتأمل في كلمته',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16 * provider.fontScale,
              color: provider.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDeveloperCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.code_rounded,
              color: Color(0xFF4ADE80),
              size: 32,
            ),
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
                  'فريق دقيقة صلاة',
                  style: GoogleFonts.cairo(
                    fontSize: 18 * provider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: provider.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildVersionCard(ThemeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.info_rounded,
              color: Color(0xFF4ADE80),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإصدار',
                  style: GoogleFonts.cairo(
                    fontSize: 14 * provider.fontScale,
                    color: provider.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1.0.0',
                  style: GoogleFonts.cairo(
                    fontSize: 18 * provider.fontScale,
                    fontWeight: FontWeight.bold,
                    color: provider.textColor,
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