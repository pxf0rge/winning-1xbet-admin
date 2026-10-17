class Match {
  final String id;
  final String sport;
  final String homeTeam;
  final String game_date;
  final String leagueName;
  final String? leagueCountry;
  final String awayTeam;
  final String status;
  final String display;
  final bool isManual;

  const Match({
    required this.id,
    required this.sport,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.display,
    required this.game_date,
    required this.leagueName,
    this.leagueCountry,
    this.isManual = false,
  });

  String get leagueLine {
    final league = leagueName.trim();
    final country = (leagueCountry ?? '').trim();
    if (country.isEmpty) return league;
    if (league.isEmpty) return country;
    if (league.toLowerCase().contains(country.toLowerCase())) return league;
    return '$country · $league';
  }
}
