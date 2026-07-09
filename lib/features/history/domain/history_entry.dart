import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/processing_stage.dart';
import '../../../core/domain/project_type.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

@freezed
class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    required String name,
    required DateTime createdAt,
    required ProjectType projectType,
    required ProcessingStage status,
    required String summary,
    String? sourceVideoUri,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => _$HistoryEntryFromJson(json);
}
