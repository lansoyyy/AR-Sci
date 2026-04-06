import 'package:flutter/material.dart';

import '../models/formatted_content_block.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class FormattedContentView extends StatelessWidget {
  final List<FormattedContentBlock> blocks;
  final String? fallbackText;

  const FormattedContentView({
    super.key,
    required this.blocks,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      if (fallbackText == null || fallbackText!.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      return Text(
        fallbackText!,
        style: const TextStyle(
          fontSize: AppConstants.fontM,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map(_buildBlock).toList(),
    );
  }

  Widget _buildBlock(FormattedContentBlock block) {
    if (block.type == FormattedContentBlockType.image) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.paddingM),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          child: Image.network(
            block.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 180,
                color: AppColors.surfaceLight,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ),
      );
    }

    final decoration =
        block.underline ? TextDecoration.underline : TextDecoration.none;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: block.highlight ? const Color(0xFFFFF3B0) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        block.text,
        style: TextStyle(
          fontSize: block.fontSize,
          fontWeight: block.bold ? FontWeight.w700 : FontWeight.normal,
          decoration: decoration,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}
