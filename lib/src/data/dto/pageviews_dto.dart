// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pageviews_dto.freezed.dart';
part 'pageviews_dto.g.dart';

@freezed
class PageviewsResponseDto with _$PageviewsResponseDto {
  const factory PageviewsResponseDto({
    @Default(<TimeValueDto>[]) List<TimeValueDto> pageviews,
    @Default(<TimeValueDto>[]) List<TimeValueDto> sessions,
  }) = _PageviewsResponseDto;

  factory PageviewsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PageviewsResponseDtoFromJson(json);
}

@freezed
class TimeValueDto with _$TimeValueDto {
  const factory TimeValueDto({
    @JsonKey(name: 'x') required Object timestamp,
    @JsonKey(name: 'y', fromJson: _intFromJson) required int value,
  }) = _TimeValueDto;

  factory TimeValueDto.fromJson(Map<String, dynamic> json) =>
      _$TimeValueDtoFromJson(json);
}

int _intFromJson(Object? value) {
  return switch (value) {
    final int number => number,
    final num number => number.round(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
}
