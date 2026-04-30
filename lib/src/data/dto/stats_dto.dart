import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_dto.freezed.dart';
part 'stats_dto.g.dart';

@freezed
class StatsResponseDto with _$StatsResponseDto {
  const factory StatsResponseDto({
    MetricValueDto? visitors,
    MetricValueDto? pageviews,
    MetricValueDto? visits,
    MetricValueDto? bounces,
    @JsonKey(name: 'totaltime') MetricValueDto? totalTime,
  }) = _StatsResponseDto;

  factory StatsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$StatsResponseDtoFromJson(json);
}

@freezed
class MetricValueDto with _$MetricValueDto {
  const factory MetricValueDto({
    @JsonKey(fromJson: _numFromJson) required num value,
    @JsonKey(fromJson: _nullableNumFromJson) num? prev,
  }) = _MetricValueDto;

  factory MetricValueDto.fromJson(Map<String, dynamic> json) =>
      _$MetricValueDtoFromJson(json);
}

num _numFromJson(Object? value) {
  return switch (value) {
    final num number => number,
    final String text => num.tryParse(text) ?? 0,
    _ => 0,
  };
}

num? _nullableNumFromJson(Object? value) {
  return switch (value) {
    null => null,
    final num number => number,
    final String text => num.tryParse(text),
    _ => null,
  };
}
