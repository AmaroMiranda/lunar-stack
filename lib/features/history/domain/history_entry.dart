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
    // Caminho do resultado final salvo (imagem mestre ou vídeo estabilizado),
    // para reabrir o projeto e re-exportar. Prévia JPEG quando o mestre é TIFF.
    String? resultPath,
    String? previewPath,
    int? resultWidth,
    int? resultHeight,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => _$HistoryEntryFromJson(json);
}
