import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/domain/video_metadata.dart';
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
      result = await FilePicker.platform.pickFiles(type: FileType.video);
    } catch (_) {
      state = ImportState(
        status: ImportStatus.error,
        errorMessage: 'Não consegui abrir a galeria de vídeos. Verifique as permissões do app.',
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
    final controller = VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
    } catch (_) {
      state = ImportState(
        status: ImportStatus.error,
        errorMessage: 'Não consegui ler esse vídeo. Tente usar um arquivo MP4 ou um vídeo mais curto.',
      );
      return;
    }

    final metadata = buildMetadataFromController(
      uri: path,
      fileName: file.name,
      fileSizeBytes: file.size,
      controller: controller,
    );

    // Some non-video files (e.g. a PNG picked from the "Recent" list) still
    // "initialize" in video_player but report a 0x0 / zero-duration track.
    // Reject them here with a clear message instead of failing later during
    // frame extraction with a cryptic decoder error.
    if (metadata.width == 0 || metadata.height == 0 || metadata.durationMs == 0) {
      await controller.dispose();
      state = const ImportState(
        status: ImportStatus.error,
        errorMessage: 'Esse arquivo não parece ser um vídeo. Selecione um vídeo MP4 da Lua.',
      );
      return;
    }

    state = ImportState(
      status: ImportStatus.ready,
      metadata: metadata,
      previewController: controller,
    );
  }

  void clear() {
    state.previewController?.dispose();
    state = const ImportState();
  }
}
