import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/core/constants/service_locator.dart';
import 'package:w1xbet_admin/core/l10n/admin_l10n.dart';
import 'package:w1xbet_admin/core/theme/admin_theme.dart';
import 'package:w1xbet_admin/features/matches/presentation/cubit/create_match_cubit.dart';
import 'package:w1xbet_admin/features/matches/presentation/pages/create_match_page.dart';
import 'package:w1xbet_admin/features/notifications/presentation/pages/send_notification_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String userEmail;
  String versionLabel = '—';
  bool? apiConnected;
  int preMatchMinutes = 30;
  bool preMatchEnabled = true;
  bool saving = false;
  bool syncingSports = false;
  bool syncingTennis = false;
  Map<String, dynamic>? apiSportsStatus;
  Map<String, dynamic>? tennisStatus;

  static const _minutePresets = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'Admin';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _loadVersion(),
      _checkApi(),
      _loadNotificationSettings(),
      _loadApiSportsStatus(),
    ]);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => versionLabel = '${info.version}+${info.buildNumber}');
      }
    } catch (_) {}
  }

  Future<void> _checkApi() async {
    try {
      await Supabase.instance.client.from('signals').select('id').limit(1);
      if (mounted) setState(() => apiConnected = true);
    } catch (_) {
      if (mounted) setState(() => apiConnected = false);
    }
  }

  Future<void> _loadApiSportsStatus() async {
    try {
      final res =
          await Supabase.instance.client.rpc('get_api_sports_status');
      if (!mounted) return;
      if (res is Map) {
        final map = Map<String, dynamic>.from(res);
        setState(() {
          apiSportsStatus = map;
          final t = map['tennis'];
          tennisStatus = t is Map ? Map<String, dynamic>.from(t) : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _runSportsSync() async {
    setState(() => syncingSports = true);
    final s = S.of(context);
    try {
      await Supabase.instance.client.rpc('trigger_sports_sync');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isFa ? 'همگام‌سازی صف شد' : 'Sync queued',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await _loadApiSportsStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.error}: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => syncingSports = false);
    }
  }

  Future<void> _runTennisSync() async {
    setState(() => syncingTennis = true);
    final s = S.of(context);
    try {
      await Supabase.instance.client.rpc('trigger_tennis_sync');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isFa ? 'همگام‌سازی تنیس صف شد' : 'Tennis sync queued',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await _loadApiSportsStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.error}: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => syncingTennis = false);
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final res = await Supabase.instance.client
          .from('admin_settings')
          .select()
          .eq('key', 'notifications')
          .maybeSingle();
      if (res != null && res['value'] is Map) {
        final v = Map<String, dynamic>.from(res['value'] as Map);
        setState(() {
          preMatchMinutes = (v['pre_match_minutes'] as num?)?.toInt() ?? 30;
          preMatchEnabled = v['enabled'] != false;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => saving = true);
    final s = S.of(context);
    try {
      await Supabase.instance.client.from('admin_settings').upsert({
        'key': 'notifications',
        'value': {
          'pre_match_minutes': preMatchMinutes,
          'enabled': preMatchEnabled,
        },
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.saved)),
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
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _relativeTime(S s, String? iso) {
    if (iso == null || iso.isEmpty || iso == '—') return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inSeconds < 60) {
      return s.isFa ? 'همین الان' : 'Just now';
    }
    if (diff.inMinutes < 60) {
      return s.isFa
          ? '${diff.inMinutes} دقیقه پیش'
          : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return s.isFa ? '${diff.inHours} ساعت پیش' : '${diff.inHours}h ago';
    }
    return s.isFa ? '${diff.inDays} روز پیش' : '${diff.inDays}d ago';
  }

  double _quotaProgress(Map<String, dynamic>? status) {
    if (status == null) return 0;
    final used = (status['used_today'] as num?)?.toDouble() ?? 0;
    final limit = (status['daily_limit'] as num?)?.toDouble() ?? 1;
    if (limit <= 0) return 0;
    return (used / limit).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeCubit = context.watch<LocaleCubit>();
    final top = MediaQuery.paddingOf(context).top;

    final hlUsed = apiSportsStatus?['used_today'] ?? '…';
    final hlLimit = apiSportsStatus?['daily_limit'] ?? 100;
    final hlRemaining = apiSportsStatus?['remaining'] ?? '…';
    final tnUsed = tennisStatus?['used_today'] ?? '…';
    final tnLimit = tennisStatus?['daily_limit'] ?? 100;
    final tnRemaining = tennisStatus?['remaining'] ?? '…';

    return Scaffold(
      backgroundColor: AdminTheme.navy,
      body: RefreshIndicator(
        color: AdminTheme.primary,
        backgroundColor: AdminTheme.card,
        onRefresh: _bootstrap,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, top + 8, 16, 28),
          children: [
            // —— Header ——
            Row(
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
                        s.settings,
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
                  onPressed: _bootstrap,
                  style: IconButton.styleFrom(
                    backgroundColor: AdminTheme.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // —— Profile ——
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AdminTheme.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AdminTheme.primary.withOpacity(0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AdminTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.adminAccount,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ConnectionDot(connected: apiConnected),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— General ——
            _SectionTitle(s.general),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.language,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SegmentChip(
                          label: s.persian,
                          selected: localeCubit.isFa,
                          onTap: () =>
                              localeCubit.setLocale(const Locale('fa')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SegmentChip(
                          label: s.english,
                          selected: !localeCubit.isFa,
                          onTap: () =>
                              localeCubit.setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        apiConnected == true
                            ? Icons.check_circle_rounded
                            : apiConnected == false
                                ? Icons.error_rounded
                                : Icons.hourglass_top_rounded,
                        size: 20,
                        color: apiConnected == true
                            ? Colors.green
                            : apiConnected == false
                                ? Colors.redAccent
                                : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.apiStatus,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              apiConnected == true
                                  ? 'Supabase · ${s.connected}'
                                  : apiConnected == false
                                      ? 'Supabase · ${s.disconnected}'
                                      : s.checking,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _checkApi,
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— Data sync ——
            _SectionTitle(s.dataSync),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProviderHeader(
                    title: 'Highlightly',
                    subtitle: s.isFa
                        ? 'فوتبال · بسکتبال · هندبال · والیبال · هاکی'
                        : 'Football · Basketball · Handball · Volleyball · Hockey',
                    icon: Icons.sports_soccer_rounded,
                    accent: AdminTheme.primary,
                  ),
                  const SizedBox(height: 14),
                  _QuotaBar(
                    progress: _quotaProgress(apiSportsStatus),
                    label: s.usedToday,
                    value: '$hlUsed / $hlLimit',
                  ),
                  const SizedBox(height: 14),
                  _MetaGrid(
                    items: [
                      _MetaItem(s.remaining, '$hlRemaining'),
                      _MetaItem(
                        s.syncInterval,
                        s.isFa
                            ? 'هر ${apiSportsStatus?['interval_minutes'] ?? 120} دقیقه'
                            : 'Every ${apiSportsStatus?['interval_minutes'] ?? 120} min',
                      ),
                      _MetaItem(
                        s.lastRequest,
                        _relativeTime(
                          s,
                          apiSportsStatus?['last_request_at']?.toString(),
                        ),
                      ),
                      _MetaItem(
                        s.lastRequestOk,
                        apiSportsStatus?['last_request_ok'] == null
                            ? '—'
                            : (apiSportsStatus!['last_request_ok'] == true
                                ? s.success
                                : s.failed),
                        valueColor:
                            apiSportsStatus?['last_request_ok'] == true
                                ? Colors.green
                                : apiSportsStatus?['last_request_ok'] == false
                                    ? Colors.redAccent
                                    : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.isFa
                        ? 'همگام‌سازی سرور هر ۲ ساعت · سقف ۱۰۰ درخواست/روز'
                        : 'Server sync every 2h · 100 req/day limit',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: syncingSports ? null : _runSportsSync,
                      icon: syncingSports
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(s.syncNow),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProviderHeader(
                    title: 'Live Tennis',
                    subtitle: s.isFa
                        ? 'کرون جدا · هر ۳ دقیقه'
                        : 'Dedicated cron · every 3 min',
                    icon: Icons.sports_tennis_rounded,
                    accent: AdminTheme.gold,
                  ),
                  const SizedBox(height: 14),
                  _QuotaBar(
                    progress: _quotaProgress(tennisStatus),
                    label: s.usedToday,
                    value: '$tnUsed / $tnLimit',
                    color: AdminTheme.gold,
                  ),
                  const SizedBox(height: 14),
                  _MetaGrid(
                    items: [
                      _MetaItem(s.remaining, '$tnRemaining'),
                      _MetaItem(
                        s.syncInterval,
                        s.isFa
                            ? 'هر ${tennisStatus?['interval_minutes'] ?? 30} دقیقه'
                            : 'Every ${tennisStatus?['interval_minutes'] ?? 30} min',
                      ),
                      _MetaItem(
                        s.lastRequest,
                        _relativeTime(
                          s,
                          tennisStatus?['last_request_at']?.toString(),
                        ),
                      ),
                      _MetaItem(
                        s.lastRequestOk,
                        tennisStatus?['last_request_ok'] == null
                            ? '—'
                            : (tennisStatus!['last_request_ok'] == true
                                ? s.success
                                : s.failed),
                        valueColor: tennisStatus?['last_request_ok'] == true
                            ? Colors.green
                            : tennisStatus?['last_request_ok'] == false
                                ? Colors.redAccent
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.isFa
                        ? 'سقف ۱۰۰/روز · هر ۳۰ دقیقه · live + upcoming ≈ ۹۶ درخواست'
                        : 'Quota 100/day · every 30 min · live + upcoming ≈ 96 req',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminTheme.gold,
                        side: BorderSide(
                          color: AdminTheme.gold.withOpacity(0.45),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: syncingTennis ? null : _runTennisSync,
                      icon: syncingTennis
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AdminTheme.gold,
                              ),
                            )
                          : const Icon(Icons.sports_tennis_rounded),
                      label: Text(s.syncTennisNow),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— Notifications ——
            _SectionTitle(s.sendNotification),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      value: preMatchEnabled,
                      onChanged: (v) => setState(() => preMatchEnabled = v),
                      activeColor: AdminTheme.primary,
                      title: Text(
                        s.preMatchNotifications,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        s.isFa
                            ? 'ارسال خودکار قبل از شروع مسابقه'
                            : 'Auto-send before kickoff',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${s.minutesBeforeKickoff}: $preMatchMinutes',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _minutePresets.map((m) {
                      final selected = preMatchMinutes == m;
                      return _SegmentChip(
                        label: '$m',
                        selected: selected,
                        onTap: () => setState(() => preMatchMinutes = m),
                        compact: true,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.remove_rounded,
                        onTap: preMatchMinutes > 5
                            ? () => setState(() => preMatchMinutes -= 5)
                            : null,
                      ),
                      Expanded(
                        child: Text(
                          '$preMatchMinutes',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _RoundIconButton(
                        icon: Icons.add_rounded,
                        onTap: () => setState(() => preMatchMinutes += 5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveNotificationSettings,
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(s.saveNotificationSettings),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— Tools ——
            _SectionTitle(s.tools),
            const SizedBox(height: 10),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.notifications_active_rounded,
                    label: s.sendNotification,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SendNotificationPage(),
                        ),
                      );
                    },
                  ),
                  _divider(),
                  _ActionTile(
                    icon: Icons.add_box_rounded,
                    label: s.manualCreate,
                    onTap: () async {
                      final changed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (_) => sl<CreateMatchCubit>(),
                            child: const CreateMatchPage(),
                          ),
                        ),
                      );
                      if (changed == true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.saved)),
                        );
                      }
                    },
                  ),
                  _divider(),
                  _ActionTile(
                    icon: Icons.play_arrow_rounded,
                    label: s.runPreMatchNow,
                    onTap: () => _confirmThenRun(
                      title: s.runPreMatchNow,
                      description: s.runPreMatchNowDesc,
                      action: _runPreMatchNotifications,
                    ),
                  ),
                  _divider(),
                  _ActionTile(
                    icon: Icons.cleaning_services_rounded,
                    label: s.cleanupOldMatches,
                    onTap: () => _confirmThenRun(
                      title: s.cleanupOldMatches,
                      description: s.cleanupOldMatchesDesc,
                      action: _cleanupOldMatches,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— Account ——
            _SectionTitle(s.account),
            const SizedBox(height: 10),
            _Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.lock_rounded,
                    label: s.changePassword,
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                  _divider(),
                  _ActionTile(
                    icon: Icons.logout_rounded,
                    label: s.logout,
                    color: Colors.redAccent,
                    onTap: () => _showLogoutConfirm(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // —— About ——
            _SectionTitle(s.about),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _AboutRow(s.version, versionLabel),
                  const SizedBox(height: 12),
                  _AboutRow('Platform', 'Flutter'),
                  const SizedBox(height: 12),
                  _AboutRow('Database', 'Supabase'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withOpacity(0.05),
        indent: 56,
      );

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    var isLoading = false;
    final s = S.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          backgroundColor: AdminTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            s.changePassword,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: s.newPassword),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(hintText: s.confirmPassword),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.passwordsMismatch)),
                        );
                        return;
                      }
                      setLocal(() => isLoading = true);
                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: newPasswordCtrl.text),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.saved)),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${s.error}: $e')),
                        );
                      } finally {
                        setLocal(() => isLoading = false);
                      }
                    },
              child: Text(s.confirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmThenRun({
    required String title,
    required String description,
    required Future<void> Function() action,
  }) async {
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          description,
          style: const TextStyle(color: Colors.white70, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.close),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.runAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await action();
    }
  }

  Future<void> _runPreMatchNotifications() async {
    final s = S.of(context);
    try {
      final res =
          await Supabase.instance.client.rpc('run_pre_match_notifications');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isFa ? 'اجرا شد: $res' : 'Ran: $res'),
        ),
      );
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

  Future<void> _cleanupOldMatches() async {
    final s = S.of(context);
    try {
      final res = await Supabase.instance.client.rpc(
        'cleanup_old_manual_matches',
        params: {'days_old': 7},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s.isFa
                ? 'حذف شد: $res مسابقه قدیمی'
                : 'Cleaned up $res old matches',
          ),
        ),
      );
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

  void _showLogoutConfirm(BuildContext context) {
    final s = S.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(s.logout, style: const TextStyle(color: Colors.white)),
        content: Text(
          s.logoutConfirm,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
            },
            child: Text(s.logout),
          ),
        ],
      ),
    );
  }
}

// ─── UI pieces ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white54,
        fontWeight: FontWeight.w700,
        fontSize: 13,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  final bool? connected;
  const _ConnectionDot({required this.connected});

  @override
  Widget build(BuildContext context) {
    final color = connected == true
        ? Colors.green
        : connected == false
            ? Colors.redAccent
            : Colors.orange;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.5), blurRadius: 8),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
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
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 12,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AdminTheme.primary
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AdminTheme.primary
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _ProviderHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotaBar extends StatelessWidget {
  final double progress;
  final String label;
  final String value;
  final Color color;

  const _QuotaBar({
    required this.progress,
    required this.label,
    required this.value,
    this.color = AdminTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.85 ? Colors.redAccent : color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaItem {
  final String label;
  final String value;
  final Color? valueColor;
  const _MetaItem(this.label, this.value, {this.valueColor});
}

class _MetaGrid extends StatelessWidget {
  final List<_MetaItem> items;
  const _MetaGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - 16 * 2 - 16 * 2 - 8) / 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  e.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: e.valueColor ?? Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(onTap == null ? 0.03 : 0.06),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AdminTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color == Colors.redAccent ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_left_rounded,
        color: Colors.white.withOpacity(0.25),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
