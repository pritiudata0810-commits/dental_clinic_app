import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../state/clinic_scope.dart';
import '../common/search_bar_field.dart';
import '../common/app_button.dart';

class AppTopBar extends StatelessWidget {
  final VoidCallback onToggleSidebar;
  final VoidCallback onOpenAddPatient;
  final VoidCallback onOpenAddAppointment;

  const AppTopBar({
    super.key,
    required this.onToggleSidebar,
    required this.onOpenAddPatient,
    required this.onOpenAddAppointment,
  });

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Waiting Room';
      case 2:
        return 'Patients Directory';
      case 3:
        return 'Appointments';
      case 4:
        return 'Doctor Availability';
      case 5:
        return 'Billing & Invoices';
      case 6:
        return 'Calls & Messages';
      case 7:
        return 'Call Reminders';
      case 8:
        return 'Reports & Statistics';
      case 9:
        return 'Clinic Settings';
      default:
        return 'Clinic Operations';
    }
  }

  void _showNotificationPanel(BuildContext context) {
    final clinic = context.clinic;
    final notifications = clinic.notifications;

    showDialog(
      context: context,
      barrierColor: Colors.black12,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned(
              top: 64,
              right: 20,
              width: 380,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 460),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Panel Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Notifications', style: AppTextStyles.h4),
                            TextButton(
                              onPressed: () {
                                clinic.markAllNotificationsAsRead();
                                Navigator.of(ctx).pop();
                              },
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              child: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                      // Notifications list
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: notifications.length,
                          separatorBuilder: (c, i) => const Divider(height: 1, color: AppColors.borderLight),
                          itemBuilder: (c, i) {
                            final n = notifications[i];
                            return ListTile(
                              dense: true,
                              tileColor: n.isRead ? Colors.transparent : AppColors.primaryLight.withValues(alpha: 0.3),
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: n.accentColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(n.icon, size: 16, color: n.accentColor),
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                n.message,
                                style: AppTextStyles.caption,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                DateFormat('hh:mm a').format(n.timestamp),
                                style: AppTextStyles.caption.copyWith(fontSize: 10),
                              ),
                              onTap: () {
                                clinic.markNotificationAsRead(n.id);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final unreadCount = clinic.unreadNotificationCount;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 980;
          final isNarrow = constraints.maxWidth < 750;

          return Row(
            children: [
              // Sidebar Toggle Button
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
                splashRadius: 20,
                tooltip: 'Toggle sidebar',
                onPressed: onToggleSidebar,
              ),
              const SizedBox(width: 8),

              // Title & Current Date (Flexible to prevent right overflow)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPageTitle(clinic.currentNavIndex),
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isNarrow ? 15 : 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isNarrow) ...[
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Global Search Field (Adapts to available space)
              if (!isNarrow) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isCompact ? 180 : 250),
                  child: SearchBarField(
                    hintText: isCompact ? 'Search...' : 'Search patients...',
                    onChanged: (q) => clinic.setSearchQuery(q),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Notification Bell with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                    splashRadius: 20,
                    tooltip: 'Operational Notifications',
                    onPressed: () => _showNotificationPanel(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),

              // Quick Actions (Icon buttons on narrow, full buttons on desktop)
              if (isCompact) ...[
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_outlined, color: AppColors.primary),
                  tooltip: 'Register Patient',
                  onPressed: onOpenAddPatient,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  tooltip: 'Book Visit',
                  onPressed: onOpenAddAppointment,
                ),
              ] else ...[
                AppButton.outline(
                  text: '+ Patient',
                  onPressed: onOpenAddPatient,
                  icon: Icons.person_add_alt_1_outlined,
                ),
                const SizedBox(width: 10),
                AppButton(
                  text: '+ Book Visit',
                  icon: Icons.add_circle_outline,
                  onPressed: onOpenAddAppointment,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
