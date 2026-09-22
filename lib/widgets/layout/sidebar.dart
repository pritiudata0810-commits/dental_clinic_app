import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../state/clinic_scope.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int index;
  final int? badgeCount;

  const SidebarItem({
    required this.title,
    required this.icon,
    required this.index,
    this.badgeCount,
  });
}

class AppSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const AppSidebar({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final clinic = context.clinic;
    final currentIndex = clinic.currentNavIndex;
    final waitingCount = clinic.waitingRoomCount;
    final pendingReminders = clinic.pendingRemindersCount;

    final navItems = [
      const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, index: 0),
      SidebarItem(
        title: 'Waiting Room',
        icon: Icons.airline_seat_recline_normal_outlined,
        index: 1,
        badgeCount: waitingCount > 0 ? waitingCount : null,
      ),
      const SidebarItem(title: 'Patients', icon: Icons.people_alt_outlined, index: 2),
      const SidebarItem(title: 'Appointments', icon: Icons.calendar_month_outlined, index: 3),
      const SidebarItem(title: 'Doctor Availability', icon: Icons.medical_services_outlined, index: 4),
      const SidebarItem(title: 'Billing & Invoices', icon: Icons.receipt_long_outlined, index: 5),
      SidebarItem(
        title: 'Call Reminders',
        icon: Icons.alarm_on_outlined,
        index: 6,
        badgeCount: pendingReminders > 0 ? pendingReminders : null,
      ),
      const SidebarItem(title: 'Reports & Statistics', icon: Icons.bar_chart_outlined, index: 7),
      const SidebarItem(title: 'Settings', icon: Icons.settings_outlined, index: 8),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 76 : 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Clinic Header / Brand
          Container(
            height: 70,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SmileCare OS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Reception & Clinic Ops',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nav Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: navItems.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == item.index;

                return _SidebarNavTile(
                  item: item,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  onTap: () => clinic.setNavIndex(item.index),
                );
              },
            ),
          ),

          // Bottom Receptionist Profile / Role Indicator & Logout
          Container(
            padding: EdgeInsets.all(isCollapsed ? 12 : 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Column(
              children: [
                if (!isCollapsed)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: const Text(
                          'SD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sunita Deshmukh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Head Receptionist',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      'SD',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    // Navigate back to Login
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 10),
                          const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatefulWidget {
  final SidebarItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarNavTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarNavTile> createState() => _SidebarNavTileState();
}

class _SidebarNavTileState extends State<_SidebarNavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppColors.primaryLight.withOpacity(0.8)
        : _isHovered
            ? AppColors.surfaceMuted
            : Colors.transparent;

    final fg = widget.isSelected ? AppColors.primaryDark : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 42,
          padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? Border.all(color: AppColors.primary.withOpacity(0.2), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                widget.item.icon,
                size: 20,
                color: fg,
              ),
              if (!widget.isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: widget.isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.item.badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.item.badgeCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
