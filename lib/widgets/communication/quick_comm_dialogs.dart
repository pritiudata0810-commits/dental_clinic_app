import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../services/telephony/call_service.dart';
import '../../services/telephony/messaging_service.dart';
import '../../services/telephony/phone_number_util.dart';
import '../../services/auth_service.dart';
import '../common/app_button.dart';
import '../common/toast_notification.dart';

class QuickCommDialogs {
  // CALL CONFIRMATION MODAL (LEVEL 1 NATIVE DIALER)
  static void showCallDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
    VoidCallback? onCallInitiated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CallConfirmationModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        onCallInitiated: onCallInitiated,
      ),
    );
  }

  // SMS MODAL
  static void showSmsDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
    String? defaultTemplate,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _SmsModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        defaultTemplate: defaultTemplate,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        doctorName: doctorName,
      ),
    );
  }

  // WHATSAPP MODAL
  static void showWhatsAppDialog(
    BuildContext context, {
    required String patientId,
    required String patientName,
    required String phoneNumber,
    String? defaultTemplate,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _WhatsAppModal(
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        defaultTemplate: defaultTemplate,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        doctorName: doctorName,
      ),
    );
  }
}

/// Real Call Confirmation Modal.
///
/// Confirms patient identity, validates & normalizes phone number,
/// and dispatches the actual device phone dialer without fake timers.
class _CallConfirmationModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final VoidCallback? onCallInitiated;

  const _CallConfirmationModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    this.onCallInitiated,
  });

  @override
  State<_CallConfirmationModal> createState() => _CallConfirmationModalState();
}

class _CallConfirmationModalState extends State<_CallConfirmationModal> {
  final TextEditingController _noteController = TextEditingController();
  bool _isLaunching = false;
  late PhoneNumberValidationResult _validation;

  @override
  void initState() {
    super.initState();
    _validation = PhoneNumberUtil.validateAndNormalize(widget.phoneNumber);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmCall() async {
    setState(() => _isLaunching = true);

    final result = await CallService.instance.initiateCall(
      patientId: widget.patientId,
      patientName: widget.patientName,
      rawPhoneNumber: widget.phoneNumber,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (!mounted) return;

    setState(() => _isLaunching = false);

    if (result.isSuccess) {
      if (result.record != null) {
        context.clinic.addCallRecord(result.record!);
      }
      Navigator.of(context).pop();
      AppFeedback.showSuccess(
        context,
        'Phone dialer opened for ${widget.patientName}.',
      );
      widget.onCallInitiated?.call();
    } else {
      AppFeedback.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffProfile = AuthService.instance.currentProfile;
    final staffName = staffProfile?.fullName.isNotEmpty == true
        ? staffProfile!.fullName
        : 'Clinic Staff';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _validation.isValid
                        ? AppColors.callGreen.withValues(alpha: 0.12)
                        : const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _validation.isValid ? Icons.phone_forwarded_rounded : Icons.phone_disabled_rounded,
                    size: 28,
                    color: _validation.isValid ? AppColors.callGreen : const Color(0xFFDC2626),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              const Center(
                child: Text(
                  'Call Patient?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Patient Name
              Center(
                child: Text(
                  widget.patientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone Number Container
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _validation.isValid ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _validation.isValid ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _validation.isValid ? Icons.phone_rounded : Icons.error_outline_rounded,
                      size: 20,
                      color: _validation.isValid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _validation.isValid
                                ? (_validation.formattedDisplay ?? widget.phoneNumber)
                                : 'Invalid Phone Number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _validation.isValid ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            ),
                          ),
                          if (!_validation.isValid)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                _validation.errorMessage ?? 'No valid phone number is available for this patient.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Caller Session Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Calling as: $staffName',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Optional Note
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Call Notes (Optional)',
                  hintText: 'e.g., Appointment confirmation, lab reminder',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // Action Buttons: Cancel and Call
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLaunching ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.callGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _isLaunching
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.phone_rounded, size: 18),
                      label: Text(
                        _isLaunching ? 'Opening...' : 'Call',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: (_validation.isValid && !_isLaunching)
                          ? _handleConfirmCall
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmsModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String? defaultTemplate;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? doctorName;

  const _SmsModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    this.defaultTemplate,
    this.appointmentDate,
    this.appointmentTime,
    this.doctorName,
  });

  @override
  State<_SmsModal> createState() => _SmsModalState();
}

class _SmsModalState extends State<_SmsModal> {
  late TextEditingController _controller;
  String _selectedCategory = 'Appointment Reminder';
  bool _isLaunching = false;
  late PhoneNumberValidationResult _validation;

  late final Map<String, String> _templates;

  @override
  void initState() {
    super.initState();
    _validation = PhoneNumberUtil.validateAndNormalize(widget.phoneNumber);

    final String apptTimeStr = widget.appointmentDate != null
        ? '${widget.appointmentDate}${widget.appointmentTime != null ? ' at ${widget.appointmentTime}' : ''}'
        : 'today';
    final String doctor = widget.doctorName ?? 'SmileCare Clinic';

    _templates = {
      'Appointment Reminder':
          'Dear {Patient}, reminder for your dental appointment with $doctor scheduled $apptTimeStr. Please arrive 10 min early.',
      'Payment Reminder':
          'SmileCare: Outstanding balance payment reminder of ₹1,500. Kindly settle via UPI or at reception.',
      'Follow-up':
          'Dear {Patient}, how is your recovery following your dental visit? Please call SmileCare for any discomfort.',
      'Custom': '',
    };

    final initial = widget.defaultTemplate ??
        _templates['Appointment Reminder']!.replaceAll('{Patient}', widget.patientName);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        if (category != 'Custom') {
          _controller.text = _templates[category]!.replaceAll('{Patient}', widget.patientName);
        }
      });
    }
  }

  Future<void> _sendSms() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppFeedback.showError(context, 'Please enter a message to send.');
      return;
    }

    setState(() => _isLaunching = true);

    final result = await MessagingService.instance.openSmsComposer(
      rawPhoneNumber: widget.phoneNumber,
      patientName: widget.patientName,
      message: text,
    );

    if (!mounted) return;
    setState(() => _isLaunching = false);

    if (result.isSuccess) {
      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'SMS composer opened for ${widget.patientName}');
    } else {
      AppFeedback.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send SMS Message', style: AppTextStyles.h4),
                        Text(
                          'To: ${widget.patientName} (${widget.phoneNumber})',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (!_validation.isValid) ...[
                          const SizedBox(height: 2),
                          Text(
                            _validation.errorMessage ?? 'Invalid phone number',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Template Category'),
                items: _templates.keys.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_controller.text.length} characters (1 SMS credit)',
                  style: AppTextStyles.caption,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    text: 'Cancel',
                    onPressed: _isLaunching ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: _isLaunching ? 'Opening...' : 'Send SMS',
                    icon: _isLaunching ? null : Icons.send_rounded,
                    onPressed: _isLaunching ? null : _sendSms,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WhatsAppModal extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String phoneNumber;
  final String? defaultTemplate;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? doctorName;

  const _WhatsAppModal({
    required this.patientId,
    required this.patientName,
    required this.phoneNumber,
    this.defaultTemplate,
    this.appointmentDate,
    this.appointmentTime,
    this.doctorName,
  });

  @override
  State<_WhatsAppModal> createState() => _WhatsAppModalState();
}

class _WhatsAppModalState extends State<_WhatsAppModal> {
  late TextEditingController _controller;
  String _selectedCategory = 'Appointment Reminder';
  bool _isLaunching = false;
  late PhoneNumberValidationResult _validation;

  late final Map<String, String> _templates;

  @override
  void initState() {
    super.initState();
    _validation = PhoneNumberUtil.validateAndNormalize(widget.phoneNumber);

    final String apptTimeStr = widget.appointmentDate != null
        ? '${widget.appointmentDate}${widget.appointmentTime != null ? ' at ${widget.appointmentTime}' : ''}'
        : 'today';
    final String doctor = widget.doctorName ?? 'Dr. Rahul Sharma';

    _templates = {
      'Appointment Reminder':
          'Hello {Patient} 👋\n\nThis is a gentle reminder for your dental consultation with $doctor at *SmileCare Dental Clinic* scheduled $apptTimeStr.\n\n📍 Operatory Wing B\n⏱️ Please report 10 minutes prior.\n\nNeed to reschedule? Reply to this message directly.',
      'Follow-up':
          'Hello {Patient} 👋\n\n$doctor and the team at *SmileCare Clinic* hope you are recovering well after your visit. Remember to follow prescribed post-op oral care guidelines. Contact us if you have any questions!',
      'Payment Reminder':
          'Dear {Patient} 👋\n\nYour digital invoice is ready from *SmileCare Dental Clinic*. Pending balance: *₹1,500*.\n\nYou can pay directly via UPI at reception or online.',
      'Custom': '',
    };

    final initial = widget.defaultTemplate ??
        _templates['Appointment Reminder']!.replaceAll('{Patient}', widget.patientName);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? category) {
    if (category != null) {
      setState(() {
        _selectedCategory = category;
        if (category != 'Custom') {
          _controller.text = _templates[category]!.replaceAll('{Patient}', widget.patientName);
        }
      });
    }
  }

  Future<void> _sendWhatsApp() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      AppFeedback.showError(context, 'Please enter a message to send.');
      return;
    }

    setState(() => _isLaunching = true);

    final result = await MessagingService.instance.openWhatsApp(
      rawPhoneNumber: widget.phoneNumber,
      patientName: widget.patientName,
      message: text,
    );

    if (!mounted) return;
    setState(() => _isLaunching = false);

    if (result.isSuccess) {
      Navigator.of(context).pop();
      AppFeedback.showSuccess(context, 'WhatsApp opened for ${widget.patientName}');
    } else {
      AppFeedback.showError(context, result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Patient Notification', style: AppTextStyles.h4),
                        Text(
                          'Patient: ${widget.patientName} • ${widget.phoneNumber}',
                          style: AppTextStyles.bodySmall,
                        ),
                        if (!_validation.isValid) ...[
                          const SizedBox(height: 2),
                          Text(
                            _validation.errorMessage ?? 'Invalid phone number',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Notification Template'),
                items: _templates.keys.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: _onCategoryChanged,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEAE2), // WhatsApp chat bubble bg look
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: 'Type your message...',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.ghost(
                    text: 'Cancel',
                    onPressed: _isLaunching ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  AppButton.success(
                    text: _isLaunching ? 'Opening...' : 'Send on WhatsApp',
                    icon: _isLaunching ? null : Icons.send,
                    onPressed: _isLaunching ? null : _sendWhatsApp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
