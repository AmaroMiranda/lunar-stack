enum ProcessingStage {
  idle,
  validating,
  decoding,
  detectingObject,
  analyzingMotion,
  stabilizing,
  analyzingQuality,
  selectingFrames,
  aligning,
  stacking,
  postProcessing,
  exporting,
  done,
  failed,
  cancelled,
}

extension ProcessingStageLabel on ProcessingStage {
  String get label {
    switch (this) {
      case ProcessingStage.idle:
        return 'Aguardando';
      case ProcessingStage.validating:
        return 'Validando vídeo';
      case ProcessingStage.decoding:
        return 'Decodificando frames';
      case ProcessingStage.detectingObject:
        return 'Detectando a posição da Lua em cada frame';
      case ProcessingStage.analyzingMotion:
        return 'Calculando estabilização';
      case ProcessingStage.stabilizing:
        return 'Aplicando estabilização e crop';
      case ProcessingStage.analyzingQuality:
        return 'Analisando nitidez dos frames';
      case ProcessingStage.selectingFrames:
        return 'Selecionando os frames mais nítidos';
      case ProcessingStage.aligning:
        return 'Alinhando crateras para evitar imagem fantasma';
      case ProcessingStage.stacking:
        return 'Somando os melhores frames para reduzir ruído';
      case ProcessingStage.postProcessing:
        return 'Aplicando ajustes finais';
      case ProcessingStage.exporting:
        return 'Exportando resultado';
      case ProcessingStage.done:
        return 'Concluído';
      case ProcessingStage.failed:
        return 'Falhou';
      case ProcessingStage.cancelled:
        return 'Cancelado';
    }
  }

  /// Short stage name for the card title — [label] is the longer
  /// explanatory text shown underneath.
  String get shortLabel {
    switch (this) {
      case ProcessingStage.idle:
        return 'Aguardando';
      case ProcessingStage.validating:
        return 'Validando';
      case ProcessingStage.decoding:
        return 'Decodificando';
      case ProcessingStage.detectingObject:
        return 'Detectando a Lua';
      case ProcessingStage.analyzingMotion:
        return 'Estabilizando';
      case ProcessingStage.stabilizing:
        return 'Estabilizando';
      case ProcessingStage.analyzingQuality:
        return 'Analisando';
      case ProcessingStage.selectingFrames:
        return 'Selecionando frames';
      case ProcessingStage.aligning:
        return 'Alinhando';
      case ProcessingStage.stacking:
        return 'Empilhando';
      case ProcessingStage.postProcessing:
        return 'Finalizando';
      case ProcessingStage.exporting:
        return 'Exportando';
      case ProcessingStage.done:
        return 'Concluído';
      case ProcessingStage.failed:
        return 'Falhou';
      case ProcessingStage.cancelled:
        return 'Cancelado';
    }
  }
}
