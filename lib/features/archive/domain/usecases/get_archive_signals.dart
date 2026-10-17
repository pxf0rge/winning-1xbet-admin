import 'package:w1xbet_admin/features/archive/domain/repositories/archive_repository.dart';
import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

class GetArchiveSignals {
  final ArchiveRepository repo;

  GetArchiveSignals(this.repo);

  Future<List<SignalModel>> call() {
    return repo.getArchive();
  }
}
