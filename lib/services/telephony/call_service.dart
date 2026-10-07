import 'package:flutter/foundation.dart';
import '../../models/communication.dart';
import '../../models/user_profile.dart';
import '../auth_service.dart';
import '../supabase_service.dart';
import 'phone_number_util.dart';
import 'telephony_provider.dart';

/// Outcome of a full call initiation attempt
class CallInitiationResult {
  final bool isSuccess;
  final String message;
  final CallRecord? record;
  final String? errorCode;

  const CallInitiationResult({
    required this.isSuccess,
    required this.message,
    this.record,
    this.errorCode,
  });

  factory CallInitiationResult.success({
    required String message,
    required CallRecord record,
  }) {
    return CallInitiationResult(
      isSuccess: true,
      message: message,
      record: record,
    );
  }

  factory CallInitiationResult.failed(
    String message, {
    String? errorCode,
    CallRecord? record,
  }) {
    return CallInitiationResult(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
      record: record,
    );
  }
}

/// Production Call Service enforcing:
/// 1. Staff Authentication & Role Authorization
/// 2. Patient Phone Number Validation & E.164 Normalization
/// 3. Real Telephony Dispatch (Level 1 Native Dialer / Level 2 Cloud Bridge)
/// 4. Accurate Status Auditing (`dialer_opened`, not fake `completed`)
/// 5. Persistent Supabase Call History Synchronization
class CallService extends ChangeNotifier {
  static final CallService instance = CallService._internal();
  factory CallService() => instance;
  CallService._internal();

  TelephonyProvider _activeProvider = NativeDialerProvider();

  TelephonyProvider get activeProvider => _activeProvider;
  TelephonyLevel get capabilityLevel => _activeProvider.capabilityLevel;

  void setProvider(TelephonyProvider provider) {
    _activeProvider = provider;
    notifyListeners();
  }

  /// Initiates an actual telephone call to a patient.
  ///
  /// Flow:
  /// 1. Authorize active staff session
  /// 2. Validate & normalize phone number
  /// 3. Dispatch to device dialer (tel:) or telephony gateway
  /// 4. Audit result into public.call_records with authentic status (dialer_opened / failed)
  Future<CallInitiationResult> initiateCall({
    required String patientId,
    required String patientName,
    required String rawPhoneNumber,
    String? note,
  }) async {
    final auth = AuthService.instance;
    final currentUser = auth.currentUser;
    final currentProfile = auth.currentProfile;

    // 1. Authorization Guard
    if (currentUser == null || currentProfile == null) {
      return CallInitiationResult.failed(
        'Authentication required. Please sign in to call patients.',
        errorCode: 'UNAUTHENTICATED',
      );
    }

    if (currentProfile.role == UserRole.patient) {
      return CallInitiationResult.failed(
        'Your account is not authorized to call patients.',
        errorCode: 'UNAUTHORIZED_ROLE',
      );
    }

    // 2. Validate & Normalize Phone Number
    final validation = PhoneNumberUtil.validateAndNormalize(rawPhoneNumber);
    if (!validation.isValid || validation.normalizedNumber == null) {
      final errorMsg = validation.errorMessage ??
          'No valid phone number is available for this patient.';
      debugPrint('[CallService] Phone validation rejected: $rawPhoneNumber -> $errorMsg');
      return CallInitiationResult.failed(
        errorMsg,
        errorCode: 'INVALID_PHONE_NUMBER',
      );
    }

    final normalizedPhone = validation.normalizedNumber!;
    final now = DateTime.now();
    final callId = 'CALL-${now.millisecondsSinceEpoch}';

    // 3. Dispatch to Real Telephony Provider
    final launchResult = await _activeProvider.launchCall(
      normalizedPhone: normalizedPhone,
      patientName: patientName,
    );

    // 4. Construct Call History Record with Genuine Status
    final record = CallRecord(
      id: callId,
      patientId: patientId,
      patientName: patientName,
      phoneNumber: normalizedPhone,
      timestamp: now,
      durationSeconds: 0, // 0 for dialer launch since external app handles voice
      direction: CallDirection.outgoing,
      status: launchResult.status, // dialer_opened or failed
      staffUserId: currentUser.id,
      staffName: currentProfile.fullName,
      clinicId: currentProfile.clinicId,
      callType: 'voice',
      note: note,
      errorMessage: launchResult.isSuccess ? null : launchResult.message,
    );

    // 5. Asynchronously persist to Supabase call_records
    await _persistCallRecord(record);

    notifyListeners();

    if (launchResult.isSuccess) {
      return CallInitiationResult.success(
        message: launchResult.message,
        record: record,
      );
    } else {
      return CallInitiationResult.failed(
        launchResult.message,
        errorCode: launchResult.errorCode,
        record: record,
      );
    }
  }

  /// Persist call record to Supabase
  Future<void> _persistCallRecord(CallRecord record) async {
    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        await client.from('call_records').insert({
          'id': record.id,
          'patient_id': record.patientId,
          'patient_name': record.patientName,
          'phone_number': record.phoneNumber,
          'timestamp': record.timestamp.toIso8601String(),
          'duration_seconds': record.durationSeconds,
          'direction': record.direction.value,
          'status': record.status.value,
          'staff_user_id': record.staffUserId,
          'staff_name': record.staffName,
          'clinic_id': record.clinicId,
          'call_type': record.callType,
          'note': record.note,
          'error_message': record.errorMessage,
        });
        debugPrint('[CallService] Call record logged in Supabase: ${record.id}');
      } catch (e) {
        debugPrint('[CallService] Supabase insert error for call record: $e');
      }
    }
  }

  /// Fetch historic call records for a patient or entire clinic
  Future<List<CallRecord>> fetchCallHistory({String? patientId}) async {
    final client = SupabaseService.instance.client;
    if (client == null) return [];

    try {
      var query = client.from('call_records').select();
      if (patientId != null && patientId.isNotEmpty) {
        query = query.eq('patient_id', patientId);
      }
      final data = await query.order('timestamp', ascending: false).limit(50);
      return (data as List<dynamic>)
          .map((m) => CallRecord.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[CallService] Error fetching call history: $e');
      return [];
    }
  }
}
