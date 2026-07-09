import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/history_entry.dart';
import '../infrastructure/history_repository.dart';

final historyRepositoryProvider = Provider((ref) => HistoryRepository());

final historyControllerProvider = AsyncNotifierProvider<HistoryController, List<HistoryEntry>>(
  HistoryController.new,
);

class HistoryController extends AsyncNotifier<List<HistoryEntry>> {
  @override
  Future<List<HistoryEntry>> build() {
    return ref.read(historyRepositoryProvider).loadAll();
  }

  Future<void> addEntry(HistoryEntry entry) async {
    await ref.read(historyRepositoryProvider).add(entry);
    state = AsyncValue.data(await ref.read(historyRepositoryProvider).loadAll());
  }
}
