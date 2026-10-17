import 'package:w1xbet_admin/features/signals/data/datasource/signal_remote_datasource.dart';
import 'package:w1xbet_admin/features/signals/domain/entities/signal.dart';
import '../../domain/repositories/signal_repository.dart';

class SignalRepositoryImpl implements SignalRepository {
  final SignalRemoteDatasource remote;

  SignalRepositoryImpl(this.remote);

  @override
  Future<List<Signal>> getMatchSignals(String matchId) {
    return remote.getSignalsByMatch(matchId);
  }

  @override
  Future<List<Signal>> getPendingSignals() {
    return remote.getPendingSignals();
  }

  @override
  Future<List<Signal>> getAllSignals() {
    return remote.getAllSignals();
  }

  @override
  Future<void> upsertSignal({
    required String matchId,
    required String betType,
    required String betValue,
    required String signalType,
    required String status,
    required String leagueName,
    required String gameDate,
    required String sport,
    double? odds,
    String? settlementType,
    bool isFeatured = true,
    String? analysis,
  }) {
    return remote.upsertSignal(
      matchId: matchId,
      betType: betType,
      betValue: betValue,
      signalType: signalType,
      status: status,
      leagueName: leagueName,
      gameDate: gameDate,
      sport: sport,
      odds: odds,
      settlementType: settlementType,
      isFeatured: isFeatured,
      analysis: analysis,
    );
  }
}
