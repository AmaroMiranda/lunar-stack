import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/widgets/astro_card.dart';

/// Extensões de imagem que o motor (OpenCV imread) decodifica bem.
const _kImageExtensions = ['jpg', 'jpeg', 'png', 'tif', 'tiff', 'bmp', 'webp', 'heic', 'heif'];

class ImageImportScreen extends ConsumerStatefulWidget {
  const ImageImportScreen({super.key});

  @override
  ConsumerState<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends ConsumerState<ImageImportScreen> {
  bool _picking = false;
  String? _error;

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });

    FilePickerResult? result;
    try {
      // Tenta o filtro por extensão (mostra só imagens). Em alguns aparelhos o
      // seletor custom falha — nesse caso caímos para FileType.image, e como
      // último recurso FileType.any (validamos as extensões nós mesmos).
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: _kImageExtensions,
          allowMultiple: true,
        );
      } catch (_) {
        try {
          result = await FilePicker.platform
              .pickFiles(type: FileType.image, allowMultiple: true);
        } catch (_) {
          result = await FilePicker.platform
              .pickFiles(type: FileType.any, allowMultiple: true);
        }
      }
    } catch (_) {
      setState(() {
        _picking = false;
        _error = 'Não consegui abrir o seletor de arquivos. Verifique as permissões do app.';
      });
      return;
    }

    if (result == null) {
      setState(() => _picking = false);
      return;
    }

    final paths = <String>[
      for (final f in result.files)
        if (f.path != null &&
            _kImageExtensions.contains((f.extension ?? f.path!.split('.').last).toLowerCase()))
          f.path!,
    ];

    if (paths.length < 2) {
      setState(() {
        _picking = false;
        _error = paths.length == 1
            ? 'Selecione pelo menos 2 imagens para empilhar.'
            : 'Nenhuma imagem válida selecionada. Use JPG, PNG, TIFF, BMP ou WEBP.';
      });
      return;
    }

    ref.read(projectDraftProvider.notifier).setImageSources(paths);
    if (mounted) context.push('/analysis');
    setState(() => _picking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Empilhar imagens')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecione as fotos da Lua',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha 2 ou mais imagens do mesmo alvo. O app mede a nitidez de '
                'cada uma, alinha e empilha para reduzir ruído e revelar detalhe.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              AstroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates_outlined,
                            color: Theme.of(context).colorScheme.tertiary, size: 20),
                        const SizedBox(width: 8),
                        Text('Dicas', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Fotos do mesmo enquadramento empilham melhor.\n'
                      '• Formatos aceitos: JPG, PNG, TIFF, BMP, WEBP.\n'
                      '• Pode misturar tremidas e nítidas — o app descarta as piores se você quiser.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              const Spacer(),
              FilledButton.icon(
                onPressed: _picking ? null : _pick,
                icon: _picking
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_picking ? 'Abrindo...' : 'Selecionar imagens'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
