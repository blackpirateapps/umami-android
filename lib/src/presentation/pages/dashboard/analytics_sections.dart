part of '../dashboard_page.dart';

class _EnvironmentSection extends StatelessWidget {
  const _EnvironmentSection({
    required this.browsers,
    required this.operatingSystems,
    required this.devices,
    required this.onViewAll,
    required this.onFilter,
  });

  final MetricReport browsers;
  final MetricReport operatingSystems;
  final MetricReport devices;
  final void Function(String title, MetricType type) onViewAll;
  final void Function(MetricType type, String value) onFilter;

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
            onFilter: onFilter,
          ),
          const SizedBox(height: 18),
          _MetricPreviewBlock(
            title: 'Operating Systems',
            report: operatingSystems,
            onViewAll: () => onViewAll('Operating Systems', MetricType.os),
            onFilter: onFilter,
          ),
          const SizedBox(height: 18),
          _MetricPreviewBlock(
            title: 'Devices',
            report: devices,
            onViewAll: () => onViewAll('Devices', MetricType.device),
            onFilter: onFilter,
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
    required this.onFilter,
  });

  final MetricReport countries;
  final VoidCallback onViewAll;
  final void Function(MetricType type, String value) onFilter;

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
                onTap: () => onFilter(countries.type, row.value),
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
    required this.onFilter,
  });

  final String title;
  final MetricReport report;
  final VoidCallback onViewAll;
  final void Function(MetricType type, String value) onFilter;

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
              onTap: () => onFilter(report.type, row.value),
            ),
            if (row != rows.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}
