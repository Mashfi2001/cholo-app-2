import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import 'role_selection_screen.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}

final List<OnboardingSlide> slides = [
  const OnboardingSlide(
    title: 'Find Your Ride',
    description: 'Search for available rides heading to your destination. Filter by time, price, and driver rating.',
    icon: Icons.search,
  ),
  const OnboardingSlide(
    title: 'Book Your Seat',
    description: 'Select the perfect seat and book instantly. No waiting, no hassle - just tap and go.',
    icon: Icons.event_seat,
  ),
  const OnboardingSlide(
    title: 'Ride Together',
    description: 'Share your journey with verified drivers and fellow passengers. Safe, social, and sustainable.',
    icon: Icons.people,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkipPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
    );
  }

  void _onGetStartedPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Full screen PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                slide: slides[index],
                isLastPage: index == slides.length - 1,
              );
            },
          ),

          // Skip button (top right)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: GestureDetector(
              onTap: _onSkipPressed,
              child: Text(
                'Skip',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.silverMid,
                ),
              ),
            ),
          ),

          // Bottom section with dots and button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryBlack
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _currentPage == index
                                ? AppColors.primaryBlack
                                : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Get Started button (only on last slide)
                  if (_currentPage == slides.length - 1)
                    CustomButton(
                      label: 'Get Started',
                      onPressed: _onGetStartedPressed,
                    )
                  else
                    CustomButton(
                      label: 'Next',
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final OnboardingSlide slide;
  final bool isLastPage;

  const OnboardingPage({
    super.key,
    required this.slide,
    required this.isLastPage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top 55%: illustration area
        Expanded(
          flex: 55,
          child: Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Icon(
                slide.icon,
                size: 80,
                color: AppColors.silverLight,
              ),
            ),
          ),
        ),
        // Bottom 45%: white container area (spacer for the actual bottom sheet)
        Expanded(
          flex: 45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  slide.title,
                  style: AppTextStyles.headingL.copyWith(
                    color: AppColors.primaryBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  slide.description,
                  style: AppTextStyles.bodyM.copyWith(
                    color: const Color(0xFF555555),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
