import 'package:w1xbet_admin/features/archive/data/datasource/archive_remote_datasource.dart';
import 'package:w1xbet_admin/features/archive/domain/repositories/archive_repository.dart';
import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

class ArchiveRepositoryImpl implements ArchiveRepository {
  final ArchiveSupabaseDatasource remote;

  ArchiveRepositoryImpl(this.remote);

  @override
  Future<List<SignalModel>> getArchive() async {
    return await remote.getArchive();
  }
}
