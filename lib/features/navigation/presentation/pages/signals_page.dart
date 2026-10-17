import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/constants/bet_catalog.dart';
import 'package:w1xbet_admin/core/constants/sport_enum.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/match.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/match_cubit.dart';
import 'package:w1xbet_admin/features/signals/domain/entities/signal.dart';
import 'package:w1xbet_admin/features/signals/presentation/cubit/signals_cubit.dart';
import 'package:w1xbet_admin/features/signals/presentation/pages/add_signal_page.dart';

class SignalsPage extends StatefulWidget {
  const SignalsPage({super.key});

  @override
  State<SignalsPage> createState() => _SignalsPageState();
}

class _SignalsPageState extends State<SignalsPage> {
  String _typeFilter = 'FREE';

  @override
  void initState() {
    super.initState();
    final cubit = context.read<SignalsCubit>();
    if (!cubit.hasLoaded) {
      cubit.load();
    }
    cubit.startRealtime();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'WIN':
        return Colors.green;
      case 'LOSE':
        return Colors.redAccent;
      case 'VOID':
        return Colors.blueGrey;
      case 'PENDING':
      default:
        return Colors.orange;
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

  String _statusFilterLabel(S s, String f) {
    switch (f) {
      case 'PENDING':
        return s.pending;
      case 'WIN':
        return s.statusWin;
      case 'LOSE':
        return s.statusLose;
      case 'VOID':
        return s.statusVoid;
      case 'ALL':
      default:
        return s.all;
    }
  }

  Match _matchForSignal(Signal signal) {
    final fromCubit = context.read<MatchCubit>().getMatchById(
          signal.matchId.toString(),
        );
    if (fromCubit != null) return fromCubit;

    final home = (signal.homeTeam?.trim().isNotEmpty ?? false)
        ? signal.homeTeam!.trim()
        : '—';
    final away = (signal.awayTeam?.trim().isNotEmpty ?? false)
        ? signal.awayTeam!.trim()
        : '—';

    return Match(
      id: signal.matchId.toString(),
      sport: signal.sport,
      homeTeam: home,
      awayTeam: away,
      status: 'Upcoming',
      display: '-',
      game_date: signal.gameDate,
      leagueName: signal.leagueName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: BlocBuilder<SignalsCubit, SignalsState>(
        builder: (context, state) {
          final all = state.signals;
          final freeCount =
              all.where((e) => e.signalType.toUpperCase() == 'FREE').length;
          final vipCount =
              all.where((e) => e.signalType.toUpperCase() == 'VIP').length;
          final pendingCount = all
              .where((e) => e.status.toUpperCase() == 'PENDING')
              .length;
          final winCount =
              all.where((e) => e.status.toUpperCase() == 'WIN').length;
          final loseCount =
              all.where((e) => e.status.toUpperCase() == 'LOSE').length;

          final list = context.read<SignalsCubit>().filtered(type: _typeFilter);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: top + 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                child: Row(
                  children: [
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
                            s.signals,
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
                    IconButton(
                      onPressed: () => context.read<SignalsCubit>().load(),
                      style: IconButton.styleFrom(
                        backgroundColor: AdminTheme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: s.pending,
                        value: '$pendingCount',
                        color: Colors.orange,
                        selected: state.statusFilter == 'PENDING',
                        onTap: () => context
                            .read<SignalsCubit>()
                            .setStatusFilter(
                              state.statusFilter == 'PENDING'
                                  ? 'ALL'
                                  : 'PENDING',
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: s.statusWin,
                        value: '$winCount',
                        color: Colors.green,
                        selected: state.statusFilter == 'WIN',
                        onTap: () => context
                            .read<SignalsCubit>()
                            .setStatusFilter(
                              state.statusFilter == 'WIN' ? 'ALL' : 'WIN',
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: s.statusLose,
                        value: '$loseCount',
                        color: Colors.redAccent,
                        selected: state.statusFilter == 'LOSE',
                        onTap: () => context
                            .read<SignalsCubit>()
                            .setStatusFilter(
                              state.statusFilter == 'LOSE' ? 'ALL' : 'LOSE',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeToggle(
                        label: 'FREE',
                        count: freeCount,
                        selected: _typeFilter == 'FREE',
                        onTap: () => setState(() => _typeFilter = 'FREE'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeToggle(
                        label: 'VIP',
                        count: vipCount,
                        selected: _typeFilter == 'VIP',
                        accent: AdminTheme.gold,
                        onTap: () => setState(() => _typeFilter = 'VIP'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    const filters = [
                      'ALL',
                      'PENDING',
                      'WIN',
                      'LOSE',
                      'VOID',
                    ];
                    final f = filters[i];
                    final selected = state.statusFilter == f;
                    return _FilterChip(
                      label: _statusFilterLabel(s, f),
                      selected: selected,
                      onTap: () =>
                          context.read<SignalsCubit>().setStatusFilter(f),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(s, state, list)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(S s, SignalsState state, List<Signal> list) {
    if (state.loading && state.signals.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      );
    }

    if (state.error != null && state.signals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Colors.white.withOpacity(0.35),
              ),
              const SizedBox(height: 12),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<SignalsCubit>().load(),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AdminTheme.primary,
      backgroundColor: AdminTheme.card,
      onRefresh: () => context.read<SignalsCubit>().load(),
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.bolt_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    s.noSignals,
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final signal = list[index];
                return _SignalCard(
                  signal: signal,
                  statusColor: _statusColor(signal.status),
                  statusLabel: _statusLabel(s, signal.status),
                  betLabel: BetCatalog.formatBetLabel(
                    betType: signal.betType,
                    betValue: signal.betValue,
                    isFa: s.isFa,
                    homeTeam: signal.homeTeam ?? '',
                    awayTeam: signal.awayTeam ?? '',
                    sport: signal.sport,
                  ),
                  unknownMatch:
                      s.isFa ? 'مسابقه نامشخص' : 'Unknown match',
                  oddsPrefix: s.isFa ? 'ضریب' : '@',
                  sportLabel: () {
                    final sport = SportTypeExtension.fromDb(signal.sport);
                    return sport != null ? s.sportName(sport) : signal.sport;
                  }(),
                  onTap: () async {
                    final match = _matchForSignal(signal);
                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSignalPage(
                          match: match,
                          signal: signal,
                        ),
                      ),
                    );
                    if (changed == true && mounted) {
                      context.read<SignalsCubit>().load();
                    }
                  },
                );
              },
            ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.18) : AdminTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color.withOpacity(0.55)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  const _TypeToggle({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.accent = AdminTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.18) : AdminTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? accent : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AdminTheme.primary : AdminTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AdminTheme.primary
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final Signal signal;
  final Color statusColor;
  final String statusLabel;
  final String betLabel;
  final String unknownMatch;
  final String oddsPrefix;
  final String sportLabel;
  final VoidCallback onTap;

  const _SignalCard({
    required this.signal,
    required this.statusColor,
    required this.statusLabel,
    required this.betLabel,
    required this.unknownMatch,
    required this.oddsPrefix,
    required this.sportLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final home = signal.homeTeam?.trim() ?? '';
    final away = signal.awayTeam?.trim() ?? '';
    final hasTeams = home.isNotEmpty && away.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
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
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: signal.signalType.toUpperCase() == 'VIP'
                                    ? AdminTheme.gold.withOpacity(0.15)
                                    : AdminTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                signal.signalType.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      signal.signalType.toUpperCase() == 'VIP'
                                          ? AdminTheme.gold
                                          : AdminTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                [
                                  if (sportLabel.trim().isNotEmpty) sportLabel,
                                  if (signal.leagueName.trim().isNotEmpty)
                                    signal.leagueName.trim(),
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
                        if (hasTeams) ...[
                          Text(
                            home,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            away,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ] else
                          Text(
                            signal.matchTitle.isNotEmpty
                                ? signal.matchTitle
                                : unknownMatch,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          signal.odds != null
                              ? '$betLabel · $oddsPrefix ${signal.odds}'
                              : betLabel,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        if (signal.gameDate.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            signal.gameDate,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
