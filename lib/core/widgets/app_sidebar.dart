import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
    this.superAdminOnly = false,
  });
  final IconData icon;
  final String label;
  final String route;
  final int? badge;
  final bool superAdminOnly;
}

class _NavSection {
  const _NavSection({required this.title, required this.items});
  final String title;
  final List<_NavItem> items;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentRoute,
    required this.isSuperAdmin,
    required this.userName,
    required this.userEmail,
    this.pendingApplications = 0,
    this.pendingReports = 0,
    this.pendingCourses = 0,
    required this.onLogout,
  });

  final String currentRoute;
  final bool isSuperAdmin;
  final String userName;
  final String userEmail;
  final int pendingApplications;
  final int pendingReports;
  final int pendingCourses;
  final VoidCallback onLogout;

  List<_NavSection> _sections(BuildContext ctx) => [
        _NavSection(title: 'Overview', items: [
          const _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            route: '/dashboard',
          ),
        ]),
        _NavSection(title: 'Platform', items: [
          _NavItem(
            icon: Icons.people_rounded,
            label: 'Users',
            route: '/users',
          ),
          _NavItem(
            icon: Icons.school_rounded,
            label: 'Courses',
            route: '/courses',
            badge: pendingCourses > 0 ? pendingCourses : null,
          ),
          const _NavItem(
            icon: Icons.category_rounded,
            label: 'Categories',
            route: '/categories',
          ),
          _NavItem(
            icon: Icons.assignment_ind_rounded,
            label: 'Applications',
            route: '/applications',
            badge: pendingApplications > 0 ? pendingApplications : null,
          ),
          const _NavItem(
            icon: Icons.notifications_rounded,
            label: 'Notifications',
            route: '/notifications',
          ),
        ]),
        _NavSection(title: 'Moderation', items: [
          _NavItem(
            icon: Icons.flag_rounded,
            label: 'Reports',
            route: '/reports',
            badge: pendingReports > 0 ? pendingReports : null,
          ),
          const _NavItem(
            icon: Icons.video_library_rounded,
            label: 'Video Management',
            route: '/video-processing',
          ),
        ]),
        _NavSection(title: 'Finance', items: [
          const _NavItem(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Payouts',
            route: '/payouts',
          ),
        ]),
        if (isSuperAdmin)
          _NavSection(title: 'Super Admin', items: [
            const _NavItem(
              icon: Icons.tune_rounded,
              label: 'System Settings',
              route: '/settings',
              superAdminOnly: true,
            ),
          ]),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          _SidebarHeader(isSuperAdmin: isSuperAdmin),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: _sections(context).map((section) {
                return _SidebarSection(
                  section: section,
                  currentRoute: currentRoute,
                );
              }).toList(),
            ),
          ),
          _SidebarFooter(
            userName: userName,
            userEmail: userEmail,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.isSuperAdmin});
  final bool isSuperAdmin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EduBridge',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                isSuperAdmin ? 'Super Admin' : 'Admin',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  const _SidebarSection({required this.section, required this.currentRoute});
  final _NavSection section;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
          child: Text(
            section.title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...section.items.map((item) => _SidebarTile(
              item: item,
              isActive: currentRoute == item.route ||
                  (currentRoute.startsWith(item.route) && item.route != '/dashboard'),
            )),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({required this.item, required this.isActive});
  final _NavItem item;
  final bool isActive;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  // ValueNotifier avoids calling setState during the mouse-tracker update phase,
  // which prevents the '!_debugDuringDeviceUpdate' assertion on Windows.
  final _hovered = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: GestureDetector(
        onTap: () => context.go(widget.item.route),
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primarySurface
                  : hovered
                      ? AppColors.surfaceVariant
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: 17,
                  color: active
                      ? AppColors.primaryLight
                      : hovered
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: active
                          ? AppColors.primaryLight
                          : hovered
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.item.badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.item.badge}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (widget.item.superAdminOnly)
                  const Icon(Icons.lock_rounded,
                      size: 11, color: AppColors.violet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatefulWidget {
  const _SidebarFooter({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  State<_SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<_SidebarFooter> {
  final _hovered = ValueNotifier<bool>(false);

  String get _initials {
    final parts = widget.userName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : '?';
  }

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(12),
      child: MouseRegion(
        onEnter: (_) => _hovered.value = true,
        onExit: (_) => _hovered.value = false,
        child: ValueListenableBuilder<bool>(
          valueListenable: _hovered,
          builder: (context, hovered, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: hovered ? AppColors.surfaceVariant : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.userEmail,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, size: 16),
                color: AppColors.textMuted,
                tooltip: 'Sign out',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),  // closes AnimatedContainer
        ),  // closes ValueListenableBuilder
      ),    // closes MouseRegion
    );
  }
}
