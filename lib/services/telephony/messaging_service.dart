import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'phone_number_util.dart';

/// Outcome of a real messaging dispatch request (WhatsApp or SMS composer)
class MessagingResult {
  final bool isSuccess;
  final String message;
  final String? errorCode;

  const MessagingResult({
    required this.isSuccess,
    required this.message,
    this.errorCode,
  });

  factory MessagingResult.success(String message) =>
      MessagingResult(isSuccess: true, message: message);

  factory MessagingResult.failed(String message, {String? errorCode}) =>
      MessagingResult(isSuccess: false, message: message, errorCode: errorCode);
}

typedef UrlLauncherFn = Future<bool> Function(Uri url, {LaunchMode mode});
typedef CanLaunchUrlFn = Future<bool> Function(Uri url);

/// Production Messaging Service for WhatsApp direct chat and device SMS composer.
///
/// Dispatches real system handlers via `url_launcher` without pretending
/// that messages were automatically sent or delivered.
class MessagingService {
  static final MessagingService instance = MessagingService._internal();
  factory MessagingService() => instance;
  MessagingService._internal();

  UrlLauncherFn _launcher = launchUrl;
  CanLaunchUrlFn _canLaunch = canLaunchUrl;

  @visibleForTesting
  void setLauncherOverrides({
    UrlLauncherFn? launcher,
    CanLaunchUrlFn? canLaunch,
  }) {
    _launcher = launcher ?? launchUrl;
    _canLaunch = canLaunch ?? canLaunchUrl;
  }

  @visibleForTesting
  void resetLauncherOverrides() {
    _launcher = launchUrl;
    _canLaunch = canLaunchUrl;
  }

  /// Builds a standard WhatsApp wa.me direct chat URI.
  ///
  /// Format: `https://wa.me/<international_number>?text=<url_encoded_message>`
  static Uri buildWhatsAppUri(String whatsAppDigits, String message) {
    return Uri.https(
      'wa.me',
      '/$whatsAppDigits',
      {'text': message},
    );
  }

  /// Builds a standard native SMS URI.
  ///
  /// Format: `sms:<number>?body=<url_encoded_message>`
  static Uri buildSmsUri(String normalizedNumber, String message) {
    return Uri(
      scheme: 'sms',
      path: normalizedNumber,
      queryParameters: {'body': message},
    );
  }

  /// Validates the recipient phone number and opens WhatsApp with pre-filled message text.
  ///
  /// Supports:
  /// - Indian standard mobile (10 digits -> 91 + number)
  /// - Full international numbers (E.164 without '+')
  ///
  /// Never claims message delivery; confirms when the WhatsApp application or web portal was opened.
  Future<MessagingResult> openWhatsApp({
    required String? rawPhoneNumber,
    required String patientName,
    required String message,
  }) async {
    final validation = PhoneNumberUtil.validateAndNormalize(rawPhoneNumber);
    if (!validation.isValid || validation.normalizedNumber == null) {
      return MessagingResult.failed(
        validation.errorMessage ?? 'Invalid phone number for patient.',
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    final String whatsAppDigits = validation.whatsAppFormat!;
    final Uri waUri = buildWhatsAppUri(whatsAppDigits, message);

    try {
      final bool canLaunch = await _canLaunch(waUri);
      if (!canLaunch) {
        // Attempt external launch in case canLaunchUrl was restricted by package visibility
        final bool launchedFallback = await _launcher(
          waUri,
          mode: LaunchMode.externalApplication,
        );
        if (launchedFallback) {
          return MessagingResult.success('WhatsApp opened for $patientName.');
        }
        return MessagingResult.failed(
          'Unable to open WhatsApp on this device. Please verify WhatsApp or a web browser is installed.',
          errorCode: 'WHATSAPP_UNAVAILABLE',
        );
      }

      final bool launched = await _launcher(
        waUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return MessagingResult.success('WhatsApp opened for $patientName.');
      } else {
        return MessagingResult.failed(
          'Could not launch WhatsApp for $patientName.',
          errorCode: 'LAUNCH_FAILED',
        );
      }
    } catch (e) {
      debugPrint('[MessagingService] Error launching WhatsApp: $e');
      return MessagingResult.failed(
        'Error opening WhatsApp: $e',
        errorCode: 'LAUNCH_EXCEPTION',
      );
    }
  }

  /// Validates the recipient phone number and opens the native device SMS composer.
  ///
  /// Populates the composer with the selected message/template for clinic staff review.
  /// Never claims message delivery or external SMS provider transmission.
  Future<MessagingResult> openSmsComposer({
    required String? rawPhoneNumber,
    required String patientName,
    required String message,
  }) async {
    final validation = PhoneNumberUtil.validateAndNormalize(rawPhoneNumber);
    if (!validation.isValid || validation.normalizedNumber == null) {
      return MessagingResult.failed(
        validation.errorMessage ?? 'Invalid phone number for patient.',
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    final Uri smsUri = buildSmsUri(validation.normalizedNumber!, message);

    try {
      final bool canLaunch = await _canLaunch(smsUri);
      if (!canLaunch) {
        // Attempt external launch in case canLaunchUrl was restricted by package visibility
        final bool launchedFallback = await _launcher(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
        if (launchedFallback) {
          return MessagingResult.success('SMS composer opened for $patientName.');
        }
        return MessagingResult.failed(
          'SMS messaging is not supported or no SMS app is installed on this device.',
          errorCode: 'SMS_UNAVAILABLE',
        );
      }

      final bool launched = await _launcher(
        smsUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return MessagingResult.success('SMS composer opened for $patientName.');
      } else {
        return MessagingResult.failed(
          'Could not open SMS composer for $patientName.',
          errorCode: 'LAUNCH_FAILED',
        );
      }
    } catch (e) {
      debugPrint('[MessagingService] Error launching SMS composer: $e');
      return MessagingResult.failed(
        'Error opening SMS composer: $e',
        errorCode: 'LAUNCH_EXCEPTION',
      );
    }
  }
}
