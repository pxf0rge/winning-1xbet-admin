import '../entities/signal.dart';
import '../repositories/signal_repository.dart';

class GetPendingSignalsUsecase {
  final SignalRepository repo;

  GetPendingSignalsUsecase(this.repo);

  Future<List<Signal>> call() {
    return repo.getPendingSignals();
  }
}
