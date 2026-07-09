import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/project_draft_controller.dart';
import '../../../core/domain/stack_config.dart';
import '../../../core/widgets/astro_card.dart';

class StackConfigScreen extends ConsumerWidget {
  const StackConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(projectDraftProvider);
    final config = draft.stackConfig;
    final notifier = ref.read(projectDraftProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar empilhamento')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AstroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configuração recomendada', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  _ConfigRow(label: 'Frames', value: 'Melhores ${config.frameSelectionPercent}%'),
                  _ConfigRow(label: 'Método', value: config.stackingMethod.label),
                  _ConfigRow(label: 'Crop', value: config.autoCropEnabled ? 'Automático' : 'Desligado'),
                  _ConfigRow(
                    label: 'Nitidez',
                    value: config.rawMode
                        ? 'Desligada (cru)'
                        : (config.sharpenMode ? 'Leve' : 'Desligada'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Percentual de frames', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              // Include the active percent (e.g. the suggested 33%) so the
              // selection is always visible even when it isn't a preset.
              children: ({10, 25, 50, 75, config.frameSelectionPercent}.toList()..sort()).map((p) {
                final selected = config.frameSelectionPercent == p;
                return ChoiceChip(
                  label: Text('$p%'),
                  selected: selected,
                  onSelected: (_) => notifier.updateStackConfig((c) => c.copyWith(frameSelectionPercent: p)),
                );
              }).toList(),
            ),
            if (draft.framesTotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Melhores ${config.frameSelectionPercent}% = '
                '${(draft.framesTotal * config.frameSelectionPercent / 100).round().clamp(2, config.maxFrames)} '
                'de ${draft.framesTotal} frames analisados'
                '${(draft.framesTotal * config.frameSelectionPercent / 100).round() > config.maxFrames ? ' (limitado pelo máximo de ${config.maxFrames})' : ''}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 20),
            Text('Método de empilhamento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<StackingMethod>(
              segments: const [
                ButtonSegment(value: StackingMethod.simpleAverage, label: Text('Média simples')),
                ButtonSegment(value: StackingMethod.weightedAverage, label: Text('Média ponderada')),
              ],
              selected: {config.stackingMethod},
              onSelectionChanged: (s) => notifier.updateStackConfig((c) => c.copyWith(stackingMethod: s.first)),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Crop automático'),
              value: config.autoCropEnabled,
              onChanged: (v) => notifier.updateStackConfig((c) => c.copyWith(autoCropEnabled: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Nitidez leve'),
              value: !config.rawMode && config.sharpenMode,
              onChanged: config.rawMode
                  ? null
                  : (v) => notifier.updateStackConfig((c) => c.copyWith(sharpenMode: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Empilhamento cru'),
              subtitle: const Text(
                'Só alinha e tira a média dos frames — nenhum ajuste de nitidez ou tom na imagem.',
              ),
              value: config.rawMode,
              onChanged: (v) => notifier.updateStackConfig((c) => c.copyWith(rawMode: v)),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Configurações avançadas'),
              children: [
                Text('Percentual personalizado', style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  value: config.frameSelectionPercent.toDouble(),
                  min: 5,
                  max: 90,
                  divisions: 17,
                  label: '${config.frameSelectionPercent}%',
                  onChanged: (v) => notifier.updateStackConfig((c) => c.copyWith(frameSelectionPercent: v.round())),
                ),
                Text('Máximo de frames: ${config.maxFrames}', style: Theme.of(context).textTheme.bodyMedium),
                Slider(
                  value: config.maxFrames.toDouble(),
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  label: '${config.maxFrames}',
                  onChanged: (v) => notifier.updateStackConfig((c) => c.copyWith(maxFrames: v.round())),
                ),
                const SizedBox(height: 8),
                Text('Formato de saída', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SegmentedButton<OutputFormat>(
                  segments: const [
                    ButtonSegment(value: OutputFormat.png, label: Text('PNG')),
                    ButtonSegment(value: OutputFormat.jpeg, label: Text('JPEG')),
                    ButtonSegment(value: OutputFormat.tiff, label: Text('TIFF')),
                  ],
                  selected: {config.outputFormat},
                  onSelectionChanged: (s) => notifier.updateStackConfig((c) => c.copyWith(outputFormat: s.first)),
                ),
                if (config.outputFormat == OutputFormat.tiff) ...[
                  const SizedBox(height: 8),
                  Text(
                    'TIFF 16-bit: arquivo bruto, sem perdas, ideal para editar depois. '
                    'É salvo na pasta Downloads (a galeria não exibe TIFF). '
                    'Dica: desligue a nitidez para o resultado mais cru possível.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/processing'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Empilhar imagem'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
