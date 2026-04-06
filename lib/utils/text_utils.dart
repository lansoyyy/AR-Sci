String normalizeWhitespace(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String toTitleCase(String value) {
  final normalized = normalizeWhitespace(value);
  if (normalized.isEmpty) {
    return normalized;
  }

  final buffer = StringBuffer();
  var capitalizeNext = true;

  for (final rune in normalized.runes) {
    final character = String.fromCharCode(rune);
    final isLetter = RegExp(r'[A-Za-z]').hasMatch(character);

    if (isLetter) {
      buffer.write(
          capitalizeNext ? character.toUpperCase() : character.toLowerCase());
      capitalizeNext = false;
      continue;
    }

    buffer.write(character);
    capitalizeNext = character == ' ' ||
        character == '-' ||
        character == '/' ||
        character == '.' ||
        character == '\'';
  }

  return buffer.toString();
}

String normalizePersonName(String value) {
  return toTitleCase(value);
}

List<String> normalizeTextList(Iterable<String> values) {
  return values
      .map(toTitleCase)
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
}

String initialsFromName(String value) {
  final parts = normalizeWhitespace(value)
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
