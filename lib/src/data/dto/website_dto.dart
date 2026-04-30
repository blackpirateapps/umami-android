import 'package:freezed_annotation/freezed_annotation.dart';

part 'website_dto.freezed.dart';
part 'website_dto.g.dart';

@freezed
class WebsiteDto with _$WebsiteDto {
  const factory WebsiteDto({
    required String id,
    required String name,
    required String domain,
    String? shareId,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(true) bool isActive,
  }) = _WebsiteDto;

  factory WebsiteDto.fromJson(Map<String, dynamic> json) =>
      _$WebsiteDtoFromJson(json);
}
