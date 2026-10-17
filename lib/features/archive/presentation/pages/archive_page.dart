import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/features/signals/data/models/signal_model.dart';

import '../cubit/archive_cubit.dart';
import '../../../signals/presentation/pages/add_signal_page.dart';
import '../../../matches/presentation/cubit/match_cubit.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  @override
  void initState() {
    super.initState();
    context.read<ArchiveCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          title: const Text(
            "Archive",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.black87,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "FREE"),
              Tab(text: "VIP"),
            ],
          ),
        ),
        body: BlocBuilder<ArchiveCubit, ArchiveState>(
          builder: (context, state) {
            if (state is ArchiveLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (state is ArchiveError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.read<ArchiveCubit>().load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final signals =
                state is ArchiveLoaded ? state.signals : <SignalModel>[];

            final freeSignals =
                signals.where((e) => e.signalType == "FREE").toList();
            final vipSignals =
                signals.where((e) => e.signalType == "VIP").toList();

            return TabBarView(
              children: [_buildList(freeSignals), _buildList(vipSignals)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<SignalModel> list) {
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              "No archive data",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () => context.read<ArchiveCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = list[index];
          final isWin = s.status == "WIN";

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final match = context.read<MatchCubit>().getMatchById(
                s.matchId.toString(),
              );
              if (match != null) {
                final changed = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSignalPage(match: match, signal: s),
                  ),
                );

                if (changed == true && mounted) {
                  context.read<ArchiveCubit>().load();
                }
              }
            },
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.09),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${s.leagueName} • ${s.sport}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.betValue,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${s.betType} • ${s.gameDate}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isWin
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.status,
                      style: TextStyle(
                        color: isWin ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
