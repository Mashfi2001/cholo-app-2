import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';
import '../../ui/widgets/custom_card.dart';
import '../../ui/widgets/ride_card.dart';
import '../../session.dart';
import '../../backend_config.dart';
import 'booking_confirmation_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int rideId;
  final dynamic ride;

  const SeatSelectionScreen({
    super.key,
    required this.rideId,
    required this.ride,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<int> _selectedSeats = {};
  int _totalSeats = 0;
  List<int> _bookedSeats = [];
  int? _unitFare;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
  }

  Future<void> _fetchSeats() async {
    setState(() => _isLoading = true);
    try {
      final userIdQuery = Session.userId != null ? "?userId=${Session.userId}" : "";
      final url = "$backendUrl/seat-booking/${widget.rideId}/seats$userIdQuery";

      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          _totalSeats = data["totalSeats"];
          _bookedSeats = List<int>.from(data["bookedSeats"]);
          final u = data["unitPassengerFare"];
          _unitFare = u == null ? null : (u is num ? u.ceil() : int.tryParse(u.toString()));
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to load seats';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSeatTapped(int seatNo) {
    if (_bookedSeats.contains(seatNo)) return;

    setState(() {
      if (_selectedSeats.contains(seatNo)) {
        _selectedSeats.remove(seatNo);
      } else {
        _selectedSeats.add(seatNo);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least one seat',
            style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.warningAmber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          rideId: widget.rideId,
          ride: widget.ride,
          selectedSeats: _selectedSeats.toList(),
          totalFare: (_unitFare ?? 80) * _selectedSeats.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFare = (_unitFare ?? 80) * _selectedSeats.length;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Seat',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Ride summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: RideCard(
                ride: widget.ride,
                showViewSeats: false,
                compact: true,
              ),
            ),

            const SizedBox(height: 24),

            // Available seats label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(
                    'AVAILABLE SEATS',
                    style: AppTextStyles.caption.copyWith(letterSpacing: 1),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Seat grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.pureWhite),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Text(_errorMessage!, style: AppTextStyles.bodyM),
                        )
                      : _buildSeatGrid(),
            ),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.cardBlack, 'Available', true),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.pureWhite, 'Selected', false),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.borderGray, 'Booked', false),
                ],
              ),
            ),

            // Price summary
            if (_selectedSeats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedSeats.length} seat${_selectedSeats.length > 1 ? 's' : ''} × BDT ${_unitFare ?? 80}',
                        style: AppTextStyles.bodyL.copyWith(color: AppColors.pureWhite),
                      ),
                      Text(
                        'BDT $totalFare',
                        style: AppTextStyles.headingM,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Confirm button
            Padding(
              padding: const EdgeInsets.all(24),
              child: CustomButton(
                label: _selectedSeats.isEmpty
                    ? 'Select Seats'
                    : 'Confirm Selection',
                onPressed: _selectedSeats.isEmpty ? null : _confirmSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatGrid() {
    // Seat 1 is front passenger, rest are back rows
    final backSeatCount = _totalSeats > 1 ? _totalSeats - 1 : 0;

    List<Widget> backRows = [];
    int remaining = backSeatCount;
    int seatNo = 2;

    while (remaining > 0) {
      int inThisRow = remaining >= 3 ? 3 : remaining;
      List<Widget> seats = [];

      for (int i = 0; i < inThisRow; i++) {
        if (i > 0) seats.add(const SizedBox(width: 12));
        seats.add(_buildSeatTile(seatNo));
        seatNo++;
      }

      if (backRows.isNotEmpty) {
        backRows.add(const SizedBox(height: 12));
      }

      backRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: seats,
        ),
      );

      remaining -= inThisRow;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Front section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'FRONT',
              style: AppTextStyles.caption.copyWith(letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 16),

          // Front row: passenger + driver
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSeatTile(1),
                _buildDriverTile(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Back section label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'BACK',
              style: AppTextStyles.caption.copyWith(letterSpacing: 2),
            ),
          ),
          const SizedBox(height: 16),

          // Back rows
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGray),
            ),
            child: Column(children: backRows),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDriverTile() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_taxi, color: AppColors.silverMid, size: 24),
          const SizedBox(height: 4),
          Text(
            'Driver',
            style: AppTextStyles.caption.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatTile(int seatNo) {
    final isBooked = _bookedSeats.contains(seatNo);
    final isSelected = _selectedSeats.contains(seatNo);

    return GestureDetector(
      onTap: isBooked ? null : () => _onSeatTapped(seatNo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isBooked
              ? AppColors.borderGray
              : isSelected
                  ? AppColors.pureWhite
                  : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isBooked
                ? AppColors.borderGray
                : isSelected
                    ? AppColors.pureWhite
                    : AppColors.borderGray,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.event_seat,
            color: isBooked
                ? AppColors.silverMid.withOpacity(0.5)
                : isSelected
                    ? AppColors.primaryBlack
                    : AppColors.silverLight,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool hasBorder) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: AppColors.borderGray) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
