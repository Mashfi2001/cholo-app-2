import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';
import 'custom_button.dart';

/// Error state widget with retry button
class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.silverMid,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              title ?? 'Something went wrong',
              style: AppTextStyles.headingL.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle ?? 'Please try again later',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              CustomButton(
                label: 'Try Again',
                variant: CustomButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget with customizable content
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: AppColors.silverMid,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headingL.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.bodyM,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              CustomButton(
                label: actionLabel!,
                variant: CustomButtonVariant.secondary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error widget with retry button
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              color: AppColors.silverMid,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No internet connection',
              style: AppTextStyles.headingL.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: AppTextStyles.bodyM,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              CustomButton(
                label: 'Retry',
                variant: CustomButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading shimmer placeholder
class LoadingShimmer extends StatefulWidget {
  final int itemCount;
  final bool showAvatar;

  const LoadingShimmer({
    super.key,
    this.itemCount = 5,
    this.showAvatar = true,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  if (widget.showAvatar) ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBlack,
                        shape: BoxShape.circle,
                      ),
                      child: _buildShimmerEffect(),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildShimmerEffect(),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 150,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlack,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildShimmerEffect(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.surfaceBlack,
            AppColors.cardBlack,
            AppColors.surfaceBlack,
          ],
          stops: [
            _controller.value - 0.3,
            _controller.value,
            _controller.value + 0.3,
          ],
        ),
      ),
    );
  }
}

/// No results found widget
class NoResultsWidget extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClear;

  const NoResultsWidget({
    super.key,
    this.searchQuery,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: AppColors.silverMid,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: AppTextStyles.headingL.copyWith(fontSize: 22),
            ),
            if (searchQuery != null) ...[
              const SizedBox(height: 8),
              Text(
                'for "$searchQuery"',
                style: AppTextStyles.bodyM,
                textAlign: TextAlign.center,
              ),
            ],
            if (onClear != null) ...[
              const SizedBox(height: 32),
              CustomButton(
                label: 'Clear Search',
                variant: CustomButtonVariant.secondary,
                onPressed: onClear,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
