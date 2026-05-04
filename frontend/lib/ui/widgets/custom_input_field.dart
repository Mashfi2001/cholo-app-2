import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors.dart';

class CustomInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Widget? prefix;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int? maxLines;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.prefix,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isFocused = false;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: Container(
          height: widget.maxLines == 1 ? 52 : null,
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? AppColors.pureWhite : AppColors.borderGray,
              width: 1,
            ),
          ),
          child: AbsorbPointer(
            absorbing: widget.readOnly && widget.onTap != null,
            child: TextField(
              controller: widget.controller,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              obscureText: _obscureText,
              maxLines: widget.maxLines,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: AppColors.pureWhite,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hint,
                labelStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.silverMid,
                ),
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppColors.silverMid,
                ),
                prefixIcon: widget.prefix ??
                    (widget.icon == null
                        ? null
                        : Icon(widget.icon, color: AppColors.silverMid, size: 20)),
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.silverMid,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
