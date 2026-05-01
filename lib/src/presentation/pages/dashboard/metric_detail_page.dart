part of '../dashboard_page.dart';

class _MetricDetailPage extends ConsumerStatefulWidget {
  const _MetricDetailPage({
    required this.title,
    required this.type,
    required this.website,
    required this.range,
    required this.filters,
    required this.onFilter,
  });

  final String title;
  final MetricType type;
  final Website website;
  final AnalyticsDateRange range;
  final AnalyticsFilters filters;
  final void Function(MetricType type, String value) onFilter;

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
      filters: widget.filters,
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
            onTap: () => widget.onFilter(widget.type, row.value),
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
