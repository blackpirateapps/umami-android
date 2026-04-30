part of '../dashboard_page.dart';

enum _DashboardDestination {
  dashboard,
  sessions,
  settings,
}

extension _DashboardDestinationDetails on _DashboardDestination {
  String get label {
    return switch (this) {
      _DashboardDestination.dashboard => 'Dashboard',
      _DashboardDestination.sessions => 'Sessions',
      _DashboardDestination.settings => 'Settings',
    };
  }

  IconData get icon {
    return switch (this) {
      _DashboardDestination.dashboard => LucideIcons.activity,
      _DashboardDestination.sessions => LucideIcons.user,
      _DashboardDestination.settings => LucideIcons.settings,
    };
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.session,
    required this.selected,
    required this.onSelected,
    required this.onSignOut,
  });

  final AuthSession session;
  final _DashboardDestination selected;
  final ValueChanged<_DashboardDestination> onSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Drawer(
      backgroundColor: theme.colorScheme.background,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.activity, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Umami Analytics',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.large.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                session.username,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 22),
              for (final destination in _DashboardDestination.values) ...[
                _NavigationButton(
                  icon: destination.icon,
                  label: destination.label,
                  selected: destination == selected,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSelected(destination);
                  },
                ),
                const SizedBox(height: 6),
              ],
              const Spacer(),
              _NavigationButton(
                icon: LucideIcons.logOut,
                label: 'Sign out',
                destructive: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onSignOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = destructive
        ? theme.colorScheme.destructive
        : theme.colorScheme.foreground;
    return Material(
      color: selected ? theme.colorScheme.muted : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
