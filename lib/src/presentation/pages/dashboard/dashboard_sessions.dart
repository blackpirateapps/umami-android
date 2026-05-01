part of '../dashboard_page.dart';

enum _SessionsTab {
  activity,
  properties,
}

class _SessionsActivityPanel extends StatelessWidget {
  const _SessionsActivityPanel({
    required this.state,
    required this.activeTab,
    required this.searchController,
    required this.onTabChanged,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onFilter,
  });

  final AsyncValue<SessionReport> state;
  final _SessionsTab activeTab;
  final TextEditingController searchController;
  final ValueChanged<_SessionsTab> onTabChanged;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final void Function(MetricType type, String value) onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return _DashboardPanel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Row(
              children: [
                _SessionsTabButton(
                  label: 'Activity',
                  selected: activeTab == _SessionsTab.activity,
                  onPressed: () => onTabChanged(_SessionsTab.activity),
                ),
                const SizedBox(width: 24),
                _SessionsTabButton(
                  label: 'Properties',
                  selected: activeTab == _SessionsTab.properties,
                  onPressed: () => onTabChanged(_SessionsTab.properties),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Refresh',
                  child: ShadIconButton.ghost(
                    icon: const Icon(LucideIcons.activity),
                    onPressed: () => unawaited(onRefresh()),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.border),
          if (activeTab == _SessionsTab.activity) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: ShadInput(
                  controller: searchController,
                  placeholder: const Text('Search'),
                  leading: const Icon(LucideIcons.search),
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            state.when(
              data: (report) => _SessionsTable(
                report: report,
                onLoadMore: onLoadMore,
                onFilter: onFilter,
              ),
              error: (error, stackTrace) => _SessionsInlineMessage(
                icon: LucideIcons.circleAlert,
                title: 'Sessions unavailable',
                message: _message(error),
                actionLabel: 'Retry',
                onAction: onRefresh,
              ),
              loading: () => const _SessionsTableSkeleton(),
            ),
          ] else
            _SessionsInlineMessage(
              icon: LucideIcons.tableProperties,
              title: 'No properties',
              message: 'No session properties were found for this range.',
              actionLabel: 'Refresh',
              onAction: onRefresh,
            ),
        ],
      ),
    );
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
  }
}

class _SessionsTabButton extends StatelessWidget {
  const _SessionsTabButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? theme.colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: theme.textTheme.p.copyWith(
                color: selected
                    ? theme.colorScheme.foreground
                    : theme.colorScheme.mutedForeground,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({
    required this.report,
    required this.onLoadMore,
    required this.onFilter,
  });

  final SessionReport report;
  final Future<void> Function() onLoadMore;
  final void Function(MetricType type, String value) onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (report.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Text('No sessions', style: theme.textTheme.muted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1180),
            child: Column(
              children: [
                const _SessionsHeaderRow(),
                for (final session in report.rows)
                  _SessionsDataRow(
                    session: session,
                    onFilter: onFilter,
                  ),
              ],
            ),
          ),
        ),
        if (report.hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Center(
              child: ShadButton.outline(
                onPressed: () => unawaited(onLoadMore()),
                child: const Text('Load More'),
              ),
            ),
          )
        else
          const SizedBox(height: 18),
      ],
    );
  }
}

class _SessionsHeaderRow extends StatelessWidget {
  const _SessionsHeaderRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 40,
      child: Row(
        children: [
          _SessionsHeaderCell(width: 104, label: 'Session'),
          _SessionsHeaderCell(width: 78, label: 'Visits'),
          _SessionsHeaderCell(width: 78, label: 'Views'),
          _SessionsHeaderCell(width: 84, label: 'Events'),
          _SessionsHeaderCell(width: 280, label: 'Location'),
          _SessionsHeaderCell(width: 170, label: 'Browser'),
          _SessionsHeaderCell(width: 170, label: 'OS'),
          _SessionsHeaderCell(width: 150, label: 'Device'),
          _SessionsHeaderCell(width: 180, label: 'Last seen'),
        ],
      ),
    );
  }
}

class _SessionsDataRow extends StatelessWidget {
  const _SessionsDataRow({
    required this.session,
    required this.onFilter,
  });

  final WebsiteSession session;
  final void Function(MetricType type, String value) onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            SizedBox(
              width: 104,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SessionAvatar(id: session.id),
              ),
            ),
            _SessionsTextCell(width: 78, text: '${session.visits}'),
            _SessionsTextCell(width: 78, text: '${session.views}'),
            _SessionsTextCell(width: 84, text: '${session.events}'),
            _SessionsLocationCell(
              session: session,
              onTap: session.country.isEmpty
                  ? null
                  : () => onFilter(MetricType.country, session.country),
            ),
            _SessionsIconTextCell(
              width: 170,
              icon: LucideIcons.globe,
              text: _browserLabel(session.browser),
              onTap: session.browser.isEmpty
                  ? null
                  : () => onFilter(MetricType.browser, session.browser),
            ),
            _SessionsIconTextCell(
              width: 170,
              icon: LucideIcons.monitor,
              text: _titleLabel(session.os),
            ),
            _SessionsIconTextCell(
              width: 150,
              icon: _deviceIcon(session.device),
              text: _deviceLabel(session.device),
            ),
            _SessionsTextCell(
              width: 180,
              text: _relativeTime(session.lastAt ?? session.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsHeaderCell extends StatelessWidget {
  const _SessionsHeaderCell({
    required this.width,
    required this.label,
  });

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SessionsTextCell extends StatelessWidget {
  const _SessionsTextCell({
    required this.width,
    required this.text,
  });

  final double width;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.p,
      ),
    );
  }
}

class _SessionsIconTextCell extends StatelessWidget {
  const _SessionsIconTextCell({
    required this.width,
    required this.icon,
    required this.text,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final child = SizedBox(
      width: width,
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.p,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _SessionsLocationCell extends StatelessWidget {
  const _SessionsLocationCell({
    required this.session,
    required this.onTap,
  });

  final WebsiteSession session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final city = session.city.trim();
    final country = _countryName(session.country);
    final label = [
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ].join(', ');
    final child = SizedBox(
      width: 280,
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(_countryFlag(session.country))),
          Expanded(
            child: Text(
              label.isEmpty ? 'Unknown' : label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.p,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _SessionAvatar extends StatelessWidget {
  const _SessionAvatar({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final hash = id.codeUnits.fold<int>(0, (value, unit) => value + unit);
    final color = _avatarColors[hash % _avatarColors.length];
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withValues(alpha: 0.28),
      child: Icon(
        LucideIcons.user,
        size: 18,
        color: color,
      ),
    );
  }
}

class _SessionsInlineMessage extends StatelessWidget {
  const _SessionsInlineMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 32),
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.mutedForeground),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.large),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
            onPressed: () => unawaited(onAction()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SessionsTableSkeleton extends StatelessWidget {
  const _SessionsTableSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          _SkeletonBox(width: double.infinity, height: 42),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 54),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 54),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 54),
          SizedBox(height: 8),
          _SkeletonBox(width: double.infinity, height: 54),
        ],
      ),
    );
  }
}

const _avatarColors = [
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFDB2777),
  Color(0xFFEA580C),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
];

String _browserLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    '' => 'Unknown',
    'chrome' => 'Chrome',
    'firefox' => 'Firefox',
    'safari' => 'Safari',
    'edge' => 'Edge',
    'edge-chromium' => 'Edge (Chromium)',
    'ios-webview' => 'iOS (webview)',
    _ => _titleLabel(value),
  };
}

String _deviceLabel(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    '' => 'Unknown',
    'desktop' => 'Laptop',
    'mobile' => 'Mobile',
    'tablet' => 'Tablet',
    _ => _titleLabel(value),
  };
}

IconData _deviceIcon(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'mobile' => LucideIcons.smartphone,
    'tablet' => LucideIcons.tablet,
    _ => LucideIcons.laptop,
  };
}

String _titleLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'Unknown';
  }
  return trimmed
      .replaceAll(RegExp('[-_]'), ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) {
    final lower = part.toLowerCase();
    return switch (lower) {
      'ios' => 'iOS',
      'os' => 'OS',
      'macos' => 'macOS',
      _ => '${part[0].toUpperCase()}${part.substring(1)}',
    };
  }).join(' ');
}

String _countryName(String code) {
  final normalized = code.trim().toUpperCase();
  return _countryNames[normalized] ?? normalized;
}

String _countryFlag(String code) {
  final normalized = code.trim().toUpperCase();
  if (normalized.length != 2 ||
      normalized.codeUnits.any((unit) => unit < 65 || unit > 90)) {
    return '';
  }
  return String.fromCharCodes(
    normalized.codeUnits.map((unit) => 0x1F1E6 + unit - 65),
  );
}

String _relativeTime(DateTime? value) {
  if (value == null) {
    return 'Unknown';
  }

  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} minutes ago';
  }
  if (diff.inDays < 1) {
    return 'about ${diff.inHours} hours ago';
  }
  if (diff.inDays < 30) {
    return '${diff.inDays} days ago';
  }
  final months = diff.inDays ~/ 30;
  if (months < 12) {
    return '$months months ago';
  }
  final years = diff.inDays ~/ 365;
  return '$years years ago';
}

const _countryNames = {
  'AT': 'Austria',
  'AU': 'Australia',
  'BR': 'Brazil',
  'CA': 'Canada',
  'CH': 'Switzerland',
  'CN': 'China',
  'DE': 'Germany',
  'ES': 'Spain',
  'FR': 'France',
  'GB': 'United Kingdom',
  'HK': 'Hong Kong',
  'HU': 'Hungary',
  'ID': 'Indonesia',
  'IE': 'Ireland',
  'IN': 'India',
  'IT': 'Italy',
  'JP': 'Japan',
  'KR': 'South Korea',
  'MX': 'Mexico',
  'MY': 'Malaysia',
  'NL': 'Netherlands',
  'NZ': 'New Zealand',
  'PH': 'Philippines',
  'PL': 'Poland',
  'SE': 'Sweden',
  'SG': 'Singapore',
  'TH': 'Thailand',
  'TR': 'Turkey',
  'UA': 'Ukraine',
  'US': 'United States',
  'VN': 'Vietnam',
  'ZA': 'South Africa',
};
