// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HistoryEntryImpl _$$HistoryEntryImplFromJson(Map<String, dynamic> json) =>
    _$HistoryEntryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      projectType: $enumDecode(_$ProjectTypeEnumMap, json['projectType']),
      status: $enumDecode(_$ProcessingStageEnumMap, json['status']),
      summary: json['summary'] as String,
      sourceVideoUri: json['sourceVideoUri'] as String?,
    );

Map<String, dynamic> _$$HistoryEntryImplToJson(_$HistoryEntryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'projectType': _$ProjectTypeEnumMap[instance.projectType]!,
      'status': _$ProcessingStageEnumMap[instance.status]!,
      'summary': instance.summary,
      'sourceVideoUri': instance.sourceVideoUri,
    };

const _$ProjectTypeEnumMap = {
  ProjectType.stabilization: 'stabilization',
  ProjectType.stacking: 'stacking',
  ProjectType.stabilizationPlusStacking: 'stabilizationPlusStacking',
};

const _$ProcessingStageEnumMap = {
  ProcessingStage.idle: 'idle',
  ProcessingStage.validating: 'validating',
  ProcessingStage.decoding: 'decoding',
  ProcessingStage.detectingObject: 'detectingObject',
  ProcessingStage.analyzingMotion: 'analyzingMotion',
  ProcessingStage.stabilizing: 'stabilizing',
  ProcessingStage.analyzingQuality: 'analyzingQuality',
  ProcessingStage.selectingFrames: 'selectingFrames',
  ProcessingStage.aligning: 'aligning',
  ProcessingStage.stacking: 'stacking',
  ProcessingStage.postProcessing: 'postProcessing',
  ProcessingStage.exporting: 'exporting',
  ProcessingStage.done: 'done',
  ProcessingStage.failed: 'failed',
  ProcessingStage.cancelled: 'cancelled',
};
