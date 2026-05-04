import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

enum CustomButtonVariant { primary, secondary, danger }

class CustomButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonVariant variant;
  final bool isLoading;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.height = 54,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = widget.variant == CustomButtonVariant.primary;
    final bool isDanger = widget.variant == CustomButtonVariant.danger;
    final bool isSecondary = widget.variant == CustomButtonVariant.secondary;

    final Color bg = isPrimary
        ? AppColors.pureWhite
        : (isDanger ? AppColors.dangerRed : Colors.transparent);
    final Color fg = isPrimary ? AppColors.primaryBlack : AppColors.pureWhite;

    return GestureDetector(
      onTapDown: widget.isLoading || widget.onPressed == null
          ? null
          : (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: double.infinity,
              height: widget.height,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100), // pill shape
                    side: BorderSide(
                      color: isSecondary
                          ? AppColors.pureWhite
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(fg),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
