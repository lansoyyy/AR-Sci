class PasswordPolicy {
  static const int minLength = 8;

  static final RegExp _letterRegex = RegExp(r'[A-Za-z]');
  static final RegExp _numberRegex = RegExp(r'\d');
  static final RegExp _specialCharacterRegex =
      RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:\"\\|,.<>\/?]');

  static const String helperText =
      'Use at least 8 characters with 1 letter, 1 number, and 1 special character.';

  static bool hasMinimumLength(String value) => value.length >= minLength;

  static bool hasLetter(String value) => _letterRegex.hasMatch(value);

  static bool hasNumber(String value) => _numberRegex.hasMatch(value);

  static bool hasSpecialCharacter(String value) =>
      _specialCharacterRegex.hasMatch(value);

  static bool isValid(String value) {
    return hasMinimumLength(value) &&
        hasLetter(value) &&
        hasNumber(value) &&
        hasSpecialCharacter(value);
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (!hasMinimumLength(value)) {
      return 'Password must be at least 8 characters';
    }
    if (!hasLetter(value)) {
      return 'Password must contain at least 1 letter';
    }
    if (!hasNumber(value)) {
      return 'Password must contain at least 1 number';
    }
    if (!hasSpecialCharacter(value)) {
      return 'Password must contain at least 1 special character';
    }
    return null;
  }
}
