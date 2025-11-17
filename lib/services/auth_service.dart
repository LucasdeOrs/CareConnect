import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<User?> signUpFamily({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'nome': name.trim(),
          'tipo': 'familiar',
          'phoneNumber': phone.trim(),
          'status': 'PendenteVerificacaoEmail',
          'profile_completed': false,
        },
      );
      return res.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signUpCaregiver({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final res = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'nome': name.trim(),
          'tipo': 'cuidador',
          'phoneNumber': phone.trim(),
          'status': 'PendenteVerificacaoEmail',
          'profile_completed': false,
        },
      );
      return res.user;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'E-mail ou senha incorretos.';
      }
      if (error.message.contains('User already registered')) {
        return 'Este e-mail já está cadastrado.';
      }
      return error.message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
