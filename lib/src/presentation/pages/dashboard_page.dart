import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../application/providers/auth_controller.dart';
import '../../application/providers/dashboard_controller.dart';
import '../../application/providers/metric_page_controller.dart';
import '../../application/providers/websites_controller.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/analytics_date_range_preset.dart';
import '../../domain/entities/analytics_query.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/country_traffic.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/metric_report.dart';
import '../../domain/entities/session_stats.dart';
import '../../domain/entities/time_series_point.dart';
import '../../domain/entities/website.dart';

const _zinc50 = Color(0xFFFAFAFA);
const _zinc900 = Color(0xFF18181B);
const _zinc950 = Color(0xFF09090B);

String _formatDurationLabel(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m ${remainingSeconds}s';
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.session,
    super.key,
  });

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return Theme(
      data: UmamiDashboard.zincThemeData(brightness),
      child: UmamiDashboard(session: session),
    );
  }
}

class UmamiDashboard extends ConsumerStatefulWidget {
  const UmamiDashboard({
    required this.session,
    super.key,
  });

  final AuthSession session;

  static ThemeData zincThemeData(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: _zinc900,
      scaffoldBackgroundColor: dark ? _zinc950 : _zinc50,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? _zinc950 : _zinc50,
        foregroundColor: dark ? _zinc50 : _zinc950,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  @override
  ConsumerState<UmamiDashboard> createState() => _UmamiDashboardState();
}

class _UmamiDashboardState extends ConsumerState<UmamiDashboard> {
  String? _selectedWebsiteId;
  var _rangeSelection = const AnalyticsDateRangeSelection.preset(
    AnalyticsDateRangePreset.last7Days,
  );
  var _destination = _DashboardDestination.dashboard;

  AnalyticsDateRange _activeRange(Website website) {
    return _rangeSelection.resolve(allTimeStartAt: website.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final websites = ref.watch(websitesControllerProvider);

    return Scaffold(
      drawer: _NavigationDrawer(
        session: widget.session,
        selected: _destination,
        onSelected: (destination) {
          setState(() {
            _destination = destination;
          });
        },
        onSignOut: () {
          ref.read(authControllerProvider.notifier).signOut();
        },
      ),
      body: websites.when(
        data: _buildDashboardWithWebsites,
        error: (error, stackTrace) => _buildShell(
          slivers: [
            _buildHeaderShell(title: 'Umami Analytics'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: _DashboardMessage(
                icon: LucideIcons.circleAlert,
                title: 'Websites unavailable',
                message: _message(error),
                actionLabel: 'Retry',
                onAction: () {
                  ref.read(websitesControllerProvider.notifier).refresh();
                },
              ),
            ),
          ],
        ),
        loading: _buildLoadingDashboard,
      ),
    );
  }

  Widget _buildDashboardWithWebsites(List<Website> websites) {
    if (_destination == _DashboardDestination.settings) {
      return _buildShell(
        slivers: [
          _buildHeaderShell(title: 'Settings'),
          _buildSettingsSlivers(),
        ],
      );
    }

    if (websites.isEmpty) {
      return _buildShell(
        slivers: [
          _buildHeaderShell(title: 'Umami Analytics'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _DashboardMessage(
              icon: LucideIcons.chartNoAxesColumn,
              title: 'No websites connected',
              message: 'Connect a website to start reading analytics.',
              actionLabel: 'Add Website',
              onAction: () {},
            ),
          ),
        ],
      );
    }

    final activeWebsiteId = _selectedWebsiteId ?? websites.first.id;
    final activeWebsite = websites.firstWhere(
      (website) => website.id == activeWebsiteId,
      orElse: () => websites.first,
    );
    final activeRange = _activeRange(activeWebsite);
    final request = DashboardRequest(
      websiteId: activeWebsite.id,
      range: activeRange,
    );
    final dashboard = ref.watch(dashboardControllerProvider(request));

    return RefreshIndicator(
      onRefresh: () {
        return ref.read(dashboardControllerProvider(request).notifier).refresh();
      },
      child: _buildShell(
        slivers: [
          _buildHeader(
            websites: websites,
            activeWebsite: activeWebsite,
          ),
          ...dashboard.when(
            data: (state) {
              return switch (_destination) {
                _DashboardDestination.dashboard => [
                    _buildMetricGrid(state.data),
                    _buildMainChart(state.data, activeRange),
                    _buildDataList(
                      data: state.data,
                      activeWebsite: activeWebsite,
                      activeRange: activeRange,
                    ),
                  ],
                _DashboardDestination.sessions => _buildSessionsSlivers(
                    data: state.data,
                    activeRange: activeRange,
                  ),
                _DashboardDestination.settings => [_buildSettingsSlivers()],
              };
            },
            error: (error, stackTrace) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _DashboardMessage(
                  icon: LucideIcons.circleAlert,
                  title: 'Dashboard unavailable',
                  message: _message(error),
                  actionLabel: 'Retry',
                  onAction: () {
                    ref
                        .read(dashboardControllerProvider(request).notifier)
                        .refresh();
                  },
                ),
              ),
            ],
            loading: () => [
              _buildMetricSkeletonGrid(),
              _buildChartSkeleton(),
              _buildListSkeleton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDashboard() {
    return _buildShell(
      slivers: [
        _buildLoadingHeader(),
        _buildMetricSkeletonGrid(),
        _buildChartSkeleton(),
        _buildListSkeleton(),
      ],
    );
  }

  Widget _buildShell({required List<Widget> slivers}) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: slivers,
    );
  }

  Widget _buildHeader({
    required List<Website> websites,
    required Website activeWebsite,
  }) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      toolbarHeight: 72,
      titleSpacing: 16,
      leading: Builder(
        builder: (context) {
          return Tooltip(
            message: 'Navigation',
            child: ShadIconButton.ghost(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          );
        },
      ),
      title: _WebsiteSelect(
        websites: websites,
        activeWebsite: activeWebsite,
        onChanged: (websiteId) {
          setState(() {
            _selectedWebsiteId = websiteId;
          });
        },
      ),
      actions: [
        ShadButton.outline(
          leading: const Icon(LucideIcons.calendarClock, size: 16),
          onPressed: () => _showDateRangeSheet(activeWebsite),
          child: Text(_rangeButtonLabel()),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildHeaderShell({required String title}) {
    final theme = ShadTheme.of(context);
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      toolbarHeight: 72,
      titleSpacing: 16,
      leading: Builder(
        builder: (context) {
          return Tooltip(
            message: 'Navigation',
            child: ShadIconButton.ghost(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          );
        },
      ),
      title: Text(title, style: theme.textTheme.h4),
    );
  }

  Widget _buildLoadingHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      toolbarHeight: 72,
      titleSpacing: 16,
      leading: Builder(
        builder: (context) {
          return Tooltip(
            message: 'Navigation',
            child: ShadIconButton.ghost(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          );
        },
      ),
      title: const _SkeletonBox(width: 180, height: 40),
      actions: const [
        _SkeletonBox(width: 72, height: 40),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMetricGrid(DashboardData data) {
    final compact = NumberFormat.compact();
    final percent = NumberFormat.percentPattern();
    final averageSeconds = _averageVisitSeconds(data.stats);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.28,
        ),
        delegate: SliverChildListDelegate.fixed([
          _MetricCard(
            label: 'Views',
            value: compact.format(data.stats.pageviews),
            icon: LucideIcons.chartNoAxesColumn,
          ),
          _MetricCard(
            label: 'Visitors',
            value: compact.format(data.stats.visitors),
            icon: LucideIcons.user,
          ),
          _MetricCard(
            label: 'Bounce Rate',
            value: percent.format(data.stats.bounceRate),
            icon: LucideIcons.activity,
          ),
          _MetricCard(
            label: 'Avg. Visit Time',
            value: _formatDuration(averageSeconds),
            icon: LucideIcons.calendarClock,
          ),
        ]),
      ),
    );
  }

  Widget _buildMainChart(DashboardData data, AnalyticsDateRange activeRange) {
    final theme = ShadTheme.of(context);
    final total = NumberFormat.compact().format(data.stats.pageviews);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: _DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Views',
                          style: theme.textTheme.large.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rangeSubtitle(activeRange),
                          style: theme.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                  ShadBadge.secondary(child: Text(total)),
                ],
              ),
              const SizedBox(height: 18),
              AspectRatio(
                aspectRatio: 1.75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.muted.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.border),
                  ),
                  child: CustomPaint(
                    painter: _LineChartPainter(
                      points: data.pageviews,
                      lineColor: theme.colorScheme.primary,
                      gridColor: theme.colorScheme.border,
                      fillColor:
                          theme.colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataList({
    required DashboardData data,
    required Website activeWebsite,
    required AnalyticsDateRange activeRange,
  }) {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _BreakdownSection(
            title: 'Top Pages',
            report: data.topPages,
            onViewAll: () => _openMetricDetail(
              title: 'Top Pages',
              type: MetricType.path,
              website: activeWebsite,
              range: activeRange,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _BreakdownSection(
            title: 'Top Referrers',
            report: data.referrers,
            emptyLabel: 'Direct',
            onViewAll: () => _openMetricDetail(
              title: 'Top Referrers',
              type: MetricType.referrer,
              website: activeWebsite,
              range: activeRange,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _EnvironmentSection(
            browsers: data.browsers,
            operatingSystems: data.operatingSystems,
            devices: data.devices,
            onViewAll: (title, type) => _openMetricDetail(
              title: title,
              type: type,
              website: activeWebsite,
              range: activeRange,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: _LocationSection(
            countries: data.countries,
            onViewAll: () => _openMetricDetail(
              title: 'Countries',
              type: MetricType.country,
              website: activeWebsite,
              range: activeRange,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildMetricSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.28,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const _MetricSkeletonCard(),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildChartSkeleton() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: _DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _SkeletonBox(width: 128, height: 20),
              SizedBox(height: 8),
              _SkeletonBox(width: 180, height: 14),
              SizedBox(height: 18),
              AspectRatio(
                aspectRatio: 1.75,
                child: _SkeletonBox(width: double.infinity, height: 220),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        for (var section = 0; section < 4; section++)
          Padding(
            padding: EdgeInsets.fromLTRB(16, section == 0 ? 4 : 0, 16, 12),
            child: _DashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SkeletonBox(width: 112, height: 18),
                  SizedBox(height: 18),
                  _SkeletonBox(width: double.infinity, height: 38),
                  SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 38),
                  SizedBox(height: 10),
                  _SkeletonBox(width: double.infinity, height: 38),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ]),
    );
  }

  List<Widget> _buildSessionsSlivers({
    required DashboardData data,
    required AnalyticsDateRange activeRange,
  }) {
    final compact = NumberFormat.compact();
    final percent = NumberFormat.percentPattern();
    final theme = ShadTheme.of(context);
    final averageSeconds = _averageVisitSeconds(data.stats);

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.22,
          ),
          delegate: SliverChildListDelegate.fixed([
            _SessionMetricCard(
              label: 'Visits',
              value: compact.format(data.stats.visits),
            ),
            _SessionMetricCard(
              label: 'Visitors',
              value: compact.format(data.stats.visitors),
            ),
            _SessionMetricCard(
              label: 'Avg. Duration',
              value: _formatDuration(averageSeconds),
            ),
            _SessionMetricCard(
              label: 'Bounce Rate',
              value: percent.format(data.stats.bounceRate),
            ),
          ]),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _SessionTotalsPanel(
            stats: data.stats,
            rangeLabel: _rangeSubtitle(activeRange),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: _DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeading(
                  title: 'Pageviews Over Time',
                  trailing: ShadBadge.secondary(
                    child: Text(compact.format(data.stats.pageviews)),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_rangeSubtitle(activeRange), style: theme.textTheme.muted),
                const SizedBox(height: 18),
                AspectRatio(
                  aspectRatio: 1.75,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.muted.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.border,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        points: data.pageviews,
                        lineColor: theme.colorScheme.primary,
                        gridColor: theme.colorScheme.border,
                        fillColor:
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildSettingsSlivers() {
    final theme = ShadTheme.of(context);
    final signedInAt =
        DateFormat.yMMMd().add_jm().format(widget.session.createdAt);

    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: _DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Account',
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsRow(label: 'Username', value: widget.session.username),
                const SizedBox(height: 12),
                _SettingsRow(label: 'Endpoint', value: widget.session.baseUrl),
                const SizedBox(height: 12),
                _SettingsRow(label: 'Signed in', value: signedInAt),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: _DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Session',
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsRow(
                  label: 'Token refresh',
                  value: widget.session.canRefreshWithoutPrompt
                      ? 'Available'
                      : 'Manual sign-in',
                ),
                const SizedBox(height: 18),
                ShadButton.destructive(
                  leading: const Icon(LucideIcons.logOut),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _openMetricDetail({
    required String title,
    required MetricType type,
    required Website website,
    required AnalyticsDateRange range,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return _MetricDetailPage(
            title: title,
            type: type,
            website: website,
            range: range,
          );
        },
      ),
    );
  }

  Future<void> _showDateRangeSheet(Website activeWebsite) async {
    final theme = ShadTheme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Date Range', style: theme.textTheme.h4),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final preset in AnalyticsDateRangePreset.values)
                          _DateRangePresetButton(
                            preset: preset,
                            selected: _rangeSelection.preset == preset,
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (preset == AnalyticsDateRangePreset.custom) {
                                unawaited(_pickCustomRange(activeWebsite));
                                return;
                              }
                              setState(() {
                                _rangeSelection =
                                    AnalyticsDateRangeSelection.preset(preset);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickCustomRange(Website activeWebsite) async {
    final activeRange = _activeRange(activeWebsite);
    final now = DateTime.now();
    final defaultFirstDate = DateTime(2000);
    final createdAt = activeWebsite.createdAt;
    final firstDate = createdAt != null && createdAt.isBefore(defaultFirstDate)
        ? DateTime(createdAt.year, createdAt.month, createdAt.day)
        : defaultFirstDate;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: activeRange.startAt,
        end: activeRange.endAt,
      ),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _rangeSelection = AnalyticsDateRangeSelection.custom(
        startAt: picked.start,
        endAt: picked.end,
      );
    });
  }

  String _rangeButtonLabel() {
    return switch (_rangeSelection.preset) {
      AnalyticsDateRangePreset.last24Hours => '24h',
      AnalyticsDateRangePreset.thisWeek => 'Week',
      AnalyticsDateRangePreset.last7Days => '7d',
      AnalyticsDateRangePreset.thisMonth => 'Month',
      AnalyticsDateRangePreset.last30Days => '30d',
      AnalyticsDateRangePreset.last60Days => '60d',
      AnalyticsDateRangePreset.last90Days => '90d',
      AnalyticsDateRangePreset.thisYear => 'Year',
      AnalyticsDateRangePreset.last6Months => '6mo',
      AnalyticsDateRangePreset.last12Months => '12mo',
      AnalyticsDateRangePreset.allTime => 'All',
      AnalyticsDateRangePreset.custom => 'Custom',
    };
  }

  String _rangeSubtitle(AnalyticsDateRange range) {
    final sameYear = range.startAt.year == range.endAt.year;
    final formatter = sameYear ? DateFormat.MMMd() : DateFormat.yMMMd();
    return '${formatter.format(range.startAt)} - ${formatter.format(range.endAt)}';
  }

  int _averageVisitSeconds(SessionStats stats) {
    return stats.visits == 0 ? 0 : stats.totalTimeSeconds ~/ stats.visits;
  }

  String _formatDuration(int seconds) {
    return _formatDurationLabel(seconds);
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
  }
}

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

class _DateRangePresetButton extends StatelessWidget {
  const _DateRangePresetButton({
    required this.preset,
    required this.selected,
    required this.onPressed,
  });

  final AnalyticsDateRangePreset preset;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? theme.colorScheme.muted : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    preset.label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: theme.textTheme.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _WebsiteSelect extends StatelessWidget {
  const _WebsiteSelect({
    required this.websites,
    required this.activeWebsite,
    required this.onChanged,
  });

  final List<Website> websites;
  final Website activeWebsite;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: ShadSelect<String>(
        minWidth: 150,
        placeholder: _WebsiteSelectLabel(name: activeWebsite.name),
        options: websites
            .map(
              (website) => ShadOption(
                value: website.id,
                child: Text(website.name),
              ),
            )
            .toList(growable: false),
        selectedOptionBuilder: (context, value) {
          final selected = websites.firstWhere(
            (website) => website.id == value,
            orElse: () => activeWebsite,
          );
          return _WebsiteSelectLabel(name: selected.name);
        },
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _WebsiteSelectLabel extends StatelessWidget {
  const _WebsiteSelectLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(LucideIcons.chevronDown, size: 16),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

    return _DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
              ),
              Icon(
                icon,
                color: theme.colorScheme.mutedForeground,
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.h2.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionMetricCard extends StatelessWidget {
  const _SessionMetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return _DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.muted,
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTotalsPanel extends StatelessWidget {
  const _SessionTotalsPanel({
    required this.stats,
    required this.rangeLabel,
  });

  final SessionStats stats;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final compact = NumberFormat.compact();
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(title: 'Session Summary'),
          const SizedBox(height: 4),
          Text(
            rangeLabel,
            overflow: TextOverflow.ellipsis,
            style: ShadTheme.of(context).textTheme.muted,
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Pageviews', value: compact.format(stats.pageviews)),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Bounces', value: compact.format(stats.bounces)),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Total Time',
            value: _formatDurationLabel(stats.totalTimeSeconds),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.muted,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.large.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _EnvironmentSection extends StatelessWidget {
  const _EnvironmentSection({
    required this.browsers,
    required this.operatingSystems,
    required this.devices,
    required this.onViewAll,
  });

  final MetricReport browsers;
  final MetricReport operatingSystems;
  final MetricReport devices;
  final void Function(String title, MetricType type) onViewAll;

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeading(title: 'Environment'),
          const SizedBox(height: 14),
          _MetricPreviewBlock(
            title: 'Browsers',
            report: browsers,
            onViewAll: () => onViewAll('Browsers', MetricType.browser),
          ),
          const SizedBox(height: 18),
          _MetricPreviewBlock(
            title: 'Operating Systems',
            report: operatingSystems,
            onViewAll: () => onViewAll('Operating Systems', MetricType.os),
          ),
          const SizedBox(height: 18),
          _MetricPreviewBlock(
            title: 'Devices',
            report: devices,
            onViewAll: () => onViewAll('Devices', MetricType.device),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.countries,
    required this.onViewAll,
  });

  final MetricReport countries;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final rows = countries.rows
        .where((row) => CountryTrafficScale.normalizeIso2(row.value) != null)
        .take(5)
        .toList(growable: false);
    final max = rows.fold<int>(
      1,
      (value, row) => row.count > value ? row.count : value,
    );

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            title: 'Location',
            trailing: ShadButton.ghost(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: 14),
          _CountryTrafficMap(rows: countries.rows),
          const SizedBox(height: 14),
          Text(
            'Top Countries',
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Text('No data', style: theme.textTheme.muted)
          else
            for (final row in rows) ...[
              _TrafficRow(
                row: row,
                max: max,
              ),
              if (row != rows.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _CountryTrafficMap extends StatelessWidget {
  const _CountryTrafficMap({required this.rows});

  final List<MetricRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final points = CountryTrafficScale.fromRows(rows).take(24).toList();

    return AspectRatio(
      aspectRatio: 2.1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.muted.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: points.isEmpty
            ? Center(child: Text('No country data', style: theme.textTheme.muted))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      (constraints.maxWidth / 52).floor().clamp(3, 6).toInt();
                  final visiblePoints =
                      points.take(columns * 3).toList(growable: false);
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visiblePoints.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      return _CountryTrafficTile(point: visiblePoints[index]);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _CountryTrafficTile extends StatelessWidget {
  const _CountryTrafficTile({required this.point});

  final CountryTrafficPoint point;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = Color.lerp(
      theme.colorScheme.muted,
      theme.colorScheme.primary,
      point.intensity,
    )!;
    final textColor = point.intensity > 0.58
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.foreground;
    return Tooltip(
      message: '${point.iso2} ${NumberFormat.compact().format(point.count)}',
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Text(
          point.iso2,
          style: theme.textTheme.small.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MetricPreviewBlock extends StatelessWidget {
  const _MetricPreviewBlock({
    required this.title,
    required this.report,
    required this.onViewAll,
  });

  final String title;
  final MetricReport report;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final rows = report.rows.take(3).toList(growable: false);
    final max = rows.fold<int>(
      1,
      (value, row) => row.count > value ? row.count : value,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ShadButton.ghost(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Text('No data', style: theme.textTheme.muted)
        else
          for (final row in rows) ...[
            _TrafficRow(
              row: row,
              max: max,
            ),
            if (row != rows.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _MetricDetailPage extends ConsumerStatefulWidget {
  const _MetricDetailPage({
    required this.title,
    required this.type,
    required this.website,
    required this.range,
  });

  final String title;
  final MetricType type;
  final Website website;
  final AnalyticsDateRange range;

  @override
  ConsumerState<_MetricDetailPage> createState() => _MetricDetailPageState();
}

class _MetricDetailPageState extends ConsumerState<_MetricDetailPage> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;

  MetricQuery get _query {
    return MetricQuery(
      websiteId: widget.website.id,
      range: widget.range,
      type: widget.type,
      limit: 50,
    );
  }

  String get _emptyLabel {
    return widget.type == MetricType.referrer ? 'Direct' : 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadNextPage);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_maybeLoadNextPage)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metricPageControllerProvider(_query));
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.large),
            Text(
              widget.website.name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.muted,
            ),
          ],
        ),
        actions: [
          Tooltip(
            message: 'Refresh',
            child: ShadIconButton.ghost(
              icon: const Icon(LucideIcons.activity),
              onPressed: () {
                ref.read(metricPageControllerProvider(_query).notifier).refresh();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.when(
        data: _buildRows,
        error: (error, stackTrace) => _DashboardMessage(
          icon: LucideIcons.circleAlert,
          title: '${widget.title} unavailable',
          message: _message(error),
          actionLabel: 'Retry',
          onAction: () {
            ref.read(metricPageControllerProvider(_query).notifier).refresh();
          },
        ),
        loading: _buildLoadingRows,
      ),
    );
  }

  Widget _buildRows(MetricReport report) {
    final rows = report.rows;
    if (rows.isEmpty) {
      return _DashboardMessage(
        icon: LucideIcons.chartNoAxesColumn,
        title: 'No data',
        message: 'No rows are available for this range.',
        actionLabel: 'Refresh',
        onAction: () {
          ref.read(metricPageControllerProvider(_query).notifier).refresh();
        },
      );
    }

    final max = rows.fold<int>(
      1,
      (value, row) => row.count > value ? row.count : value,
    );

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: rows.length + 1,
      itemBuilder: (context, index) {
        if (index == rows.length) {
          if (!report.hasMore) {
            return const SizedBox(height: 8);
          }
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: _loadingMore
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : ShadButton.outline(
                      onPressed: _loadNextPage,
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        final row = rows[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 8),
          child: _TrafficRow(
            row: row,
            max: max,
            emptyLabel: _emptyLabel,
          ),
        );
      },
    );
  }

  Widget _buildLoadingRows() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        _SkeletonBox(width: double.infinity, height: 40),
        SizedBox(height: 8),
        _SkeletonBox(width: double.infinity, height: 40),
        SizedBox(height: 8),
        _SkeletonBox(width: double.infinity, height: 40),
        SizedBox(height: 8),
        _SkeletonBox(width: double.infinity, height: 40),
      ],
    );
  }

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients || _loadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.extentAfter > 320) {
      return;
    }
    unawaited(_loadNextPage());
  }

  Future<void> _loadNextPage() async {
    final report = ref.read(metricPageControllerProvider(_query)).valueOrNull;
    if (_loadingMore || report == null || !report.hasMore) {
      return;
    }

    setState(() {
      _loadingMore = true;
    });
    await ref.read(metricPageControllerProvider(_query).notifier).loadNextPage();
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingMore = false;
    });
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.report,
    required this.onViewAll,
    this.emptyLabel = 'Unknown',
  });

  final String title;
  final MetricReport report;
  final VoidCallback onViewAll;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final rows = report.rows.take(5).toList(growable: false);
    final max = rows.fold<int>(
      1,
      (value, row) => row.count > value ? row.count : value,
    );

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeading(
            title: title,
            trailing: ShadButton.ghost(
              onPressed: onViewAll,
              child: const Text('View All'),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text('No data', style: theme.textTheme.muted)
          else
            for (final row in rows) ...[
              _TrafficRow(
                row: row,
                max: max,
                emptyLabel: emptyLabel,
              ),
              if (row != rows.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _TrafficRow extends StatelessWidget {
  const _TrafficRow({
    required this.row,
    required this.max,
    this.emptyLabel = 'Unknown',
  });

  final MetricRow row;
  final int max;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final compact = NumberFormat.compact();
    final factor = (row.count / max).clamp(0.04, 1.0).toDouble();
    final label = row.value.trim().isEmpty ? emptyLabel : row.value;

    return SizedBox(
      height: 40,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: theme.colorScheme.muted),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    compact.format(row.count),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSkeletonCard extends StatelessWidget {
  const _MetricSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const _DashboardPanel(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBox(width: 84, height: 14),
          Spacer(),
          _SkeletonBox(width: 104, height: 30),
          SizedBox(height: 10),
          _SkeletonBox(width: 56, height: 14),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final panelColor = Color.lerp(
      theme.colorScheme.background,
      theme.colorScheme.foreground,
      0.018,
    )!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.border),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
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
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: theme.colorScheme.mutedForeground),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.h4, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ShadButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.fillColor,
  });

  final List<TimeSeriesPoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    final maxViews = points.fold<int>(
      1,
      (value, point) => point.pageviews > value ? point.pageviews : value,
    );
    final step = points.length <= 1 ? size.width : size.width / (points.length - 1);
    final path = Path();

    for (var i = 0; i < points.length; i++) {
      final x = i * step;
      final normalized = points[i].pageviews / maxViews;
      final y = size.height - (normalized * size.height * 0.82) - 12;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fillColor != fillColor;
  }
}
