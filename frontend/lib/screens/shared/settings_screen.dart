import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Settings menu
              CustomCard(
                child: Column(
                  children: [
                    _buildToggleItem(
                      icon: Icons.notifications,
                      title: 'Push Notifications',
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                      },
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildNavigationItem(
                      icon: Icons.location_on,
                      title: 'Location Permissions',
                      onTap: () async {
                        // Open app settings
                        if (Platform.isAndroid) {
                          await launchUrl(Uri.parse('app-settings:'));
                        } else if (Platform.isIOS) {
                          await launchUrl(Uri.parse('app-settings:'));
                        }
                      },
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildChipItem(
                      icon: Icons.language,
                      title: 'Language',
                      value: _language,
                      onTap: () {
                        _showLanguagePicker();
                      },
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildNavigationItem(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      onTap: () async {
                        await launchUrl(Uri.parse('https://cholo.app/privacy'));
                      },
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildNavigationItem(
                      icon: Icons.description,
                      title: 'Terms of Service',
                      onTap: () async {
                        await launchUrl(Uri.parse('https://cholo.app/terms'));
                      },
                    ),
                    Divider(color: AppColors.borderGray, height: 1),
                    _buildStaticItem(
                      icon: Icons.info,
                      title: 'App Version',
                      value: 'v1.0.0',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.silverLight, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
          ),
          // Custom toggle switch
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppColors.pureWhite : AppColors.surfaceBlack,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: value ? AppColors.pureWhite : AppColors.borderGray,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: value ? AppColors.primaryBlack : AppColors.silverMid,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.silverLight, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.silverMid,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipItem({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.silverLight, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Text(
                value,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.pureWhite,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.silverMid,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.silverLight, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyM.copyWith(color: AppColors.silverMid),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    final languages = ['English', 'বাংলা (Bangla)'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceBlack,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Language',
              style: AppTextStyles.headingL,
            ),
            const SizedBox(height: 24),
            ...languages.map((lang) => GestureDetector(
              onTap: () {
                setState(() {
                  _language = lang;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _language == lang 
                      ? AppColors.pureWhite 
                      : AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _language == lang 
                        ? AppColors.pureWhite 
                        : AppColors.borderGray,
                  ),
                ),
                child: Text(
                  lang,
                  style: AppTextStyles.bodyL.copyWith(
                    color: _language == lang 
                        ? AppColors.primaryBlack 
                        : AppColors.pureWhite,
                    fontWeight: _language == lang 
                        ? FontWeight.w600 
                        : FontWeight.w400,
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
