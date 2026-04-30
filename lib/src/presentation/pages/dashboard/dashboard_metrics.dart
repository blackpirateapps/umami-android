part of '../dashboard_page.dart';

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
