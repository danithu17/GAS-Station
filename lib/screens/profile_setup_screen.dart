import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AppAuthProvider>();
    _nameController = TextEditingController(
      text: auth.userProfile?.name.isNotEmpty == true
          ? auth.userProfile!.name
          : (auth.currentUser?.displayName ?? ''),
    );
    if (auth.userProfile?.phone.isNotEmpty == true) {
      _phoneController.text = auth.userProfile!.phone;
    }
    if (auth.userProfile?.town.isNotEmpty == true) {
      _townController.text = auth.userProfile!.town;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _townController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AppAuthProvider>();

    final success = await auth.saveProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      town: _townController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!success && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.outOfStockRed,
          content: Text(auth.errorMessage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final lang = context.watch<LanguageProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang.isSinhala ? 'පැතිකඩ සම්පූර්ණ කරන්න' : 'Complete Profile',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null
                            ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Citizen',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.availableGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Google Verified',
                                style: TextStyle(
                                  color: AppColors.availableGreen,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  lang.isSinhala ? 'මූලික තොරතුරු' : 'Citizen Details',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.isSinhala
                      ? 'ගෑස් තොරතුරු සැපයීමේදී වගවීම සහ සත්‍යතාව තහවුරු කිරීම සඳහා ඔබගේ නම සහ ජංගම දුරකථන අංකය ඇතුළත් කරන්න.'
                      : 'Required to ensure reliable stock reporting and maintain high data integrity for all citizens.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                ),

                const SizedBox(height: 20),

                // Name Field
                Text(
                  lang.isSinhala ? 'සම්පූර්ණ නම *' : 'Full Name *',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kasun Perera',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
                    fillColor: AppColors.surfaceElevated,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return lang.isSinhala ? 'කරුණාකර ඔබගේ නම ඇතුළත් කරන්න' : 'Please enter your name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Phone Field
                Text(
                  lang.isSinhala ? 'ජංගම දුරකථන අංකය *' : 'Mobile Phone Number *',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 077 123 4567',
                    prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.textSecondary, size: 20),
                    fillColor: AppColors.surfaceElevated,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return lang.isSinhala ? 'දුරකථන අංකය ඇතුළත් කරන්න' : 'Please enter phone number';
                    }
                    final clean = val.replaceAll(RegExp(r'[\s\-\+]'), '');
                    if (clean.length < 9) {
                      return lang.isSinhala ? 'වලංගු දුරකථන අංකයක් ඇතුළත් කරන්න' : 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Town / City Field
                Text(
                  lang.isSinhala ? 'පදිංචි නගරය / ප්‍රදේශය' : 'Home Town / City',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _townController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Colombo, Kandy, Maharagama...',
                    prefixIcon: Icon(Icons.location_city_rounded, color: AppColors.textSecondary, size: 20),
                    fillColor: AppColors.surfaceElevated,
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.map_rounded, size: 20),
                    label: Text(
                      _isSaving
                          ? (lang.isSinhala ? 'සුරකිමින්...' : 'Saving Profile...')
                          : (lang.isSinhala ? 'සුරැක Map එකට පිවිසෙන්න' : 'Save & Open Gas Map'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
