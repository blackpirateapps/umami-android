final class Website {
  const Website({
    required this.id,
    required this.name,
    required this.domain,
    required this.createdAt,
    required this.updatedAt,
    this.shareId,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String domain;
  final String? shareId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
}
