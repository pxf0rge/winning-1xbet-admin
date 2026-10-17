import 'package:w1xbet_admin/core/constants/sport_enum.dart';

/// Canonical bet markets for auto-settlement.
///
/// Stored values are machine-readable English keys.
/// UI shows localized labels via [BetCatalog.label].
class BetMarket {
  final String type; // e.g. 1X2, OVER, UNDER
  final String value; // e.g. 1, X, 2.5, YES
  final String settlementHint; // Regular Time | Including Extra Time | Qualification

  const BetMarket({
    required this.type,
    required this.value,
    this.settlementHint = 'Regular Time',
  });

  String get storageKey => '$type|$value';
}

class BetTypeOption {
  final String id;
  final String Function(bool isFa) label;
  final String settlementHint;
  final List<BetValueOption> Function({
    required String homeTeam,
    required String awayTeam,
  }) values;

  const BetTypeOption({
    required this.id,
    required this.label,
    required this.values,
    this.settlementHint = 'Regular Time',
  });
}

class BetValueOption {
  final String id;
  final String labelEn;
  final String labelFa;

  const BetValueOption({
    required this.id,
    required this.labelEn,
    String? labelFa,
  }) : labelFa = labelFa ?? labelEn;

  String label(bool isFa) => isFa ? labelFa : labelEn;
}

/// Catalog of supported markets. Prefer these over free text.
class BetCatalog {
  BetCatalog._();

  static const customTypeId = 'CUSTOM';

  static List<BetTypeOption> typesForSport(String? sport) {
    final key = SportTypeExtension.normalize(sport);
    switch (key) {
      case 'tennis':
        return _tennisTypes;
      case 'basketball':
        return _basketballTypes;
      case 'handball':
      case 'hockey':
      case 'volleyball':
      case 'futsal':
      case 'beach_soccer':
      case 'waterpolo':
        return _scoreSportsTypes;
      case 'football':
      default:
        return _footballTypes;
    }
  }

  static BetTypeOption? findType(String id, String? sport) {
    for (final t in typesForSport(sport)) {
      if (t.id == id) return t;
    }
    return null;
  }

  static BetValueOption? findValue(
    BetTypeOption type,
    String valueId, {
    required String homeTeam,
    required String awayTeam,
  }) {
    for (final v in type.values(homeTeam: homeTeam, awayTeam: awayTeam)) {
      if (v.id == valueId) return v;
    }
    return null;
  }

  /// Human-readable bet line for lists (FA/EN).
  static String formatBetLabel({
    required String betType,
    required String betValue,
    required bool isFa,
    String homeTeam = '',
    String awayTeam = '',
    String? sport,
  }) {
    final parsed = parseExisting(
      betType: betType,
      betValue: betValue,
      sport: sport,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
    if (parsed.custom) {
      final t = betType.trim();
      final v = betValue.trim();
      if (t.isEmpty) return v;
      if (v.isEmpty) return t;
      return '$t · $v';
    }
    final type = findType(parsed.type, sport);
    if (type == null) return '${parsed.type} · ${parsed.value}';
    final value = findValue(
      type,
      parsed.value,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
    final typeLabel = type.label(isFa);
    if (value != null) return '$typeLabel · ${value.label(isFa)}';
    return '$typeLabel · ${parsed.value}';
  }

  /// Map legacy free-text rows into catalog ids when possible.
  static ({String type, String value, bool custom}) parseExisting({
    required String betType,
    required String betValue,
    required String? sport,
    required String homeTeam,
    required String awayTeam,
  }) {
    final tRaw = betType.trim().toUpperCase();
    final vRaw = betValue.trim();
    final vUpper = vRaw.toUpperCase();

    String? typeId;
    if (tRaw == '1X2' || tRaw == 'MATCH_RESULT' || tRaw == 'RESULT') {
      typeId = '1X2';
    } else if (tRaw == 'OVER' || tRaw.startsWith('OVER')) {
      typeId = 'OVER';
    } else if (tRaw == 'UNDER' || tRaw.startsWith('UNDER') || tRaw == 'UDER') {
      typeId = 'UNDER';
    } else if (tRaw == 'BTTS' || tRaw.contains('BOTH')) {
      typeId = 'BTTS';
    } else if (tRaw == 'DC' || tRaw.contains('DOUBLE')) {
      typeId = 'DC';
    } else if (tRaw == 'AH' || tRaw.contains('HANDICAP') || tRaw.contains('AH')) {
      typeId = 'AH';
    } else if (tRaw == 'QUAL' || tRaw.contains('QUALIF')) {
      typeId = 'QUAL';
    } else if (tRaw == 'ML' || tRaw == 'MONEYLINE') {
      typeId = 'ML';
    } else if (tRaw == 'CUSTOM') {
      typeId = customTypeId;
    }

    // Infer OVER/UNDER from value like "Over 2.5"
    if (typeId == null) {
      final over = RegExp(r'over\s*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false)
          .firstMatch(vRaw);
      final under =
          RegExp(r'under\s*([0-9]+(?:\.[0-9]+)?)', caseSensitive: false)
              .firstMatch(vRaw);
      if (over != null) {
        typeId = 'OVER';
        return (type: 'OVER', value: over.group(1)!, custom: false);
      }
      if (under != null) {
        typeId = 'UNDER';
        return (type: 'UNDER', value: under.group(1)!, custom: false);
      }
    }

    if (typeId == null) {
      return (type: customTypeId, value: vRaw.isEmpty ? betType : vRaw, custom: true);
    }

    final type = findType(typeId, sport);
    if (type == null) {
      return (type: customTypeId, value: vRaw, custom: true);
    }

    // Normalize value
    String valueId = vRaw;
    if (typeId == '1X2' || typeId == 'ML' || typeId == 'QUAL') {
      if (vUpper == '1' ||
          vUpper == 'HOME' ||
          vRaw == homeTeam ||
          vUpper == 'H') {
        valueId = '1';
      } else if (vUpper == '2' ||
          vUpper == 'AWAY' ||
          vRaw == awayTeam ||
          vUpper == 'A') {
        valueId = '2';
      } else if (vUpper == 'X' ||
          vUpper == 'DRAW' ||
          vRaw == 'مساوی' ||
          vUpper == 'D') {
        valueId = 'X';
      }
    } else if (typeId == 'OVER' || typeId == 'UNDER') {
      final m = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(vRaw);
      if (m != null) valueId = m.group(1)!;
    } else if (typeId == 'BTTS') {
      if (vUpper == 'YES' || vUpper == 'Y' || vRaw == 'بله') {
        valueId = 'YES';
      } else if (vUpper == 'NO' || vUpper == 'N' || vRaw == 'خیر') {
        valueId = 'NO';
      }
    } else if (typeId == 'DC') {
      if (vUpper.contains('1X') || vUpper == '10') {
        valueId = '1X';
      } else if (vUpper.contains('X2') || vUpper == '02') {
        valueId = 'X2';
      } else if (vUpper.contains('12') || vUpper == 'NO DRAW') {
        valueId = '12';
      }
    }

    final known = findValue(
      type,
      valueId,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
    if (known != null) {
      return (type: typeId, value: known.id, custom: false);
    }

    // Known type but unknown value → keep as custom text under that type if OVER line etc.
    if ((typeId == 'OVER' || typeId == 'UNDER') &&
        RegExp(r'^[0-9]+(?:\.[0-9]+)?$').hasMatch(valueId)) {
      return (type: typeId, value: valueId, custom: false);
    }

    return (type: customTypeId, value: vRaw, custom: true);
  }

  // ---------- Football ----------
  static final _footballTypes = <BetTypeOption>[
    BetTypeOption(
      id: '1X2',
      label: (fa) => fa ? 'نتیجه مسابقه (۱X۲)' : 'Match Result (1X2)',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1',
          labelEn: 'Home win ($homeTeam)',
          labelFa: 'برد میزبان ($homeTeam)',
        ),
        const BetValueOption(id: 'X', labelEn: 'Draw', labelFa: 'مساوی'),
        BetValueOption(
          id: '2',
          labelEn: 'Away win ($awayTeam)',
          labelFa: 'برد میهمان ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'OVER',
      label: (fa) => fa ? 'بالای گل (Over)' : 'Over Goals',
      values: ({required homeTeam, required awayTeam}) => _goalLines,
    ),
    BetTypeOption(
      id: 'UNDER',
      label: (fa) => fa ? 'زیر گل (Under)' : 'Under Goals',
      values: ({required homeTeam, required awayTeam}) => _goalLines,
    ),
    BetTypeOption(
      id: 'BTTS',
      label: (fa) => fa ? 'هر دو تیم گل می‌زنند' : 'Both Teams To Score',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(id: 'YES', labelEn: 'Yes', labelFa: 'بله'),
        BetValueOption(id: 'NO', labelEn: 'No', labelFa: 'خیر'),
      ],
    ),
    BetTypeOption(
      id: 'DC',
      label: (fa) => fa ? 'شانس دو برابر' : 'Double Chance',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(
          id: '1X',
          labelEn: 'Home or Draw (1X)',
          labelFa: 'میزبان یا مساوی (۱X)',
        ),
        BetValueOption(
          id: '12',
          labelEn: 'Home or Away (12)',
          labelFa: 'میزبان یا میهمان (۱۲)',
        ),
        BetValueOption(
          id: 'X2',
          labelEn: 'Draw or Away (X2)',
          labelFa: 'مساوی یا میهمان (X۲)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'AH',
      label: (fa) => fa ? 'هندیکپ آسیایی' : 'Asian Handicap',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1:-0.5',
          labelEn: 'Home -0.5 ($homeTeam)',
          labelFa: 'میزبان -۰.۵ ($homeTeam)',
        ),
        BetValueOption(
          id: '1:-1.5',
          labelEn: 'Home -1.5 ($homeTeam)',
          labelFa: 'میزبان -۱.۵ ($homeTeam)',
        ),
        BetValueOption(
          id: '2:-0.5',
          labelEn: 'Away -0.5 ($awayTeam)',
          labelFa: 'میهمان -۰.۵ ($awayTeam)',
        ),
        BetValueOption(
          id: '2:-1.5',
          labelEn: 'Away -1.5 ($awayTeam)',
          labelFa: 'میهمان -۱.۵ ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'QUAL',
      label: (fa) => fa ? 'صعود / واجد شرایط شدن' : 'To Qualify',
      settlementHint: 'Qualification',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1',
          labelEn: 'Home qualifies ($homeTeam)',
          labelFa: 'صعود میزبان ($homeTeam)',
        ),
        BetValueOption(
          id: '2',
          labelEn: 'Away qualifies ($awayTeam)',
          labelFa: 'صعود میهمان ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: customTypeId,
      label: (fa) => fa ? 'سایر (دستی)' : 'Other (custom)',
      values: ({required homeTeam, required awayTeam}) => const [],
    ),
  ];

  // ---------- Tennis ----------
  static final _tennisTypes = <BetTypeOption>[
    BetTypeOption(
      id: 'ML',
      label: (fa) => fa ? 'برنده مسابقه' : 'Match Winner',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1',
          labelEn: 'Player 1 ($homeTeam)',
          labelFa: 'برد بازیکن ۱ ($homeTeam)',
        ),
        BetValueOption(
          id: '2',
          labelEn: 'Player 2 ($awayTeam)',
          labelFa: 'برد بازیکن ۲ ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'OVER',
      label: (fa) => fa ? 'بالای ست / گیم' : 'Over Sets/Games',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(id: '2.5', labelEn: 'Over 2.5'),
        BetValueOption(id: '21.5', labelEn: 'Over 21.5 games'),
        BetValueOption(id: '22.5', labelEn: 'Over 22.5 games'),
      ],
    ),
    BetTypeOption(
      id: 'UNDER',
      label: (fa) => fa ? 'زیر ست / گیم' : 'Under Sets/Games',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(id: '2.5', labelEn: 'Under 2.5'),
        BetValueOption(id: '21.5', labelEn: 'Under 21.5 games'),
        BetValueOption(id: '22.5', labelEn: 'Under 22.5 games'),
      ],
    ),
    BetTypeOption(
      id: customTypeId,
      label: (fa) => fa ? 'سایر (دستی)' : 'Other (custom)',
      values: ({required homeTeam, required awayTeam}) => const [],
    ),
  ];

  // ---------- Basketball ----------
  static final _basketballTypes = <BetTypeOption>[
    BetTypeOption(
      id: 'ML',
      label: (fa) => fa ? 'برنده مسابقه' : 'Moneyline',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1',
          labelEn: 'Home ($homeTeam)',
          labelFa: 'برد میزبان ($homeTeam)',
        ),
        BetValueOption(
          id: '2',
          labelEn: 'Away ($awayTeam)',
          labelFa: 'برد میهمان ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'OVER',
      label: (fa) => fa ? 'بالای امتیاز' : 'Over Points',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(id: '210.5', labelEn: '210.5'),
        BetValueOption(id: '220.5', labelEn: '220.5'),
        BetValueOption(id: '230.5', labelEn: '230.5'),
      ],
    ),
    BetTypeOption(
      id: 'UNDER',
      label: (fa) => fa ? 'زیر امتیاز' : 'Under Points',
      values: ({required homeTeam, required awayTeam}) => const [
        BetValueOption(id: '210.5', labelEn: '210.5'),
        BetValueOption(id: '220.5', labelEn: '220.5'),
        BetValueOption(id: '230.5', labelEn: '230.5'),
      ],
    ),
    BetTypeOption(
      id: customTypeId,
      label: (fa) => fa ? 'سایر (دستی)' : 'Other (custom)',
      values: ({required homeTeam, required awayTeam}) => const [],
    ),
  ];

  // ---------- Other score sports ----------
  static final _scoreSportsTypes = <BetTypeOption>[
    BetTypeOption(
      id: '1X2',
      label: (fa) => fa ? 'نتیجه مسابقه (۱X۲)' : 'Match Result (1X2)',
      values: ({required homeTeam, required awayTeam}) => [
        BetValueOption(
          id: '1',
          labelEn: 'Home ($homeTeam)',
          labelFa: 'برد میزبان ($homeTeam)',
        ),
        const BetValueOption(id: 'X', labelEn: 'Draw', labelFa: 'مساوی'),
        BetValueOption(
          id: '2',
          labelEn: 'Away ($awayTeam)',
          labelFa: 'برد میهمان ($awayTeam)',
        ),
      ],
    ),
    BetTypeOption(
      id: 'OVER',
      label: (fa) => fa ? 'بالای گل/امتیاز' : 'Over',
      values: ({required homeTeam, required awayTeam}) => _goalLines,
    ),
    BetTypeOption(
      id: 'UNDER',
      label: (fa) => fa ? 'زیر گل/امتیاز' : 'Under',
      values: ({required homeTeam, required awayTeam}) => _goalLines,
    ),
    BetTypeOption(
      id: customTypeId,
      label: (fa) => fa ? 'سایر (دستی)' : 'Other (custom)',
      values: ({required homeTeam, required awayTeam}) => const [],
    ),
  ];

  static const _goalLines = <BetValueOption>[
    BetValueOption(id: '0.5', labelEn: '0.5'),
    BetValueOption(id: '1.5', labelEn: '1.5'),
    BetValueOption(id: '2.5', labelEn: '2.5'),
    BetValueOption(id: '3.5', labelEn: '3.5'),
    BetValueOption(id: '4.5', labelEn: '4.5'),
  ];
}
