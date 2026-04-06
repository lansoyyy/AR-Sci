import 'package:flutter/material.dart';

import '../models/formatted_content_block.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class FormattedContentEditor extends StatelessWidget {
  final List<FormattedContentBlock> blocks;
  final ValueChanged<List<FormattedContentBlock>> onChanged;
  final Future<String?> Function()? onAddImage;
  final bool allowImages;
  final String emptyLabel;

  const FormattedContentEditor({
    super.key,
    required this.blocks,
    required this.onChanged,
    this.onAddImage,
    this.allowImages = false,
    this.emptyLabel = 'Add a text block to start writing.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (blocks.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingL),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Text(
              emptyLabel,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...blocks.asMap().entries.map((entry) {
            return _buildEditorCard(context, entry.key, entry.value);
          }),
        const SizedBox(height: AppConstants.paddingM),
        Wrap(
          spacing: AppConstants.paddingS,
          runSpacing: AppConstants.paddingS,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addTextBlock(),
              icon: const Icon(Icons.notes_outlined),
              label: const Text('Add Text'),
            ),
            if (allowImages)
              OutlinedButton.icon(
                onPressed: () async {
                  final imageUrl = await onAddImage?.call();
                  if (imageUrl == null || imageUrl.trim().isEmpty) {
                    return;
                  }
                  _updateBlocks([
                    ...blocks,
                    FormattedContentBlock(
                      id: FormattedContentBlock.generateId(),
                      type: FormattedContentBlockType.image,
                      imageUrl: imageUrl,
                    ),
                  ]);
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Add Image'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorCard(
    BuildContext context,
    int index,
    FormattedContentBlock block,
  ) {
    final canMoveUp = index > 0;
    final canMoveDown = index < blocks.length - 1;

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  block.type == FormattedContentBlockType.image
                      ? Icons.image_outlined
                      : Icons.notes_outlined,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppConstants.paddingS),
                Text(
                  block.type == FormattedContentBlockType.image
                      ? 'Image Block'
                      : 'Text Block',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed:
                      canMoveUp ? () => _moveBlock(index, index - 1) : null,
                  icon: const Icon(Icons.arrow_upward_outlined),
                ),
                IconButton(
                  onPressed:
                      canMoveDown ? () => _moveBlock(index, index + 1) : null,
                  icon: const Icon(Icons.arrow_downward_outlined),
                ),
                IconButton(
                  onPressed: () => _removeBlock(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),
            if (block.type == FormattedContentBlockType.image)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
                child: Image.network(
                  block.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.broken_image_outlined),
                    );
                  },
                ),
              )
            else ...[
              Wrap(
                spacing: AppConstants.paddingS,
                runSpacing: AppConstants.paddingS,
                children: [
                  FilterChip(
                    label: const Text('Bold'),
                    selected: block.bold,
                    onSelected: (value) => _replaceBlock(
                      index,
                      block.copyWith(bold: value),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Underline'),
                    selected: block.underline,
                    onSelected: (value) => _replaceBlock(
                      index,
                      block.copyWith(underline: value),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Highlight'),
                    selected: block.highlight,
                    onSelected: (value) => _replaceBlock(
                      index,
                      block.copyWith(highlight: value),
                    ),
                  ),
                  DropdownButton<double>(
                    value: block.fontSize,
                    underline: const SizedBox.shrink(),
                    items: const <double>[14, 16, 18, 20, 24]
                        .map(
                          (size) => DropdownMenuItem<double>(
                            value: size,
                            child: Text('${size.toInt()} pt'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      _replaceBlock(index, block.copyWith(fontSize: value));
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingS),
              TextFormField(
                key: ValueKey(block.id),
                initialValue: block.text,
                maxLines: null,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your content here...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _replaceBlock(index, block.copyWith(text: value));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addTextBlock() {
    _updateBlocks([...blocks, FormattedContentBlock.emptyTextBlock()]);
  }

  void _removeBlock(int index) {
    final updated = [...blocks]..removeAt(index);
    _updateBlocks(updated);
  }

  void _replaceBlock(int index, FormattedContentBlock updatedBlock) {
    final updated = [...blocks];
    updated[index] = updatedBlock;
    _updateBlocks(updated);
  }

  void _moveBlock(int fromIndex, int toIndex) {
    final updated = [...blocks];
    final block = updated.removeAt(fromIndex);
    updated.insert(toIndex, block);
    _updateBlocks(updated);
  }

  void _updateBlocks(List<FormattedContentBlock> updatedBlocks) {
    onChanged(updatedBlocks);
  }
}
