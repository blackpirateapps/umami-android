part of '../dashboard_page.dart';

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
