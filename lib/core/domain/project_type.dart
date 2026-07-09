enum ProjectType {
  stabilization,
  stacking,
  stabilizationPlusStacking,
}

extension ProjectTypeLabel on ProjectType {
  String get title {
    switch (this) {
      case ProjectType.stabilization:
        return 'Apenas estabilizar';
      case ProjectType.stacking:
        return 'Apenas empilhar';
      case ProjectType.stabilizationPlusStacking:
        return 'Estabilizar + empilhar';
    }
  }

  String get description {
    switch (this) {
      case ProjectType.stabilization:
        return 'Para gerar um vídeo da Lua mais parado e centralizado.';
      case ProjectType.stacking:
        return 'Para gerar uma imagem final com menos ruído e mais detalhe.';
      case ProjectType.stabilizationPlusStacking:
        return 'Recomendado para vídeos tremidos.';
    }
  }
}
