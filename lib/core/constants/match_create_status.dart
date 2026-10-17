enum CreateMatchStatus { upcoming, live, finished }

extension CreateMatchStatusX on CreateMatchStatus {
  String get label {
    switch (this) {
      case CreateMatchStatus.upcoming:
        return "Upcoming";
      case CreateMatchStatus.live:
        return "Live";
      case CreateMatchStatus.finished:
        return "Finished";
    }
  }
}
