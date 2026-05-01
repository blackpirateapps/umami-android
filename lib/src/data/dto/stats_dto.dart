// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_dto.freezed.dart';
part 'stats_dto.g.dart';

@freezed
class StatsResponseDto with _$StatsResponseDto {
  const factory StatsResponseDto({
    @JsonKey(fromJson: _metricValueFromJson)
    MetricValueDto? visitors,
    @JsonKey(fromJson: _metricValueFromJson)
    MetricValueDto? pageviews,
    @JsonKey(fromJson: _metricValueFromJson)
    MetricValueDto? visits,
    @JsonKey(fromJson: _metricValueFromJson)
    MetricValueDto? bounces,
    @JsonKey(name: 'totaltime', fromJson: _metricValueFromJson)
    MetricValueDto? totalTime,
    @JsonKey(fromJson: _comparisonFromJson)
    StatsComparisonDto? comparison,
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

@freezed
class StatsComparisonDto with _$StatsComparisonDto {
  const factory StatsComparisonDto({
    @JsonKey(fromJson: _nullableNumFromJson) num? visitors,
    @JsonKey(fromJson: _nullableNumFromJson) num? pageviews,
    @JsonKey(fromJson: _nullableNumFromJson) num? visits,
    @JsonKey(fromJson: _nullableNumFromJson) num? bounces,
    @JsonKey(name: 'totaltime', fromJson: _nullableNumFromJson)
    num? totalTime,
  }) = _StatsComparisonDto;

  factory StatsComparisonDto.fromJson(Map<String, dynamic> json) =>
      _$StatsComparisonDtoFromJson(json);
}

MetricValueDto? _metricValueFromJson(Object? value) {
  return switch (value) {
    null => null,
    final Map<String, dynamic> object => MetricValueDto.fromJson(object),
    final Map object => MetricValueDto.fromJson(
        Map<String, dynamic>.from(object),
      ),
    _ => MetricValueDto(value: _numFromJson(value)),
  };
}

StatsComparisonDto? _comparisonFromJson(Object? value) {
  return switch (value) {
    null => null,
    final Map<String, dynamic> object => StatsComparisonDto.fromJson(object),
    final Map object => StatsComparisonDto.fromJson(
        Map<String, dynamic>.from(object),
      ),
    _ => null,
  };
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
