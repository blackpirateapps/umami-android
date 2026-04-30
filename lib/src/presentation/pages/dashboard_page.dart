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

part 'dashboard/navigation.dart';
part 'dashboard/date_range_controls.dart';
part 'dashboard/settings_widgets.dart';
part 'dashboard/dashboard_chrome.dart';
part 'dashboard/dashboard_metrics.dart';
part 'dashboard/analytics_sections.dart';
part 'dashboard/metric_detail_page.dart';

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
