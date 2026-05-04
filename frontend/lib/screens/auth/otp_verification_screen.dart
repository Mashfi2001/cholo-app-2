import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  String? _errorMessage;
  int _resendTimer = 60;
  bool _canResend = false;
  Timer? _timer;

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
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {
      _errorMessage = null;
    });
  }

  void _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace &&
          _controllers[index].text.isEmpty &&
          index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // TODO: Implement actual OTP verification API call
    // For now, simulate success
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Show success and navigate to login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account verified successfully!',
          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
        ),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    // TODO: Implement resend OTP API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OTP resent successfully!',
          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
        ),
        backgroundColor: AppColors.surfaceBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'Verify Your Account',
                  style: AppTextStyles.headingXL,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Enter the 6-digit code sent to',
                  style: AppTextStyles.bodyM,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  widget.phone.isNotEmpty ? widget.phone : widget.email,
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: Focus(
                      onKeyEvent: (node, event) {
                        _onOtpKeyEvent(index, event);
                        return KeyEventResult.ignored;
                      },
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: AppTextStyles.headingM,
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.cardBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderGray,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.borderGray,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.pureWhite,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.dangerRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.dangerRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Verify button
              CustomButton(
                label: 'Verify',
                onPressed: _verifyOtp,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              // Resend code
              Center(
                child: _canResend
                    ? GestureDetector(
                        onTap: _resendOtp,
                        child: Text(
                          'Resend Code',
                          style: AppTextStyles.labelBold.copyWith(
                            color: AppColors.pureWhite,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        'Resend code in $_resendTimer seconds',
                        style: AppTextStyles.bodyM,
                      ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
