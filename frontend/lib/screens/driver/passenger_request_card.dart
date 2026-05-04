import 'package:flutter/material.dart';

import '../../ui/app_colors.dart';
import '../../ui/app_text_styles.dart';
import '../../ui/widgets/custom_button.dart';

class PassengerRequestCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const PassengerRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final passengerName = request['passenger']?['name'] ?? 'Passenger';
    final rating = request['passenger']?['rating']?.toStringAsFixed(1) ?? '4.5';
    final rides = request['passenger']?['totalRides']?.toString() ?? '0';
    final pickup = request['pickupStop']?.toString() ?? 'Pickup location';
    final seats = request['seats'] ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger info row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlack,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: const Icon(Icons.person, color: AppColors.silverLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passengerName,
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warningAmber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: AppTextStyles.bodyM,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· $rides rides',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Pickup info
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.silverMid, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pickup: $pickup',
                  style: AppTextStyles.bodyM,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Seats info
          Row(
            children: [
              const Icon(Icons.event_seat, color: AppColors.silverMid, size: 16),
              const SizedBox(width: 8),
              Text(
                'Seats requested: $seats',
                style: AppTextStyles.bodyM,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.borderGray, height: 1),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerRed,
                      side: const BorderSide(color: AppColors.dangerRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Reject',
                          style: AppTextStyles.labelBold,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pureWhite,
                      foregroundColor: AppColors.primaryBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Accept',
                          style: AppTextStyles.labelBold.copyWith(
                            color: AppColors.primaryBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
