import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import 'register_screen.dart';

enum UserRole { driver, passenger }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  void _onContinuePressed() {
    if (_selectedRole != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RegisterScreen(selectedRole: _selectedRole!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back arrow
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.pureWhite,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 32),
              // Title
              Center(
                child: Text(
                  'I am a...',
                  style: AppTextStyles.headingXL,
                ),
              ),
              const SizedBox(height: 48),
              // Role cards
              if (isSmallScreen)
                // Stacked layout for small screens
                Column(
                  children: [
                    RoleCard(
                      icon: Icons.local_taxi,
                      label: 'Driver',
                      description: 'Create routes, accept passengers.',
                      isSelected: _selectedRole == UserRole.driver,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.driver;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    RoleCard(
                      icon: Icons.directions_walk,
                      label: 'Passenger',
                      description: 'Find rides, book seats.',
                      isSelected: _selectedRole == UserRole.passenger,
                      onTap: () {
                        setState(() {
                          _selectedRole = UserRole.passenger;
                        });
                      },
                    ),
                  ],
                )
              else
                // Side by side layout for larger screens
                Row(
                  children: [
                    Expanded(
                      child: RoleCard(
                        icon: Icons.local_taxi,
                        label: 'Driver',
                        description: 'Create routes, accept passengers.',
                        isSelected: _selectedRole == UserRole.driver,
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.driver;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RoleCard(
                        icon: Icons.directions_walk,
                        label: 'Passenger',
                        description: 'Find rides, book seats.',
                        isSelected: _selectedRole == UserRole.passenger,
                        onTap: () {
                          setState(() {
                            _selectedRole = UserRole.passenger;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              // Continue button
              CustomButton(
                label: 'Continue',
                onPressed: _selectedRole != null ? _onContinuePressed : null,
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      isSelected: isSelected,
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.pureWhite.withOpacity(0.1)
                  : AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.pureWhite : AppColors.borderGray,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.pureWhite : AppColors.silverLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.headingM.copyWith(
              color: isSelected ? AppColors.pureWhite : AppColors.silverLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyM,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
