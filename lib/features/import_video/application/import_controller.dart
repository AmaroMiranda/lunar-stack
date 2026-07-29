import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/video_metadata.dart';
import '../../../core/native/frame_extractor_channel.dart';
import '../infrastructure/video_metadata_reader.dart';

enum ImportStatus { idle, picking, ready, error }

class ImportState {
  const ImportState({
    this.status = ImportStatus.idle,
    this.metadata,
    this.previewController,
    this.errorMessage,
  });

  final ImportStatus status;
  final VideoMetadata? metadata;
  final VideoPlayerController? previewController;
  final String? errorMessage;

  ImportState copyWith({
    ImportStatus? status,
    VideoMetadata? metadata,
    VideoPlayerController? previewController,
    String? errorMessage,
  }) {
    return ImportState(
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      previewController: previewController ?? this.previewController,
      errorMessage: errorMessage,
    );
  }
}

final importControllerProvider = NotifierProvider<ImportController, ImportState>(ImportController.new);

class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() {
    ref.onDispose(() {
      state.previewController?.dispose();
    });
    return const ImportState();
  }

  Future<void> pickVideo() async {
    state = state.copyWith(status: ImportStatus.picking, errorMessage: null);

    final FilePickerResult? result;
    try {
      // FileType.any (não .video): o filtro de MIME do sistema esconde formatos
      // que o extrator lê bem — de MP4 com codec fora do padrão a vídeos de
      // câmera astro (o usuário reportou MP4 "não aceitos"). Validamos o
      // conteúdo depois, não pela classificação do seletor.
      result = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (_) {
      state = ImportState(
        status: ImportStatus.error,
        errorMessage:
            'Não consegui abrir o seletor de arquivos. Verifique as permissões do app.',
      );
      return;
    }

    if (result == null || result.files.single.path == null) {
      state = const ImportState(status: ImportStatus.idle);
      return;
    }

    final file = result.files.single;
    final path = file.path!;

    await state.previewController?.dispose();

    // Tenta o preview do ExoPlayer — MAS não rejeita se ele falhar. O ExoPlayer
    // é bem mais exigente que o extrator nativo (MediaExtractor/
    // MediaMetadataRetriever) que faz o trabalho de verdade; rejeitar no preview
    // jogava fora vídeos que empilham normalmente. Se o preview falhar, seguimos
    // com a metadata do probe nativo e sem prévia em vídeo.
    VideoPlayerController? controller = VideoPlayerController.file(File(path));
    var previewOk = false;
    try {
      await controller.initialize();
      final s = controller.value.size;
      previewOk = controller.value.duration.inMilliseconds > 0 &&
          s.width > 0 &&
          s.height > 0;
    } catch (_) {
      previewOk = false;
    }

    if (previewOk) {
      final metadata = buildMetadataFromController(
        uri: path,
        fileName: file.name,
        fileSizeBytes: file.size,
        controller: controller,
      );
      state = ImportState(
        status: ImportStatus.ready,
        metadata: metadata,
        previewController: controller,
      );
      return;
    }

    // Preview falhou → probe nativo (rápido, sem decodificar frames).
    await controller.dispose();
    controller = null;
    final probe = await FrameExtractorChannel().probeVideo(videoPath: path);
    if (probe == null) {
      final ext = (file.extension ?? path.split('.').last).toLowerCase();
      final serHint = ext == 'ser'
          ? ' O formato SER ainda não é suportado no fluxo de vídeo.'
          : '';
      state = ImportState(
        status: ImportStatus.error,
        errorMessage:
            'Não consegui ler esse arquivo como vídeo.$serHint Tente MP4, MOV, AVI ou MKV.',
      );
      return;
    }

    final metadata = buildMetadataFromProbe(
      uri: path,
      fileName: file.name,
      fileSizeBytes: file.size,
      durationMs: probe.durationMs,
      width: probe.width,
      height: probe.height,
      frameCount: probe.frameCount,
      fps: probe.fps,
    );
    state = ImportState(
      status: ImportStatus.ready,
      metadata: metadata,
      previewController: null,
    );
  }

  void clear() {
    state.previewController?.dispose();
    state = const ImportState();
  }
}
