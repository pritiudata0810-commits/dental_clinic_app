import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../../models/communication.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/communication/quick_comm_dialogs.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final callLogs = clinic.callRecords;
    final messages = clinic.messageRecords;
    final whatsappLogs = messages.where((m) => m.channel == MessageChannel.whatsapp).toList();
    final smsLogs = messages.where((m) => m.channel == MessageChannel.sms).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Calls & Patient Communication', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text(
                      'Track telephone contact logs, WhatsApp reminders, and automated clinic SMS alerts',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  AppButton.outline(
                    text: 'Send SMS',
                    icon: Icons.sms_outlined,
                    onPressed: () {
                      if (clinic.patients.isNotEmpty) {
                        final p = clinic.patients.first;
                        QuickCommDialogs.showSmsDialog(context, patientId: p.id, patientName: p.name, phoneNumber: p.phone);
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  AppButton.success(
                    text: 'WhatsApp Reminder',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () {
                      if (clinic.patients.isNotEmpty) {
                        final p = clinic.patients.first;
                        QuickCommDialogs.showWhatsAppDialog(context, patientId: p.id, patientName: p.name, phoneNumber: p.phone);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tabs: Calls, WhatsApp, SMS
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTab(0, 'Telephone Calls (${callLogs.length})', Icons.phone_outlined),
                _buildTab(1, 'WhatsApp Reminders (${whatsappLogs.length})', Icons.chat_bubble_outline),
                _buildTab(2, 'SMS Alerts (${smsLogs.length})', Icons.sms_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return _buildCallsList(context, callLogs);
                case 1:
                  return _buildMessagesList(context, whatsappLogs, isWhatsApp: true);
                case 2:
                  return _buildMessagesList(context, smsLogs, isWhatsApp: false);
                default:
                  return const SizedBox();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _tabController.index == index;

    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsList(BuildContext context, List<CallRecord> calls) {
    if (calls.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No call logs recorded today.'),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: calls.length,
        separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
        itemBuilder: (context, index) {
          final call = calls[index];
          final isMissed = call.status == CallStatus.missed;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isMissed ? const Color(0xFFFFE4E6) : const Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    call.direction == CallDirection.incoming
                        ? Icons.call_received_rounded
                        : isMissed
                            ? Icons.call_missed_rounded
                            : Icons.call_made_rounded,
                    size: 16,
                    color: isMissed ? const Color(0xFFBE123C) : const Color(0xFF047857),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(call.patientName, style: AppTextStyles.h4),
                      Text(call.phoneNumber, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(call.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(call.durationFormatted, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    call.note ?? 'Routine contact check',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppButton.outline(
                  text: 'Callback',
                  icon: Icons.phone_forwarded,
                  onPressed: () => QuickCommDialogs.showCallDialog(
                    context,
                    patientId: call.patientId,
                    patientName: call.patientName,
                    phoneNumber: call.phoneNumber,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context, List<MessageRecord> msgs, {required bool isWhatsApp}) {
    if (msgs.isEmpty) {
      return const AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No messages sent yet.'),
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: msgs.length,
        separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
        itemBuilder: (context, index) {
          final msg = msgs[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWhatsApp ? const Color(0xFFDCFCE7) : AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWhatsApp ? Icons.chat_bubble_outline : Icons.sms_outlined,
                    size: 16,
                    color: isWhatsApp ? const Color(0xFF16A34A) : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.patientName, style: AppTextStyles.h4),
                      Text(msg.phoneNumber, style: AppTextStyles.caption),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(msg.templateCategory, style: AppTextStyles.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      msg.message,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('hh:mm a').format(msg.timestamp), style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.done_all, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          msg.status.name.toUpperCase(),
                          style: AppTextStyles.label.copyWith(fontSize: 10, color: const Color(0xFF047857)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
