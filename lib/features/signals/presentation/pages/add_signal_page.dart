import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/constants/bet_catalog.dart';
import 'package:w1xbet_admin/core/constants/service_locator.dart';
import 'package:w1xbet_admin/core/constants/sport_enum.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/match.dart';
import 'package:w1xbet_admin/features/signals/domain/entities/signal.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/add_signal_cubit.dart';

class AddSignalPage extends StatefulWidget {
  final Match match;
  final Signal? signal;

  const AddSignalPage({super.key, required this.match, this.signal});

  @override
  State<AddSignalPage> createState() => _AddSignalPageState();
}

class _AddSignalPageState extends State<AddSignalPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController oddsCtrl;
  late final TextEditingController analysisCtrl;
  late final TextEditingController customTypeCtrl;
  late final TextEditingController customValueCtrl;
  late final TextEditingController customLineCtrl;

  late String selectedBetType;
  String? selectedBetValue;
  late String signalStatus;
  late String signalType;
  late String settlementType;
  late bool isFeatured;
  late bool isCustomMarket;

  static const _settlementDb = [
    'Regular Time',
    'Including Extra Time',
    'Qualification',
  ];

  List<BetTypeOption> get _types =>
      BetCatalog.typesForSport(widget.match.sport);

  BetTypeOption? get _currentType =>
      BetCatalog.findType(selectedBetType, widget.match.sport);

  List<BetValueOption> get _currentValues {
    final type = _currentType;
    if (type == null) return const [];
    return type.values(
      homeTeam: widget.match.homeTeam,
      awayTeam: widget.match.awayTeam,
    );
  }

  @override
  void initState() {
    super.initState();
    oddsCtrl = TextEditingController();
    analysisCtrl = TextEditingController();
    customTypeCtrl = TextEditingController();
    customValueCtrl = TextEditingController();
    customLineCtrl = TextEditingController();

    final s = widget.signal;
    if (s != null) {
      final parsed = BetCatalog.parseExisting(
        betType: s.betType,
        betValue: s.betValue,
        sport: widget.match.sport,
        homeTeam: widget.match.homeTeam,
        awayTeam: widget.match.awayTeam,
      );
      selectedBetType = parsed.type;
      selectedBetValue = parsed.custom ? null : parsed.value;
      isCustomMarket = parsed.custom || parsed.type == BetCatalog.customTypeId;
      if (isCustomMarket) {
        selectedBetType = BetCatalog.customTypeId;
        customTypeCtrl.text =
            parsed.type == BetCatalog.customTypeId ? s.betType : parsed.type;
        customValueCtrl.text = parsed.value;
      } else if ((parsed.type == 'OVER' || parsed.type == 'UNDER') &&
          !_currentValues.any((v) => v.id == parsed.value)) {
        customLineCtrl.text = parsed.value;
        selectedBetValue = null;
      }
      signalType = s.signalType.toUpperCase() == 'VIP' ? 'VIP' : 'FREE';
      signalStatus = s.status.toUpperCase();
      oddsCtrl.text = s.odds != null ? s.odds!.toString() : '';
      settlementType = _normalizeSettlement(s.settlementType);
      analysisCtrl.text = s.analysis ?? '';
      isFeatured = s.isFeatured;
    } else {
      selectedBetType = _types.first.id;
      selectedBetValue = '1';
      isCustomMarket = false;
      signalType = 'FREE';
      signalStatus = 'PENDING';
      settlementType = 'Regular Time';
      isFeatured = true;
    }
  }

  String _normalizeSettlement(String? raw) {
    if (raw == null || raw.isEmpty) return 'Regular Time';
    if (_settlementDb.contains(raw)) return raw;
    final lower = raw.toLowerCase();
    if (lower.contains('extra')) return 'Including Extra Time';
    if (lower.contains('qualif')) return 'Qualification';
    return 'Regular Time';
  }

  void _onBetTypeChanged(String typeId) {
    final type = BetCatalog.findType(typeId, widget.match.sport);
    setState(() {
      selectedBetType = typeId;
      isCustomMarket = typeId == BetCatalog.customTypeId;
      customLineCtrl.clear();
      if (isCustomMarket) {
        selectedBetValue = null;
      } else {
        final values = type?.values(
              homeTeam: widget.match.homeTeam,
              awayTeam: widget.match.awayTeam,
            ) ??
            const [];
        selectedBetValue = values.isNotEmpty ? values.first.id : null;
        if (type != null) {
          settlementType = type.settlementHint;
        }
      }
    });
  }

  String get _resolvedBetType {
    if (isCustomMarket) {
      final t = customTypeCtrl.text.trim();
      return t.isEmpty ? 'CUSTOM' : t;
    }
    return selectedBetType;
  }

  String get _resolvedBetValue {
    if (isCustomMarket) return customValueCtrl.text.trim();
    if ((selectedBetType == 'OVER' || selectedBetType == 'UNDER') &&
        (selectedBetValue == null || selectedBetValue!.isEmpty) &&
        customLineCtrl.text.trim().isNotEmpty) {
      return customLineCtrl.text.trim();
    }
    return selectedBetValue?.trim() ?? '';
  }

  String _summaryLabel(S s) {
    if (isCustomMarket) {
      return '${_resolvedBetType} · ${_resolvedBetValue}';
    }
    final type = _currentType;
    final typeLabel = type?.label(s.isFa) ?? selectedBetType;
    if (selectedBetValue != null) {
      final value = BetCatalog.findValue(
        type!,
        selectedBetValue!,
        homeTeam: widget.match.homeTeam,
        awayTeam: widget.match.awayTeam,
      );
      if (value != null) return '$typeLabel · ${value.label(s.isFa)}';
    }
    if (customLineCtrl.text.trim().isNotEmpty) {
      return '$typeLabel · ${customLineCtrl.text.trim()}';
    }
    return typeLabel;
  }

  @override
  void dispose() {
    oddsCtrl.dispose();
    analysisCtrl.dispose();
    customTypeCtrl.dispose();
    customValueCtrl.dispose();
    customLineCtrl.dispose();
    super.dispose();
  }

  bool _validateBeforeSubmit(S s) {
    if (!_formKey.currentState!.validate()) return false;

    if (_resolvedBetType.isEmpty) {
      _showError(s.betTypeRequired);
      return false;
    }
    if (_resolvedBetValue.isEmpty) {
      _showError(s.predictionRequired);
      return false;
    }
    if (oddsCtrl.text.trim().isEmpty) {
      _showError(s.oddsRequired);
      return false;
    }
    final parsedOdds = double.tryParse(oddsCtrl.text.trim());
    if (parsedOdds == null) {
      _showError(s.oddsInvalid);
      return false;
    }
    if (parsedOdds <= 1) {
      _showError(s.oddsMustBeGt1);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  String _settlementLabel(S s, String dbValue) {
    switch (dbValue) {
      case 'Including Extra Time':
        return s.settlementExtra;
      case 'Qualification':
        return s.settlementQualification;
      case 'Regular Time':
      default:
        return s.settlementRegular;
    }
  }

  String _statusLabel(S s, String status) {
    switch (status.toUpperCase()) {
      case 'WIN':
        return s.statusWin;
      case 'LOSE':
        return s.statusLose;
      case 'VOID':
        return s.statusVoid;
      case 'PENDING':
      default:
        return s.pending;
    }
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AdminTheme.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _submit(BuildContext context, S s) async {
    if (!_validateBeforeSubmit(s)) return;

    final parsedOdds = double.tryParse(oddsCtrl.text.trim());

    try {
      await context.read<AddSignalCubit>().submit(
            matchId: widget.match.id,
            betType: _resolvedBetType,
            betValue: _resolvedBetValue,
            signalType: signalType,
            status: signalStatus,
            leagueName: widget.match.leagueName,
            gameDate: widget.match.game_date,
            sport: SportTypeExtension.normalize(widget.match.sport),
            odds: parsedOdds,
            settlementType: settlementType,
            isFeatured: isFeatured,
            analysis: signalType == 'VIP'
                ? (analysisCtrl.text.trim().isEmpty
                    ? null
                    : analysisCtrl.text.trim())
                : null,
            isNew: widget.signal == null,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.signalSaved)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.error}: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isEdit = widget.signal != null;
    final top = MediaQuery.paddingOf(context).top;
    final allowCustomLine =
        selectedBetType == 'OVER' || selectedBetType == 'UNDER';
    final sport = SportTypeExtension.fromDb(widget.match.sport);

    return BlocProvider(
      create: (_) => sl<AddSignalCubit>(),
      child: Scaffold(
        backgroundColor: AdminTheme.navy,
        body: BlocBuilder<AddSignalCubit, bool>(
          builder: (context, loading) {
            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 20),
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              style: IconButton.styleFrom(
                                backgroundColor: AdminTheme.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.welcomeAdmin,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isEdit ? s.editSignal : s.createSignal,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _MatchHeroCard(
                          home: widget.match.homeTeam,
                          away: widget.match.awayTeam,
                          league: widget.match.leagueName,
                          date: widget.match.game_date,
                          display: widget.match.display,
                          status: widget.match.status,
                          sportLabel: sport != null
                              ? s.sportName(sport)
                              : widget.match.sport,
                        ),
                        const SizedBox(height: 14),
                        _SectionCard(
                          title: s.betType,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.betSelectHint,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _types.map((t) {
                                  return _Chip(
                                    label: t.label(s.isFa),
                                    selected: selectedBetType == t.id,
                                    onTap: () => _onBetTypeChanged(t.id),
                                  );
                                }).toList(),
                              ),
                              if (isCustomMarket) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: customTypeCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  decoration:
                                      _fieldDecoration(hint: s.customBetType),
                                  validator: (v) {
                                    if (!isCustomMarket) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return s.betTypeRequired;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: s.prediction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCustomMarket)
                                TextFormField(
                                  controller: customValueCtrl,
                                  style: const TextStyle(color: Colors.white),
                                  decoration:
                                      _fieldDecoration(hint: s.customBetValue),
                                  validator: (v) {
                                    if (!isCustomMarket) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return s.predictionRequired;
                                    }
                                    return null;
                                  },
                                )
                              else ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _currentValues.map((v) {
                                    final selected =
                                        selectedBetValue == v.id &&
                                            customLineCtrl.text.isEmpty;
                                    return _Chip(
                                      label: v.label(s.isFa),
                                      selected: selected,
                                      onTap: () => setState(() {
                                        selectedBetValue = v.id;
                                        customLineCtrl.clear();
                                      }),
                                    );
                                  }).toList(),
                                ),
                                if (allowCustomLine) ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: customLineCtrl,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    onChanged: (v) {
                                      if (v.trim().isNotEmpty) {
                                        setState(
                                          () => selectedBetValue = null,
                                        );
                                      }
                                    },
                                    decoration: _fieldDecoration(
                                      hint: s.customLineHint,
                                    ),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AdminTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color:
                                        AdminTheme.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.selectedSummary,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _summaryLabel(s),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      s.isFa
                                          ? 'کد ذخیره‌شده: ${_resolvedBetType} / ${_resolvedBetValue.isEmpty ? '—' : _resolvedBetValue}'
                                          : 'Stored: ${_resolvedBetType} / ${_resolvedBetValue.isEmpty ? '—' : _resolvedBetValue}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: s.signalType,
                          child: Row(
                            children: [
                              Expanded(
                                child: _Chip(
                                  label: 'FREE',
                                  selected: signalType == 'FREE',
                                  onTap: () =>
                                      setState(() => signalType = 'FREE'),
                                  expand: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _Chip(
                                  label: 'VIP',
                                  selected: signalType == 'VIP',
                                  onTap: () =>
                                      setState(() => signalType = 'VIP'),
                                  expand: true,
                                  selectedColor: AdminTheme.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (signalType == 'VIP') ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: s.vipAnalysis,
                            child: TextFormField(
                              controller: analysisCtrl,
                              maxLines: 4,
                              style: const TextStyle(color: Colors.white),
                              decoration:
                                  _fieldDecoration(hint: s.vipAnalysisHint),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: s.showOnPicks,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              title: Text(
                                s.featuredPick,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                s.featuredPickHint,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              value: isFeatured,
                              activeColor: AdminTheme.primary,
                              onChanged: (v) =>
                                  setState(() => isFeatured = v),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: s.odds,
                          child: TextFormField(
                            controller: oddsCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return s.oddsRequired;
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null) return s.oddsInvalid;
                              if (parsed <= 1) return s.oddsMustBeGt1;
                              return null;
                            },
                            decoration: _fieldDecoration(hint: s.oddsHint),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: s.settlementType,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _settlementDb.map((v) {
                              return _Chip(
                                label: _settlementLabel(s, v),
                                selected: settlementType == v,
                                onTap: () =>
                                    setState(() => settlementType = v),
                              );
                            }).toList(),
                          ),
                        ),
                        if (isEdit) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: s.matchResult,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'PENDING',
                                'WIN',
                                'LOSE',
                                'VOID',
                              ].map((v) {
                                return _Chip(
                                  label: _statusLabel(s, v),
                                  selected: signalStatus == v,
                                  onTap: () =>
                                      setState(() => signalStatus = v),
                                  selectedColor: v == 'WIN'
                                      ? Colors.green
                                      : v == 'LOSE'
                                          ? Colors.redAccent
                                          : v == 'VOID'
                                              ? Colors.blueGrey
                                              : AdminTheme.primary,
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AdminTheme.primary,
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _submit(context, s),
                              child: Text(
                                s.submitSignal,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MatchHeroCard extends StatelessWidget {
  final String home;
  final String away;
  final String league;
  final String date;
  final String display;
  final String status;
  final String sportLabel;

  const _MatchHeroCard({
    required this.home,
    required this.away,
    required this.league,
    required this.date,
    required this.display,
    required this.status,
    required this.sportLabel,
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'live':
        return const Color(0xFFFF5252);
      case 'finished':
        return Colors.white38;
      default:
        return AdminTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLive = status.toLowerCase() == 'live';

    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isLive) ...[
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _statusColor.withOpacity(0.6),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            [
                              if (sportLabel.trim().isNotEmpty) sportLabel,
                              if (league.trim().isNotEmpty) league,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                home,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                away,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          constraints: const BoxConstraints(minWidth: 64),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                display.isEmpty ? '—' : display,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isLive
                                      ? AdminTheme.gold
                                      : AdminTheme.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;
  final Color selectedColor;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = false,
    this.selectedColor = AdminTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: expand ? double.infinity : null,
          alignment: expand ? Alignment.center : null,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? selectedColor
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );

    if (!expand) return child;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
