enum MatchStatusFilter { all, upcoming, live, finished }

extension MatchStatusFilterExtension on MatchStatusFilter {
  String get label {
    switch (this) {
      case MatchStatusFilter.all:
        return "All";
      case MatchStatusFilter.upcoming:
        return "Upcoming";
      case MatchStatusFilter.live:
        return "Live";
      case MatchStatusFilter.finished:
        return "Finished";
    }
  }
}
