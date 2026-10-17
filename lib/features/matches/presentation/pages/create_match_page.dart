import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:w1xbet_admin/core/constants/match_create_status.dart';
import 'package:w1xbet_admin/core/constants/sport_enum.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/create_match.dart';
import 'package:w1xbet_admin/features/matches/domain/entities/match.dart';
import 'package:w1xbet_admin/features/matches/domain/exceptions/duplicate_match_exception.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/create_match_cubit.dart';

enum MatchFormStatus { upcoming, live, finished }

class CreateMatchPage extends StatefulWidget {
  final Match? editMatch;

  const CreateMatchPage({super.key, this.editMatch});

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  late SportType selectedSport;
  late MatchFormStatus selectedStatus;

  final homeCtrl = TextEditingController();
  final awayCtrl = TextEditingController();
  final leagueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final homeScoreCtrl = TextEditingController();
  final awayScoreCtrl = TextEditingController();

  bool get isEdit => widget.editMatch != null;

  @override
  void initState() {
    super.initState();
    final m = widget.editMatch;
    selectedSport =
        SportTypeExtension.fromDb(m?.sport) ?? SportType.football;
    selectedStatus = _statusFromLabel(m?.status);
    homeCtrl.text = m?.homeTeam ?? '';
    awayCtrl.text = m?.awayTeam ?? '';
    leagueCtrl.text = m?.leagueName ?? '';
    dateCtrl.text = m?.game_date ?? '';

    if (selectedStatus == MatchFormStatus.upcoming) {
      timeCtrl.text = m?.display ?? '';
    } else if (m != null && m.display.contains('-')) {
      final parts = m.display.split('-');
      if (parts.length == 2) {
        homeScoreCtrl.text = parts[0].trim();
        awayScoreCtrl.text = parts[1].trim();
      }
    }
  }

  @override
  void dispose() {
    homeCtrl.dispose();
    awayCtrl.dispose();
    leagueCtrl.dispose();
    dateCtrl.dispose();
    timeCtrl.dispose();
    homeScoreCtrl.dispose();
    awayScoreCtrl.dispose();
    super.dispose();
  }

  MatchFormStatus _statusFromLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'live':
        return MatchFormStatus.live;
      case 'finished':
        return MatchFormStatus.finished;
      default:
        return MatchFormStatus.upcoming;
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: Column(
        children: [
          Expanded(
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
                      child: Text(
                        isEdit ? s.editMatch : s.createMatch,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isEdit)
                      IconButton(
                        onPressed: _confirmDelete,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _Card(
                  title: s.isFa ? 'ورزش' : 'Sport',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SportType.values
                        .where((e) => e != SportType.all)
                        .map((e) {
                      final selected = selectedSport == e;
                      return _Chip(
                        label: s.sportName(e),
                        selected: selected,
                        onTap: () => setState(() => selectedSport = e),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: s.isFa ? 'وضعیت' : 'Status',
                  child: Row(
                    children: [
                      Expanded(
                        child: _Chip(
                          label: s.upcoming,
                          selected:
                              selectedStatus == MatchFormStatus.upcoming,
                          onTap: () => setState(
                            () => selectedStatus = MatchFormStatus.upcoming,
                          ),
                          expand: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Chip(
                          label: s.live,
                          selected: selectedStatus == MatchFormStatus.live,
                          onTap: () => setState(
                            () => selectedStatus = MatchFormStatus.live,
                          ),
                          expand: true,
                          selectedColor: const Color(0xFFFF5252),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Chip(
                          label: s.finished,
                          selected:
                              selectedStatus == MatchFormStatus.finished,
                          onTap: () => setState(
                            () => selectedStatus = MatchFormStatus.finished,
                          ),
                          expand: true,
                          selectedColor: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: s.isFa ? 'تیم‌ها' : 'Teams',
                  child: Column(
                    children: [
                      TextField(
                        controller: homeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration(
                          hint: s.isFa ? 'تیم میزبان' : 'Home team',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: awayCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration(
                          hint: s.isFa ? 'تیم میهمان' : 'Away team',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: s.league,
                  child: TextField(
                    controller: leagueCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(
                      hint: s.isFa ? 'نام لیگ' : 'League name',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: s.date,
                  child: TextField(
                    controller: dateCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _fieldDecoration(hint: 'YYYY-MM-DD'),
                  ),
                ),
                const SizedBox(height: 12),
                _Card(
                  title: selectedStatus == MatchFormStatus.upcoming
                      ? (s.isFa ? 'ساعت (HH:mm)' : 'Time (HH:mm)')
                      : (s.isFa ? 'نتیجه' : 'Score'),
                  child: selectedStatus == MatchFormStatus.upcoming
                      ? TextField(
                          controller: timeCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration(hint: '18:30'),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: homeScoreCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  hint: s.homeTeam,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: awayScoreCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  hint: s.awayTeam,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    isEdit
                        ? (s.isFa ? 'ذخیره تغییرات' : 'Save changes')
                        : s.createMatch,
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
      ),
    );
  }

  Future<void> _submit() async {
    final s = S.of(context);
    if (homeCtrl.text.trim().isEmpty ||
        awayCtrl.text.trim().isEmpty ||
        leagueCtrl.text.trim().isEmpty ||
        dateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isFa
                ? 'تمام فیلدهای ضروری را پر کنید'
                : 'Please fill all required fields',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (selectedStatus == MatchFormStatus.upcoming &&
        timeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isFa ? 'ساعت مسابقه الزامی است' : 'Match time is required',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final match = CreateMatch(
      leagueName: leagueCtrl.text.trim(),
      sport: selectedSport.dbKey,
      homeTeam: homeCtrl.text.trim(),
      awayTeam: awayCtrl.text.trim(),
      date: dateCtrl.text.trim(),
      status: CreateMatchStatus.values[selectedStatus.index],
      time: selectedStatus == MatchFormStatus.upcoming
          ? timeCtrl.text.trim()
          : null,
      homeScore: selectedStatus != MatchFormStatus.upcoming
          ? int.tryParse(homeScoreCtrl.text.trim())
          : null,
      awayScore: selectedStatus != MatchFormStatus.upcoming
          ? int.tryParse(awayScoreCtrl.text.trim())
          : null,
    );

    try {
      final editId = isEdit ? int.tryParse(widget.editMatch!.id) : null;
      await context.read<CreateMatchCubit>().submit(match, editId: editId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? (s.isFa ? 'مسابقه به‌روز شد' : 'Match updated')
                  : (s.isFa ? 'مسابقه ایجاد شد' : 'Match created'),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } on DuplicateMatchException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.error}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          s.isFa ? 'حذف مسابقه' : 'Delete match',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          s.isFa
              ? 'این مسابقه دستی حذف شود؟ سیگنال‌های مرتبط (در صورت وجود) باطل (VOID) می‌شوند و از اپ کاربر حذف می‌گردند.'
              : 'Delete this manual match? Linked signals (if any) will be VOID and removed from the user app.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.isFa ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final id = int.parse(widget.editMatch!.id);
      await context.read<CreateMatchCubit>().deleteManual(id);
      if (mounted) Navigator.pop(context, true);
    }
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: expand ? double.infinity : null,
          alignment: expand ? Alignment.center : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
