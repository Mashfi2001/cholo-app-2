import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../session.dart';
import '../../backend_config.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final int rideId;
  final dynamic ride;
  final List<int> selectedSeats;
  final int totalFare;

  const BookingConfirmationScreen({
    super.key,
    required this.rideId,
    required this.ride,
    required this.selectedSeats,
    required this.totalFare,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isLoading = false;
  String _paymentMethod = 'Cash on Ride';

  Future<void> _bookNow() async {
    if (Session.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please login first',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/seat-booking'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rideId': widget.rideId,
          'userId': Session.userId,
          'seats': widget.selectedSeats,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Show success bottom sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (context) => BookingSuccessBottomSheet(
            ride: widget.ride,
            selectedSeats: widget.selectedSeats,
            totalFare: widget.totalFare,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error']?.toString() ?? 'Booking failed',
              style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.ride['driver']?['name'] ?? 'Driver';
    final origin = widget.ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = widget.ride['destination']?.toString().split(',').first ?? 'Unknown';
    final departureTime = _formatDateTime(widget.ride['departureTime'] ?? '');

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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Confirm Booking',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Summary Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Summary',
                      style: AppTextStyles.headingL.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    // Route
                    Row(
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 1,
                              height: 30,
                              color: AppColors.borderGray,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppColors.pureWhite,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderGray),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                origin,
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                destination,
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.pureWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Divider(color: AppColors.borderGray),
                    const SizedBox(height: 16),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: AppColors.silverMid, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          departureTime,
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Seats
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: AppColors.silverMid, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.selectedSeats.length} seat${widget.selectedSeats.length > 1 ? 's' : ''} (Seat ${widget.selectedSeats.join(", ")})',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Driver
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlack,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: const Icon(Icons.person, color: AppColors.silverLight, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          driverName,
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Price Breakdown Card
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Breakdown',
                      style: AppTextStyles.headingL.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base fare',
                          style: AppTextStyles.bodyM,
                        ),
                        Text(
                          'BDT ${widget.totalFare - (widget.totalFare * 0.1).ceil()}',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service fee',
                          style: AppTextStyles.bodyM,
                        ),
                        Text(
                          'BDT ${(widget.totalFare * 0.1).ceil()}',
                          style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: AppColors.borderGray),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: AppTextStyles.headingM,
                        ),
                        Text(
                          'BDT ${widget.totalFare}',
                          style: AppTextStyles.headingL,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment Method
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Method',
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _paymentMethod,
                            style: AppTextStyles.bodyL.copyWith(
                              color: AppColors.pureWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Show payment method picker
                      },
                      child: Text(
                        'Change',
                        style: AppTextStyles.labelBold.copyWith(
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms note
              Center(
                child: Text(
                  'By confirming, you agree to our cancellation policy.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Book Now button
              CustomButton(
                label: 'Book Now',
                onPressed: _isLoading ? null : _bookNow,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$day/$month/$year at $hour:$minute $suffix';
    } catch (e) {
      return '';
    }
  }
}

class BookingSuccessBottomSheet extends StatelessWidget {
  final dynamic ride;
  final List<int> selectedSeats;
  final int totalFare;

  const BookingSuccessBottomSheet({
    super.key,
    required this.ride,
    required this.selectedSeats,
    required this.totalFare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.successGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Booking Confirmed!',
            style: AppTextStyles.headingL,
          ),
          const SizedBox(height: 8),

          Text(
            'Your ride has been booked successfully',
            style: AppTextStyles.bodyM,
          ),
          const SizedBox(height: 24),

          // Summary
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Seats:', style: AppTextStyles.bodyM),
                    Text(
                      '${selectedSeats.length} seat${selectedSeats.length > 1 ? 's' : ''}',
                      style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: AppTextStyles.bodyM),
                    Text(
                      'BDT $totalFare',
                      style: AppTextStyles.headingM,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          CustomButton(
            label: 'View My Ride',
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              // Navigate to My Rides
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Back to Home',
              style: AppTextStyles.bodyM.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
