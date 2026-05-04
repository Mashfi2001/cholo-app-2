import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_text_styles.dart';

class RideCard extends StatelessWidget {
  final dynamic ride;
  final VoidCallback? onTap;
  final bool showViewSeats;
  final bool compact;

  const RideCard({
    super.key,
    required this.ride,
    this.onTap,
    this.showViewSeats = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final driverName = ride['driver']?['name'] ?? 'Driver';
    final driverRating = ride['driver']?['rating']?.toStringAsFixed(1) ?? '4.5';
    final isVerified = ride['driver']?['isVerified'] == true;
    final origin = ride['origin']?.toString().split(',').first ?? 'Unknown';
    final destination = ride['destination']?.toString().split(',').first ?? 'Unknown';
    final departureTime = _formatTime(ride['departureTime'] ?? '');
    final arrivalTime = _formatTime(ride['estimatedArrival'] ?? '');
    final seatsLeft = ride['seatsAvailable'] ?? ride['seats'] ?? 0;
    final farePerSeat = ride['unitPassengerFare'] ?? 80;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderGray),
        ),
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver info row
            Row(
              children: [
                Container(
                  width: compact ? 32 : 40,
                  height: compact ? 32 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.silverLight,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.warningAmber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driverRating,
                            style: AppTextStyles.bodyM,
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.borderGray, height: 1),
            const SizedBox(height: 16),

            // Route row
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
                    if (!compact) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 1,
                        height: 20,
                        color: AppColors.borderGray,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.pureWhite,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(BorderSide(color: AppColors.borderGray)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 12),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        departureTime,
                        style: AppTextStyles.caption,
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                        Text(
                          destination,
                          style: AppTextStyles.bodyL.copyWith(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          arrivalTime.isNotEmpty ? 'Est. $arrivalTime' : '',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact)
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.silverMid,
                    size: 20,
                  ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.borderGray, height: 1),
            const SizedBox(height: 12),

            // Seats and fare row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_seat,
                      color: seatsLeft <= 2 ? AppColors.warningAmber : AppColors.silverLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$seatsLeft seats left',
                      style: AppTextStyles.bodyM.copyWith(
                        color: seatsLeft <= 2 ? AppColors.warningAmber : AppColors.silverLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppColors.silverLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BDT $farePerSeat/seat',
                      style: AppTextStyles.bodyL.copyWith(
                        color: AppColors.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (showViewSeats) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Seats',
                        style: AppTextStyles.labelBold.copyWith(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.pureWhite,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    } catch (e) {
      return '';
    }
  }
}
