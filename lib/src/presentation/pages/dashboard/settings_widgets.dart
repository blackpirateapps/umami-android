part of '../dashboard_page.dart';

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
