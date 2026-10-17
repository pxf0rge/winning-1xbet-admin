import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

abstract class ArchiveRepository {
  Future<List<SignalModel>> getArchive();
}
