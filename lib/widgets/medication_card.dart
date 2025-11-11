import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class MedicationCard extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final String time;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onMarkTaken;
  final VoidCallback? onMarkMissed;

  const MedicationCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.time,
    required this.status,
    this.onTap,
    this.onMarkTaken,
    this.onMarkMissed,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'taken':
      case 'completed':
        return AppColors.completed;
      case 'missed':
      case 'overdue':
        return AppColors.overdue;
      case 'pending':
      case 'inprogress':
        return AppColors.inProgress;
      case 'skipped':
      case 'notstarted':
        return AppColors.notStarted;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      case 'pending':
        return Icons.schedule;
      case 'skipped':
        return Icons.remove_circle;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      elevation: AppConstants.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        side: BorderSide(color: _getStatusColor().withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Row(
            children: [
              // Medication Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Icon(
                  Icons.medication,
                  color: _getStatusColor(),
                  size: AppConstants.iconL,
                ),
              ),
              const SizedBox(width: AppConstants.paddingM),

              // Medication Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicationName,
                      style: const TextStyle(
                        fontSize: AppConstants.fontL,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Text(
                      dosage,
                      style: const TextStyle(
                        fontSize: AppConstants.fontM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingXS),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: AppConstants.iconS,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppConstants.paddingXS),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: AppConstants.fontS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingM,
                      vertical: AppConstants.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusRound),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: AppConstants.iconS,
                          color: _getStatusColor(),
                        ),
                        const SizedBox(width: AppConstants.paddingXS),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: AppConstants.fontS,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons for Pending Status
                  if (status.toLowerCase() == 'pending') ...[
                    const SizedBox(height: AppConstants.paddingS),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.check, size: AppConstants.iconS),
                          color: AppColors.completed,
                          onPressed: onMarkTaken,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: AppConstants.paddingS),
                        IconButton(
                          icon:
                              const Icon(Icons.close, size: AppConstants.iconS),
                          color: AppColors.overdue,
                          onPressed: onMarkMissed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
