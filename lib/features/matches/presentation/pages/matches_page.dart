import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/constants/service_locator.dart';
import 'package:w1xbet_admin/core/constants/sport_enum.dart';
import 'package:w1xbet_admin/core/constants/status_enum.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/match.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/create_match_cubit.dart';
import 'package:w1xbet_admin/features/matches/presentation/pages/create_match_page.dart';
import 'package:w1xbet_admin/features/signals/presentation/pages/add_signal_page.dart';
import '../cubit/match_cubit.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final TextEditingController searchCtrl = TextEditingController();

  String query = '';
  SportType selectedSport = SportType.all;
  MatchStatusFilter selectedStatus = MatchStatusFilter.upcoming;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<MatchCubit>();
    if (cubit.state is! MatchLoaded) {
      cubit.loadMatches();
    }
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String _sportLabel(S s, SportType sport) => s.sportName(sport);

  String _statusFilterLabel(S s, MatchStatusFilter status) =>
      s.statusFilter(status);

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return const Color(0xFFFF5252);
      case 'finished':
        return Colors.white38;
      case 'upcoming':
      default:
        return AdminTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: BlocBuilder<MatchCubit, MatchState>(
        builder: (context, state) {
          final matches =
              state is MatchLoaded ? state.matches : const <Match>[];

          final liveCount =
              matches.where((m) => m.status.toLowerCase() == 'live').length;
          final upcomingCount = matches
              .where((m) => m.status.toLowerCase() == 'upcoming')
              .length;
          final finishedCount = matches
              .where((m) => m.status.toLowerCase() == 'finished')
              .length;

          final filtered = matches.where((m) {
            final matchesSearch =
                '${m.homeTeam} ${m.awayTeam}'.toLowerCase().contains(query);
            final matchesSport = selectedSport == SportType.all
                ? true
                : SportTypeExtension.normalize(m.sport) == selectedSport.dbKey;
            final matchesStatus = selectedStatus == MatchStatusFilter.all
                ? true
                : m.status.toLowerCase() ==
                    selectedStatus.label.toLowerCase();
            return matchesSearch && matchesSport && matchesStatus;
          }).toList();

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
                            s.matchesToday,
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
                      onPressed: () =>
                          context.read<MatchCubit>().loadMatches(),
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
                        label: s.live,
                        value: '$liveCount',
                        color: const Color(0xFFFF5252),
                        selected: selectedStatus == MatchStatusFilter.live,
                        onTap: () => setState(() {
                          selectedStatus =
                              selectedStatus == MatchStatusFilter.live
                                  ? MatchStatusFilter.all
                                  : MatchStatusFilter.live;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: s.upcoming,
                        value: '$upcomingCount',
                        color: AdminTheme.primary,
                        selected:
                            selectedStatus == MatchStatusFilter.upcoming,
                        onTap: () => setState(() {
                          selectedStatus =
                              selectedStatus == MatchStatusFilter.upcoming
                                  ? MatchStatusFilter.all
                                  : MatchStatusFilter.upcoming;
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatPill(
                        label: s.finished,
                        value: '$finishedCount',
                        color: AdminTheme.gold,
                        selected:
                            selectedStatus == MatchStatusFilter.finished,
                        onTap: () => setState(() {
                          selectedStatus =
                              selectedStatus == MatchStatusFilter.finished
                                  ? MatchStatusFilter.all
                                  : MatchStatusFilter.finished;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  onChanged: (val) =>
                      setState(() => query = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: s.searchTeam,
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                    ),
                    filled: true,
                    fillColor: AdminTheme.card,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AdminTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: SportType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final sport = SportType.values[i];
                    final selected = selectedSport == sport;
                    return _FilterChip(
                      label: _sportLabel(s, sport),
                      selected: selected,
                      onTap: () => setState(() => selectedSport = sport),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: MatchStatusFilter.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final status = MatchStatusFilter.values[i];
                    final selected = selectedStatus == status;
                    return _FilterChip(
                      label: _statusFilterLabel(s, status),
                      selected: selected,
                      onTap: () => setState(() => selectedStatus = status),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(s, state, filtered)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(S s, MatchState state, List<Match> filtered) {
    if (state is MatchLoading || state is MatchInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AdminTheme.primary),
      );
    }

    if (state is MatchError) {
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
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<MatchCubit>().loadMatches(),
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
      onRefresh: () => context.read<MatchCubit>().loadMatches(),
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Icon(
                  Icons.sports_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    s.noMatches,
                    style: const TextStyle(color: Colors.white54, fontSize: 15),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final m = filtered[i];
                return _MatchCard(
                  match: m,
                  statusColor: _statusColor(m.status),
                  statusLabel: () {
                    switch (m.status.toLowerCase()) {
                      case 'live':
                        return s.live;
                      case 'finished':
                        return s.finished;
                      case 'upcoming':
                        return s.upcoming;
                      default:
                        return m.status;
                    }
                  }(),
                  manualLabel: s.manual,
                  tapHint: s.tapToSignal,
                  onTap: () async {
                    final cubit = context.read<MatchCubit>();
                    final signals = await cubit.getMatchSignals(m.id);
                    if (!mounted) return;

                    final changed = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSignalPage(
                          match: m,
                          signal: signals.isEmpty ? null : signals.first,
                        ),
                      ),
                    );
                    if (changed == true && mounted) {
                      context.read<MatchCubit>().loadMatches();
                    }
                  },
                  onEdit: m.isManual
                      ? () async {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (_) => sl<CreateMatchCubit>(),
                                child: CreateMatchPage(editMatch: m),
                              ),
                            ),
                          );
                          if (changed == true && mounted) {
                            context.read<MatchCubit>().loadMatches();
                          }
                        }
                      : null,
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
              color: selected ? color.withOpacity(0.55) : Colors.white.withOpacity(0.06),
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
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white,
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
            color: selected
                ? AdminTheme.primary
                : AdminTheme.card,
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

class _MatchCard extends StatelessWidget {
  final Match match;
  final Color statusColor;
  final String statusLabel;
  final String manualLabel;
  final String tapHint;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const _MatchCard({
    required this.match,
    required this.statusColor,
    required this.statusLabel,
    required this.manualLabel,
    required this.tapHint,
    required this.onTap,
    this.onEdit,
  });

  String get _sportLabel {
    final t = match.sport;
    if (t.isEmpty) return '';
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final isLive = match.status.toLowerCase() == 'live';

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
                            if (isLive) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
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
                                statusLabel.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                [
                                  _sportLabel,
                                  if (match.leagueLine.isNotEmpty)
                                    match.leagueLine,
                                  if (match.isManual) manualLabel,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (onEdit != null)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: onEdit,
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Colors.white54,
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
                                    match.homeTeam,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    match.awayTeam,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
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
                                    match.display,
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
                                    match.game_date,
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
                        const SizedBox(height: 10),
                        Text(
                          tapHint,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.28),
                            fontSize: 11,
                          ),
                        ),
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
