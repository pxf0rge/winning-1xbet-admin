import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/features/auth/presentation/pages/login_page.dart';
import 'package:w1xbet_admin/features/splash/presentation/pages/splash_page.dart';

/// Reacts to Supabase auth session changes (login / logout).
/// Requires app_metadata.role == admin.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _ensureAdminSession();
  }

  Future<void> _ensureAdminSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      await Supabase.instance.client.auth.refreshSession();
    } catch (_) {}
    final role =
        Supabase.instance.client.auth.currentUser?.appMetadata['role']?.toString();
    if (role != 'admin') {
      await Supabase.instance.client.auth.signOut();
    }
  }

  bool _isAdmin(Session? session) {
    if (session == null) return false;
    return session.user.appMetadata['role']?.toString() == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (_isAdmin(session)) {
          return const SplashPage();
        }
        return const LoginPage();
      },
    );
  }
}
