import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:w1xbet_admin/features/auth/domain/usecases/login_usecase.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {}

class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String msg;
  AuthError(this.msg);
}

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;

  AuthCubit(this.loginUseCase) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    try {
      if (!isClosed) emit(AuthLoading());
      await loginUseCase(email, password);

      final user = Supabase.instance.client.auth.currentUser;
      final role = user?.appMetadata['role']?.toString();
      if (role != 'admin') {
        await Supabase.instance.client.auth.signOut();
        if (!isClosed) {
          emit(AuthError('Access denied: admin role required. Re-login after role grant.'));
        }
        return;
      }

      if (!isClosed) emit(AuthSuccess());
    } catch (e) {
      if (!isClosed) emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!isClosed) emit(AuthLoggedOut());
  }
}
