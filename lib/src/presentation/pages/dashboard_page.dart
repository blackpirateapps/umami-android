import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

const _zinc50 = Color(0xFFFAFAFA);
const _zinc900 = Color(0xFF18181B);
const _zinc950 = Color(0xFF09090B);

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
  final _range = AnalyticsDateRange.last7Days();

  String get _rangeLabel => 'Last 7d';

  String get _rangeSubtitle {
    final formatter = DateFormat.MMMd();
    return '${formatter.format(_range.startAt)} - ${formatter.format(_range.endAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final websites = ref.watch(websitesControllerProvider);

    return Scaffold(
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
    final request = DashboardRequest(
      websiteId: activeWebsite.id,
      range: _range,
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
            data: (state) => [
              _buildMetricGrid(state.data),
              _buildMainChart(state.data),
              _buildDataList(state.data),
            ],
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
    final theme = ShadTheme.of(context);
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 16,
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
          onPressed: () {},
          child: Text(_rangeLabel),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Settings',
          child: ShadIconButton.ghost(
            icon: const Icon(LucideIcons.settings),
            onPressed: () => _showSettingsSheet(theme),
          ),
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
      toolbarHeight: 72,
      titleSpacing: 16,
      title: Text(title, style: theme.textTheme.h4),
    );
  }

  Widget _buildLoadingHeader() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      title: const _SkeletonBox(width: 180, height: 40),
      actions: const [
        _SkeletonBox(width: 92, height: 40),
        SizedBox(width: 8),
        _SkeletonBox(width: 40, height: 40),
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
            trend: 12.4,
          ),
          _MetricCard(
            label: 'Visitors',
            value: compact.format(data.stats.visitors),
            trend: 8.1,
          ),
          _MetricCard(
            label: 'Bounce Rate',
            value: percent.format(data.stats.bounceRate),
            trend: -2.7,
          ),
          _MetricCard(
            label: 'Avg. Visit Time',
            value: _formatDuration(averageSeconds),
            trend: 5.2,
          ),
        ]),
      ),
    );
  }

  Widget _buildMainChart(DashboardData data) {
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
                        Text(_rangeSubtitle, style: theme.textTheme.muted),
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

  Widget _buildDataList(DashboardData data) {
    return SliverList(
      delegate: SliverChildListDelegate.fixed([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: _BreakdownSection(
            title: 'Top Pages',
            report: data.topPages,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          child: _BreakdownSection(
            title: 'Top Referrers',
            report: data.referrers,
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
        for (var section = 0; section < 2; section++)
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

  void _showSettingsSheet(ShadThemeData theme) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings', style: theme.textTheme.h4),
              const SizedBox(height: 6),
              Text(widget.session.username, style: theme.textTheme.muted),
              const SizedBox(height: 20),
              ShadButton.destructive(
                leading: const Icon(LucideIcons.logOut),
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).signOut();
                },
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
      },
    );
  }

  int _averageVisitSeconds(SessionStats stats) {
    return stats.visits == 0 ? 0 : stats.totalTimeSeconds ~/ stats.visits;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _message(Object error) {
    return error is Failure ? error.message : error.toString();
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
      constraints: const BoxConstraints(maxWidth: 220),
      child: ShadSelect<String>(
        minWidth: 190,
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
    required this.trend,
  });

  final String label;
  final String value;
  final double trend;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final up = trend >= 0;
    final trendColor = up ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final trendLabel = '${up ? '+' : ''}${trend.toStringAsFixed(1)}%';

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
                up ? LucideIcons.chartBarIncreasing : LucideIcons.chartBarDecreasing,
                color: trendColor,
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
          const SizedBox(height: 8),
          Text(
            trendLabel,
            style: theme.textTheme.small.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.report,
  });

  final String title;
  final MetricReport report;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.large.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ShadButton.ghost(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
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

class _TrafficRow extends StatelessWidget {
  const _TrafficRow({
    required this.row,
    required this.max,
  });

  final MetricRow row;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final compact = NumberFormat.compact();
    final factor = (row.count / max).clamp(0.04, 1.0).toDouble();

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
                      row.value.isEmpty ? 'Direct' : row.value,
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
