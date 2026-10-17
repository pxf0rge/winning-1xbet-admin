import '../../domain/entities/match.dart';

class MatchModel extends Match {
  const MatchModel({
    required super.id,
    required super.sport,
    required super.homeTeam,
    required super.awayTeam,
    required super.status,
    required super.game_date,
    required super.leagueName,
    required super.display,
    super.leagueCountry,
    super.isManual,
  });

  factory MatchModel.fromJson(Map<String, dynamic> j) {
    return MatchModel(
      id: j['game_id'].toString(),
      sport: j['sport']?.toString() ?? '',
      homeTeam: j['home_team']?.toString() ?? '',
      awayTeam: j['away_team']?.toString() ?? '',
      status: j['match_status']?.toString() ?? 'Upcoming',
      game_date: j['game_date']?.toString() ?? '',
      leagueName: j['league_name']?.toString() ?? '',
      leagueCountry: j['league_country']?.toString(),
      display: j['result_or_time']?.toString() ?? '',
      isManual: j['is_manual'] == true,
    );
  }
}
