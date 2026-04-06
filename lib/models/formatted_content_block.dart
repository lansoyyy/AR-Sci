import '../utils/text_utils.dart';

enum FormattedContentBlockType { text, image }

class FormattedContentBlock {
  final String id;
  final FormattedContentBlockType type;
  final String text;
  final String imageUrl;
  final bool bold;
  final bool underline;
  final bool highlight;
  final double fontSize;

  const FormattedContentBlock({
    required this.id,
    required this.type,
    this.text = '',
    this.imageUrl = '',
    this.bold = false,
    this.underline = false,
    this.highlight = false,
    this.fontSize = 16,
  });

  bool get hasMeaningfulContent {
    if (type == FormattedContentBlockType.image) {
      return imageUrl.trim().isNotEmpty;
    }
    return normalizeWhitespace(text).isNotEmpty;
  }

  FormattedContentBlock copyWith({
    String? id,
    FormattedContentBlockType? type,
    String? text,
    String? imageUrl,
    bool? bold,
    bool? underline,
    bool? highlight,
    double? fontSize,
  }) {
    return FormattedContentBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      bold: bold ?? this.bold,
      underline: underline ?? this.underline,
      highlight: highlight ?? this.highlight,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  factory FormattedContentBlock.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'text').toString().toLowerCase();
    final fontSize = json['fontSize'] is num
        ? (json['fontSize'] as num).toDouble()
        : double.tryParse((json['fontSize'] ?? '').toString()) ?? 16;
    return FormattedContentBlock(
      id: (json['id'] ?? generateId()).toString(),
      type: rawType == 'image'
          ? FormattedContentBlockType.image
          : FormattedContentBlockType.text,
      text: (json['text'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      bold: json['bold'] == true,
      underline: json['underline'] == true,
      highlight: json['highlight'] == true,
      fontSize: fontSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'text': text,
      'imageUrl': imageUrl,
      'bold': bold,
      'underline': underline,
      'highlight': highlight,
      'fontSize': fontSize,
    };
  }

  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  static FormattedContentBlock emptyTextBlock() {
    return FormattedContentBlock(
      id: generateId(),
      type: FormattedContentBlockType.text,
    );
  }

  static List<FormattedContentBlock> listFromJson(
    dynamic value, {
    String fallbackText = '',
  }) {
    final parsedBlocks = <FormattedContentBlock>[];

    if (value is List) {
      for (final entry in value) {
        if (entry is Map<String, dynamic>) {
          final block = FormattedContentBlock.fromJson(entry);
          if (block.hasMeaningfulContent) {
            parsedBlocks.add(block);
          }
        } else if (entry is Map) {
          final block = FormattedContentBlock.fromJson(
            Map<String, dynamic>.from(entry),
          );
          if (block.hasMeaningfulContent) {
            parsedBlocks.add(block);
          }
        }
      }
    }

    if (parsedBlocks.isNotEmpty) {
      return parsedBlocks;
    }

    final normalizedFallback = normalizeWhitespace(fallbackText);
    if (normalizedFallback.isNotEmpty) {
      return <FormattedContentBlock>[
        FormattedContentBlock(
          id: generateId(),
          type: FormattedContentBlockType.text,
          text: fallbackText.trim(),
        ),
      ];
    }

    return <FormattedContentBlock>[];
  }

  static List<Map<String, dynamic>> listToJson(
    List<FormattedContentBlock> blocks,
  ) {
    return blocks.where((block) => block.hasMeaningfulContent).map((block) {
      return block.toJson();
    }).toList();
  }

  static String plainText(List<FormattedContentBlock> blocks) {
    return blocks
        .where((block) =>
            block.type == FormattedContentBlockType.text &&
            block.text.trim().isNotEmpty)
        .map((block) => block.text.trim())
        .join('\n\n');
  }

  static List<String> imageUrls(List<FormattedContentBlock> blocks) {
    return blocks
        .where((block) =>
            block.type == FormattedContentBlockType.image &&
            block.imageUrl.trim().isNotEmpty)
        .map((block) => block.imageUrl.trim())
        .toList();
  }
}
