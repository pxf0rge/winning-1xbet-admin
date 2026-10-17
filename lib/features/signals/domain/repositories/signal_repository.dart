import '../entities/signal.dart';

abstract class SignalRepository {
  Future<List<Signal>> getMatchSignals(String matchId);

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
  });

  Future<List<Signal>> getPendingSignals();

  Future<List<Signal>> getAllSignals();
}
