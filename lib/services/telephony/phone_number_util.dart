/// Represents the outcome of phone number validation & normalization
class PhoneNumberValidationResult {
  final bool isValid;
  final String? normalizedNumber; // E.164 format, e.g. +919876543210
  final String? formattedDisplay; // Visual display, e.g. +91 98765 43210
  final String? errorMessage;

  const PhoneNumberValidationResult._({
    required this.isValid,
    this.normalizedNumber,
    this.formattedDisplay,
    this.errorMessage,
  });

  factory PhoneNumberValidationResult.valid({
    required String normalized,
    required String formatted,
  }) {
    return PhoneNumberValidationResult._(
      isValid: true,
      normalizedNumber: normalized,
      formattedDisplay: formatted,
    );
  }

  factory PhoneNumberValidationResult.invalid(String error) {
    return PhoneNumberValidationResult._(
      isValid: false,
      errorMessage: error,
    );
  }

  /// International digits-only format required for WhatsApp links (no leading '+')
  String? get whatsAppFormat => normalizedNumber?.replaceAll('+', '');
}

/// Robust Phone Number Normalization and Validation Engine.
///
/// Designed with specific support for Indian telecom numbers (+91)
/// and standard international E.164 formats.
class PhoneNumberUtil {
  PhoneNumberUtil._();

  /// Validate and normalize any raw patient phone number.
  ///
  /// Cleans out formatting noise (spaces, dashes, parentheses) and produces
  /// a clean E.164 standard phone string for the phone dialer or telephony provider.
  static PhoneNumberValidationResult validateAndNormalize(String? rawInput) {
    if (rawInput == null || rawInput.trim().isEmpty) {
      return PhoneNumberValidationResult.invalid(
        'Patient phone number is missing.',
      );
    }

    final trimmed = rawInput.trim();

    // 1. Strip all formatting artifacts except '+' and digits
    final cleaned = trimmed.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) {
      return PhoneNumberValidationResult.invalid(
        'No valid phone number is available for this patient.',
      );
    }

    String normalized;

    // 2. Evaluate and normalize based on pattern
    if (cleaned.startsWith('+91')) {
      // +91 followed by 10 digits
      final digits = cleaned.substring(3);
      if (digits.length == 10 && _isValidIndianLeadingDigit(digits)) {
        normalized = '+91$digits';
      } else {
        return PhoneNumberValidationResult.invalid(
          'Invalid Indian mobile number format. Must contain 10 valid digits.',
        );
      }
    } else if (cleaned.startsWith('+')) {
      // General international number
      final digits = cleaned.substring(1);
      if (digits.length >= 7 && digits.length <= 15) {
        normalized = cleaned;
      } else {
        return PhoneNumberValidationResult.invalid(
          'Invalid international phone number length.',
        );
      }
    } else if (cleaned.startsWith('0') && cleaned.length == 11) {
      // Leading zero standard Indian trunk: 09876543210
      final digits = cleaned.substring(1);
      if (_isValidIndianLeadingDigit(digits)) {
        normalized = '+91$digits';
      } else {
        return PhoneNumberValidationResult.invalid(
          'Invalid mobile number format.',
        );
      }
    } else if (cleaned.startsWith('91') && cleaned.length == 12) {
      // 91 prefix without plus: 919876543210
      final digits = cleaned.substring(2);
      if (_isValidIndianLeadingDigit(digits)) {
        normalized = '+91$digits';
      } else {
        return PhoneNumberValidationResult.invalid(
          'Invalid mobile number format.',
        );
      }
    } else if (cleaned.length == 10 && _isValidIndianLeadingDigit(cleaned)) {
      // Standard 10-digit Indian mobile: 9876543210
      normalized = '+91$cleaned';
    } else {
      return PhoneNumberValidationResult.invalid(
        'No valid phone number is available for this patient.',
      );
    }

    // 3. Format visual display
    final display = formatForDisplay(normalized);

    return PhoneNumberValidationResult.valid(
      normalized: normalized,
      formatted: display,
    );
  }

  /// Indian mobile numbers start with 6, 7, 8, or 9
  static bool _isValidIndianLeadingDigit(String tenDigits) {
    if (tenDigits.length != 10) return false;
    final first = tenDigits[0];
    return first == '6' || first == '7' || first == '8' || first == '9';
  }

  /// Format E.164 phone number nicely for UI display
  static String formatForDisplay(String normalized) {
    if (normalized.startsWith('+91') && normalized.length == 13) {
      final part1 = normalized.substring(3, 8);
      final part2 = normalized.substring(8);
      return '+91 $part1 $part2';
    }
    return normalized;
  }

  /// Mask the last digits of the phone number for patient privacy display
  static String maskPhoneNumber(String raw) {
    final result = validateAndNormalize(raw);
    if (!result.isValid || result.normalizedNumber == null) {
      return '••••••••••';
    }
    final norm = result.normalizedNumber!;
    if (norm.startsWith('+91') && norm.length == 13) {
      final lead = norm.substring(3, 8);
      return '+91 $lead •••••';
    }
    if (norm.length > 5) {
      return '${norm.substring(0, norm.length - 4)}••••';
    }
    return norm;
  }

  /// Normalizes and formats a phone number strictly for WhatsApp wa.me links
  /// (international digits-only format with country code and no '+', e.g. 919876543210).
  static String? formatForWhatsApp(String? rawInput) {
    final result = validateAndNormalize(rawInput);
    if (!result.isValid || result.normalizedNumber == null) return null;
    return result.normalizedNumber!.replaceAll('+', '');
  }
}
