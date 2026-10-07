import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/communication.dart';

/// Levels of telephony capability
enum TelephonyLevel {
  level1NativeDialer,      // Opens device phone dialer (tel:+91...)
  level2ProviderOutbound,  // Backend VoIP provider bridge (e.g. Twilio REST call)
  level3AutomatedIVR,      // Automated IVR, status webhooks, recordings
}

/// Outcome of a call launch request
class CallLaunchResult {
  final bool isSuccess;
  final CallStatus status;
  final String message;
  final String? providerRef;
  final String? errorCode;

  const CallLaunchResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.providerRef,
    this.errorCode,
  });

  factory CallLaunchResult.success({
    required CallStatus status,
    required String message,
    String? providerRef,
  }) {
    return CallLaunchResult(
      isSuccess: true,
      status: status,
      message: message,
      providerRef: providerRef,
    );
  }

  factory CallLaunchResult.failed(
    String message, {
    String? errorCode,
  }) {
    return CallLaunchResult(
      isSuccess: false,
      status: CallStatus.failed,
      message: message,
      errorCode: errorCode,
    );
  }
}

/// Abstract contract for telephony dispatch mechanisms
abstract class TelephonyProvider {
  String get providerName;
  TelephonyLevel get capabilityLevel;

  Future<CallLaunchResult> launchCall({
    required String normalizedPhone,
    required String patientName,
  });
}

/// Level 1 Telephony Provider: Dispatches native device dialer via `tel:` URL scheme.
///
/// Uses the device's installed telephony application (Android Phone, iOS Phone, or desktop SIP client).
class NativeDialerProvider implements TelephonyProvider {
  @override
  String get providerName => 'Native Phone Dialer (tel:)';

  @override
  TelephonyLevel get capabilityLevel => TelephonyLevel.level1NativeDialer;

  @override
  Future<CallLaunchResult> launchCall({
    required String normalizedPhone,
    required String patientName,
  }) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: normalizedPhone);

    try {
      final bool canLaunch = await canLaunchUrl(phoneUri);
      if (!canLaunch) {
        debugPrint('[NativeDialerProvider] Device cannot launch tel: URI: $phoneUri');
        return CallLaunchResult.failed(
          'Unable to open phone dialer on this device. Telephony is not supported.',
          errorCode: 'DIALER_UNAVAILABLE',
        );
      }

      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        return CallLaunchResult.success(
          status: CallStatus.dialerOpened,
          message: 'Phone dialer opened for $patientName.',
        );
      } else {
        return CallLaunchResult.failed(
          'Failed to launch phone dialer.',
          errorCode: 'LAUNCH_FAILED',
        );
      }
    } catch (e) {
      debugPrint('[NativeDialerProvider] Exception opening dialer: $e');
      return CallLaunchResult.failed(
        'Unable to open phone dialer: $e',
        errorCode: 'EXCEPTION',
      );
    }
  }
}

/// Level 2/3 Telephony Provider: Architecture boundary for server-side cloud calling.
///
/// Calls out to a secure Supabase Edge Function (`dispatch-call`) or enterprise SIP gateway.
/// Does NOT store secret provider credentials inside the Flutter client.
class CloudTelephonyProvider implements TelephonyProvider {
  final String? edgeFunctionUrl;

  const CloudTelephonyProvider({this.edgeFunctionUrl});

  @override
  String get providerName => 'Cloud Telephony Gateway';

  @override
  TelephonyLevel get capabilityLevel => TelephonyLevel.level2ProviderOutbound;

  @override
  Future<CallLaunchResult> launchCall({
    required String normalizedPhone,
    required String patientName,
  }) async {
    if (edgeFunctionUrl == null || edgeFunctionUrl!.isEmpty) {
      return CallLaunchResult.failed(
        'Cloud telephony provider is not configured. Server credentials and Edge Function required.',
        errorCode: 'PROVIDER_NOT_CONFIGURED',
      );
    }

    // Server-side programmatic dispatch would happen here via Supabase Edge Function
    return CallLaunchResult.failed(
      'Automated cloud outbound calling requires active Twilio/Exotel provider credentials on the server.',
      errorCode: 'UNCONFIGURED_BACKEND',
    );
  }
}
