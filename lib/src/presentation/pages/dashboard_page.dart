import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../application/providers/auth_controller.dart';
import '../../application/providers/dashboard_controller.dart';
import '../../application/providers/websites_controller.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/metric_report.dart';
import '../../domain/entities/session_stats.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/website.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({
    required this.session,
    super.key,
  });

  final AuthSession session;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _selectedWebsiteId;
  final _range = AnalyticsDateRange.last7Days();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final websites = ref.watch(websitesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(LucideIcons.activity),
            const SizedBox(width: 10),
            Text('Umami Analytics', style: theme.textTheme.h4),
          ],
        ),
        actions: [
          ShadButton.ghost(
            leading: const Icon(LucideIcons.logOut),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: websites.when(
        data: (items) => _DashboardContent(
          websites: items,
          selectedWebsiteId: _selectedWebsiteId,
          range: _range,
          onSelectWebsite: (websiteId) {
            setState(() {
              _selectedWebsiteId = websiteId;
            });
          },
        ),
        error: (error, stackTrace) => _CenteredError(
          title: 'Websites unavailable',
          message: _message(error),
          onRetry: () => ref.read(websitesControllerProvider.notifier).refresh(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.websites,
    required this.range,
    required this.onSelectWebsite,
    this.selectedWebsiteId,
  });

  final List<Website> websites;
  final String? selectedWebsiteId;
  final AnalyticsDateRange range;
  final ValueChanged<String> onSelectWebsite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (websites.isEmpty) {
      return _CenteredError(
        title: 'No websites found',
        message: 'This Umami account has no websites available.',
        onRetry: () => ref.read(websitesControllerProvider.notifier).refresh(),
      );
    }

    final activeWebsiteId = selectedWebsiteId ?? websites.first.id;
    final request = DashboardRequest(
      websiteId: activeWebsiteId,
      range: range,
    );
    final dashboard = ref.watch(dashboardControllerProvider(request));

    return RefreshIndicator(
      onRefresh: () {
        return ref.read(dashboardControllerProvider(request).notifier).refresh();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WebsiteSwitcher(
            websites: websites,
            selectedWebsiteId: activeWebsiteId,
            onSelectWebsite: onSelectWebsite,
          ),
          const SizedBox(height: 16),
          dashboard.when(
            data: (state) => _LoadedDashboard(data: state.data),
            error: (error, stackTrace) => _CenteredError(
              title: 'Dashboard unavailable',
              message: error is Failure ? error.message : error.toString(),
              onRetry: () {
                ref.read(dashboardControllerProvider(request).notifier).refresh();
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteSwitcher extends StatelessWidget {
  const _WebsiteSwitcher({
    required this.websites,
    required this.selectedWebsiteId,
    required this.onSelectWebsite,
  });

  final List<Website> websites;
  final String selectedWebsiteId;
  final ValueChanged<String> onSelectWebsite;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Websites', style: theme.textTheme.h4),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final website in websites)
                if (website.id == selectedWebsiteId)
                  ShadButton(
                    onPressed: () => onSelectWebsite(website.id),
                    child: Text(website.name),
                  )
                else
                  ShadButton.outline(
                    onPressed: () => onSelectWebsite(website.id),
                    child: Text(website.name),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadedDashboard extends StatelessWidget {
  const _LoadedDashboard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact();
    final percent = NumberFormat.percentPattern();
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(data.website.name, style: theme.textTheme.h2),
            ),
            ShadBadge.secondary(child: Text(data.website.domain)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 720 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth > 720 ? 1.8 : 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StatCard(
                  label: 'Visitors',
                  value: compact.format(data.stats.visitors),
                  icon: LucideIcons.users,
                ),
                _StatCard(
                  label: 'Pageviews',
                  value: compact.format(data.stats.pageviews),
                  icon: LucideIcons.eye,
                ),
                _StatCard(
                  label: 'Visits',
                  value: compact.format(data.stats.visits),
                  icon: LucideIcons.mousePointerClick,
                ),
                _StatCard(
                  label: 'Bounce',
                  value: percent.format(data.stats.bounceRate),
                  icon: LucideIcons.cornerDownLeft,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        ShadCard(
          title: const Text('Pageviews'),
          description: const Text('Last 7 days'),
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _MiniBarChart(points: data.pageviews),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth > 840;
            final children = [
              _MetricCard(title: 'Top pages', report: data.topPages),
              _MetricCard(title: 'Referrers', report: data.referrers),
              _MetricCard(title: 'Countries', report: data.countries),
              _SessionCard(stats: data.stats),
            ];

            if (!twoColumns) {
              return Column(
                children: children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: child,
                      ),
                    )
                    .toList(growable: false),
              );
            }

            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.75,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: children,
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: theme.textTheme.muted)),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(value, style: theme.textTheme.h1),
          ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.points});

  final List<TimeSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final maxValue = points.fold<int>(
      1,
      (max, point) => point.pageviews > max ? point.pageviews : max,
    );

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: point.pageviews / maxValue,
                          widthFactor: 0.82,
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.E().format(point.timestamp),
                      style: theme.textTheme.muted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.report,
  });

  final String title;
  final MetricReport report;

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: Text(title),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: _MetricRows(report: report),
      ),
    );
  }
}

class _MetricRows extends StatelessWidget {
  const _MetricRows({required this.report});

  final MetricReport report;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final compact = NumberFormat.compact();
    final max = report.rows.fold<int>(
      1,
      (value, row) => row.count > value ? row.count : value,
    );

    return Column(
      children: [
        for (final row in report.rows.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    row.value,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: row.count / max,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 52,
                  child: Text(
                    compact.format(row.count),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.muted,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.stats});

  final SessionStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final averageSeconds =
        stats.visits == 0 ? 0 : stats.totalTimeSeconds ~/ stats.visits;

    return ShadCard(
      title: const Text('Sessions'),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Average duration', style: theme.textTheme.muted),
            const SizedBox(height: 8),
            Text(_formatDuration(averageSeconds), style: theme.textTheme.h2),
            const Spacer(),
            Row(
              children: [
                const Icon(LucideIcons.timer, size: 18),
                const SizedBox(width: 8),
                Text('${stats.bounces} bounced visits'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ShadCard(
          title: Text(title),
          description: Text(message),
          footer: ShadButton.outline(
            leading: const Icon(LucideIcons.refreshCw),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
          child: const SizedBox(height: 12),
        ),
      ),
    );
  }
}
