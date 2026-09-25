import 'package:flutter/material.dart';
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
      const SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded, index: 0),
      SidebarItem(
        title: 'Waiting Room',
        icon: Icons.airline_seat_recline_normal_rounded,
        index: 1,
        badgeCount: waitingCount > 0 ? waitingCount : null,
      ),
      const SidebarItem(title: 'Patients', icon: Icons.people_alt_rounded, index: 2),
      const SidebarItem(title: 'Appointments', icon: Icons.calendar_month_rounded, index: 3),
      const SidebarItem(title: 'Doctor Availability', icon: Icons.medical_services_rounded, index: 4),
      const SidebarItem(title: 'Billing & Invoices', icon: Icons.receipt_long_rounded, index: 5),
      SidebarItem(
        title: 'Call Reminders',
        icon: Icons.alarm_on_rounded,
        index: 6,
        badgeCount: pendingReminders > 0 ? pendingReminders : null,
      ),
      const SidebarItem(title: 'Reports & Statistics', icon: Icons.bar_chart_rounded, index: 7),
      const SidebarItem(title: 'Settings', icon: Icons.settings_rounded, index: 8),
    ];

    // Reference 2: Organic deep purple sidebar aesthetic
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 80 : 250,
      decoration: const BoxDecoration(
        color: Color(0xFF5856D6), // Reference 2 vibrant purple sidebar
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Clinic Header / Brand with Top Rounded Indicator
          Container(
            height: 74,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 18),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                // Reference 2: White pill for brand icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Color(0xFF5856D6),
                    size: 24,
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
                          'SmileCare',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'SmileCare OS • Clinic Ops',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFD6D5F7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Nav Items List (Reference 2 style: White active pills, clean hover)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: navItems.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == item.index;

                return _SidebarNavTile(
                  item: item,
                  isSelected: isSelected,
                  isCollapsed: isCollapsed,
                  onTap: () {
                    clinic.setNavIndex(item.index);
                    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),

          // Bottom Receptionist Profile / Role Indicator & Logout
          Container(
            padding: EdgeInsets.all(isCollapsed ? 12 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: Column(
              children: [
                if (!isCollapsed)
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'SD',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5856D6),
                            ),
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
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Reception Station',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFFD6D5F7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'SD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5856D6),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Sign Out',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
    // Reference 2: Active items are clean white pills on purple background
    final bg = widget.isSelected
        ? Colors.white
        : _isHovered
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent;

    final fg = widget.isSelected
        ? const Color(0xFF5856D6)
        : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: widget.isCollapsed ? 0 : 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
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
                      fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: fg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.item.badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: widget.isSelected ? const Color(0xFF5856D6) : const Color(0xFFF59E0B),
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
