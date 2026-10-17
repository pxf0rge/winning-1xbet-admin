import 'package:w1xbet_admin/core/constants/match_create_status.dart';

class CreateMatch {
  final String sport;
  final String leagueName;
  final String homeTeam;
  final String awayTeam;
  final CreateMatchStatus status;
  final String? date;

  // conditional fields
  final String? time; // upcoming
  final int? homeScore; // live / finished
  final int? awayScore; // live / finished

  const CreateMatch({
    required this.sport,
    required this.leagueName,
    required this.homeTeam,
    required this.awayTeam,
    required this.status,
    required this.date,
    this.time,
    this.homeScore,
    this.awayScore,
  });
}
