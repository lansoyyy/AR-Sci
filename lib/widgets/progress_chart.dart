import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class ProgressChart extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final Color? color;

  const ProgressChart({
    super.key,
    required this.data,
    required this.title,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chartColor = color ?? AppColors.studentPrimary;
    final maxValue = data.isEmpty ? 100.0 : data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      elevation: AppConstants.elevationS,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: AppConstants.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),
            
            // Simple Bar Chart
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((item) {
                  final heightPercentage = maxValue > 0 ? item.value / maxValue : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: AppConstants.fontS,
                              fontWeight: FontWeight.w600,
                              color: chartColor,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Container(
                            height: 150 * heightPercentage,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  chartColor,
                                  chartColor.withOpacity(0.6),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.radiusS),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingS),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: AppConstants.fontXS,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;

  ChartData({required this.label, required this.value});
}
