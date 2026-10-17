/// Canonical sport keys — must match Supabase `normalize_sport_key`.
enum SportType {
  all,
  football,
  handball,
  hockey,
  basketball,
  volleyball,
  tennis,
  beach_soccer,
  snooker,
  waterpolo,
  futsal,
}

extension SportTypeExtension on SportType {
  String get label {
    switch (this) {
      case SportType.all:
        return 'All';
      case SportType.football:
        return 'Football';
      case SportType.handball:
        return 'Handball';
      case SportType.hockey:
        return 'Hockey';
      case SportType.basketball:
        return 'Basketball';
      case SportType.volleyball:
        return 'Volleyball';
      case SportType.tennis:
        return 'Tennis';
      case SportType.beach_soccer:
        return 'Beach Soccer';
      case SportType.snooker:
        return 'Snooker';
      case SportType.waterpolo:
        return 'Waterpolo';
      case SportType.futsal:
        return 'Futsal';
    }
  }

  /// Value written to / compared against Supabase.
  String get dbKey {
    switch (this) {
      case SportType.all:
        return 'all';
      default:
        return name;
    }
  }

  static String normalize(String? raw) {
    final key = (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '_');

    switch (key) {
      case 'football':
      case 'soccer':
        return 'football';
      case 'handball':
        return 'handball';
      case 'hockey':
      case 'icehockey':
      case 'icehokey':
        return 'hockey';
      case 'basketball':
        return 'basketball';
      case 'volleyball':
        return 'volleyball';
      case 'tennis':
        return 'tennis';
      case 'beach_soccer':
      case 'beachsoccer':
        return 'beach_soccer';
      case 'snooker':
      case 'snocker':
        return 'snooker';
      case 'waterpolo':
        return 'waterpolo';
      case 'futsal':
      case 'footsall':
        return 'futsal';
      default:
        return (raw ?? 'football').toLowerCase();
    }
  }

  static SportType? fromDb(String? raw) {
    final key = normalize(raw);
    for (final sport in SportType.values) {
      if (sport != SportType.all && sport.dbKey == key) return sport;
    }
    return null;
  }
}
