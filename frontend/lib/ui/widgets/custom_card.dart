import 'package:flutter/material.dart';

import '../app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? margin;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.isSelected = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.cardBlack;
    final brdColor = isSelected
        ? AppColors.pureWhite
        : (borderColor ?? AppColors.borderGray);

    final cardContent = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: brdColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: child,
    );

    Widget result = cardContent;

    if (margin != null) {
      result = Container(
        margin: margin,
        child: result,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    return result;
  }
}
