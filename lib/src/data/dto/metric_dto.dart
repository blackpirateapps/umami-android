// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/analytics_query.dart';

part 'metric_dto.freezed.dart';
part 'metric_dto.g.dart';

@freezed
class MetricResponseDto with _$MetricResponseDto {
  const factory MetricResponseDto({
    required MetricType type,
    @Default(<MetricDto>[]) List<MetricDto> rows,
    @Default(0) int total,
    @Default(0) int offset,
    @Default(25) int limit,
  }) = _MetricResponseDto;

  factory MetricResponseDto.fromJson(Map<String, dynamic> json) =>
      _$MetricResponseDtoFromJson(json);
}

@freezed
class MetricDto with _$MetricDto {
  const factory MetricDto({
    @JsonKey(name: 'x', fromJson: _stringFromJson) required String value,
    @JsonKey(name: 'y', fromJson: _intFromJson) required int count,
  }) = _MetricDto;

  factory MetricDto.fromJson(Map<String, dynamic> json) =>
      _$MetricDtoFromJson(json);
}

String _stringFromJson(Object? value) => value?.toString() ?? 'Unknown';

int _intFromJson(Object? value) {
  return switch (value) {
    final int number => number,
    final num number => number.round(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
}
