import '../../domain/entities/dashboard_data.dart';

final class DashboardState {
  const DashboardState({
    required this.data,
    this.lastUpdatedLabel = 'Just now',
  });

  final DashboardData data;
  final String lastUpdatedLabel;
}
