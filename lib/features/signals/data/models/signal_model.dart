import '../../domain/entities/signal.dart';

class SignalModel extends Signal {
  SignalModel({
    required super.id,
    required super.matchId,
    required super.betType,
    required super.betValue,
    required super.signalType,
    required super.status,
    required super.leagueName,
    required super.gameDate,
    required super.sport,
    super.odds,
    super.settlementType,
    super.isFeatured,
    super.analysis,
    super.homeTeam,
    super.awayTeam,
  });

  factory SignalModel.fromJson(Map<String, dynamic> json) {
    final rawOdds = json['odds'];
    double? odds;

    if (rawOdds != null) {
      if (rawOdds is num) {
        odds = rawOdds.toDouble();
      } else if (rawOdds is String) {
        odds = double.tryParse(rawOdds);
      }
    }

    return SignalModel(
      id: json['id']?.toString() ?? '',
      matchId: int.parse(json['match_id'].toString()),
      betType: json['bet_type']?.toString() ?? '',
      betValue: json['bet_value']?.toString() ?? '',
      signalType: json['signal_type']?.toString() ?? 'FREE',
      status: json['status']?.toString() ?? 'PENDING',
      leagueName: json['league_name']?.toString() ?? '',
      gameDate: json['game_date']?.toString() ?? '',
      sport: json['sport']?.toString() ?? '',
      odds: odds,
      settlementType: json['settlement_type']?.toString(),
      isFeatured: json['is_featured'] != false,
      analysis: json['analysis']?.toString(),
      homeTeam: json['home_team']?.toString(),
      awayTeam: json['away_team']?.toString(),
    );
  }

  SignalModel withTeams({String? homeTeam, String? awayTeam}) {
    return SignalModel(
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
