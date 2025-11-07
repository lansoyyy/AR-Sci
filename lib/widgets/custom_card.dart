import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardBorderRadius =
        borderRadius ?? BorderRadius.circular(AppConstants.radiusM);

    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.cardBackground) : null,
        gradient: gradient,
        borderRadius: cardBorderRadius,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: cardBorderRadius,
        child: cardContent,
      );
    }

    return Card(
      elevation: elevation ?? AppConstants.elevationS,
      margin: margin ??
          const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingS,
          ),
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: cardContent,
    );
  }
}
