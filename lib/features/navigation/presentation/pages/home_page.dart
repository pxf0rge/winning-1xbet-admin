import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/constants/service_locator.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/create_match_cubit.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/match_cubit.dart';
import 'package:w1xbet_admin/features/matches/presentation/pages/create_match_page.dart';
import 'package:w1xbet_admin/features/matches/presentation/pages/matches_page.dart';
import 'package:w1xbet_admin/features/navigation/presentation/pages/settings_page.dart';
import 'package:w1xbet_admin/features/navigation/presentation/pages/signals_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const MatchesPage(),
    const SignalsPage(),
    const SettingsPage(),
  ];

  Future<void> _openCreateMatch() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => sl<CreateMatchCubit>(),
          child: const CreateMatchPage(),
        ),
      ),
    );
    if (changed == true && mounted) {
      context.read<MatchCubit>().loadMatches();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final onHome = _selectedIndex == 0;

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: onHome
          ? FloatingActionButton.extended(
              onPressed: _openCreateMatch,
              backgroundColor: AdminTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text(s.createMatch),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        index: _selectedIndex,
        onChanged: (i) => setState(() => _selectedIndex = i),
        items: [
          _NavItem(icon: Icons.sports_soccer_rounded, label: s.home),
          _NavItem(icon: Icons.bolt_rounded, label: s.signals),
          _NavItem(icon: Icons.tune_rounded, label: s.settings),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<_NavItem> items;

  const _BottomNav({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.navy,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AdminTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = index == i;
                final item = items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AdminTheme.primary.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AdminTheme.primary
                                : Colors.white38,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AdminTheme.primary
                                  : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
