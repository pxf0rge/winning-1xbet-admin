class Signal {
  final String id;
  final int matchId;
  final String betType;
  final String betValue;
  final String signalType;
  final String status;
  final String leagueName;
  final String gameDate;
  final String sport;
  final double? odds;
  final String? settlementType;
  final bool isFeatured;
  final String? analysis;
  final String? homeTeam;
  final String? awayTeam;

  Signal({
    required this.id,
    required this.matchId,
    required this.betType,
    required this.betValue,
    required this.signalType,
    required this.status,
    required this.leagueName,
    required this.gameDate,
    required this.sport,
    this.odds,
    this.settlementType,
    this.isFeatured = true,
    this.analysis,
    this.homeTeam,
    this.awayTeam,
  });

  String get matchTitle {
    final home = homeTeam?.trim() ?? '';
    final away = awayTeam?.trim() ?? '';
    if (home.isNotEmpty && away.isNotEmpty) return '$home vs $away';
    if (home.isNotEmpty) return home;
    if (away.isNotEmpty) return away;
    return '';
  }

  Signal copyWith({
    String? homeTeam,
    String? awayTeam,
  }) {
    return Signal(
      id: id,
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
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
    );
  }
}
