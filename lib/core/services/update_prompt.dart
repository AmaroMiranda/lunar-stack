import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_checker.dart';

/// Checks GitHub for a newer release and, if found, offers the download.
/// Call once after the first frame of the home screen; completely silent when
/// up to date or offline.
Future<void> maybePromptUpdate(BuildContext context) async {
  final info = await UpdateChecker.check();
  if (info == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.system_update_alt_rounded),
      title: Text('Atualização disponível (${info.tag})'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uma nova versão do LunarStack foi publicada.'),
            if (info.highlights != null) ...[
              const SizedBox(height: 12),
              Text(
                info.highlights!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            UpdateChecker.dismiss(info.tag);
            Navigator.of(context).pop();
          },
          child: const Text('Agora não'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final navigator = Navigator.of(context);
            var ok = false;
            try {
              ok = await launchUrl(Uri.parse(info.url),
                  mode: LaunchMode.externalApplication);
            } catch (_) {
              ok = false;
            }
            navigator.pop();
            if (!ok) {
              messenger?.showSnackBar(const SnackBar(
                content: Text('Não foi possível abrir o link da atualização.'),
              ));
            }
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text('Baixar'),
        ),
      ],
    ),
  );
}
