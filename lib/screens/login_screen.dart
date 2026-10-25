import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.litroBlue, AppColors.laugfsYellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.litroBlue.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_gas_station_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                Text(
                  lang.isSinhala ? 'ලංකා ගෑස් ට්‍රැකර්' : 'Lanka Gas Tracker',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.isSinhala
                      ? 'ලිට්‍රෝ සහ ලාෆ්ස් ගෑස් සජීවීව සොයාගන්න'
                      : 'Real-Time Litro & Laugfs Availability in Sri Lanka',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 36),

                // Accountability Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureRow(
                        icon: Icons.verified_user_rounded,
                        color: AppColors.availableGreen,
                        title: lang.isSinhala ? 'තහවුරු කළ දත්ත' : 'Verified Community Data',
                        subtitle: lang.isSinhala
                            ? 'බොරු තොරතුරු වැළැක්වීමට Google ගිණුමෙන් ලොග් වීම අනිවාර්ය කර ඇත.'
                            : 'Sign-in ensures verified citizens and eliminates false stock reports.',
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureRow(
                        icon: Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        title: lang.isSinhala ? '4 KM ආසන්නතා නිවේදන' : '4 KM Proximity Alerts',
                        subtitle: lang.isSinhala
                            ? 'ඔබ සිටින තැන සිට 4 KM ඇතුළත ගෑස් පැමිණි සැණින් notification ලැබේ.'
                            : 'Get notified immediately when stock arrives within 4 km of your GPS.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Google Sign In Button
                if (auth.isLoading)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final success = await auth.signInWithGoogle();
                        if (!success && context.mounted && auth.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.outOfStockRed,
                              content: Text(auth.errorMessage!),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 22,
                            height: 22,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 28,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            lang.isSinhala ? 'Google ගිණුමෙන් ඇතුල් වන්න' : 'Sign in with Google',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Language Switcher Chip
                ActionChip(
                  avatar: const Icon(Icons.language_rounded, size: 16, color: AppColors.primary),
                  backgroundColor: AppColors.surfaceElevated,
                  side: const BorderSide(color: AppColors.border),
                  label: Text(
                    lang.isSinhala ? 'Language: English' : 'භාෂාව: සිංහල',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  onPressed: () {
                    lang.setLanguage(lang.isSinhala ? AppLanguage.english : AppLanguage.sinhala);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
