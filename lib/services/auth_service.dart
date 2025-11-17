import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  User? get currentUser => supabase.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Falha ao realizar login: ${e.toString()}');
    }
  }

  Future<void> signUpFamily({
    required String email,
    required String password,
    required String nome,
    required String phone,
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'tipo': 'familiar',
          'phoneNumber': phone,
          'status': 'PendenteVerificacaoEmail',
          'profile_completed': false,
        },
      );
    } catch (e) {
      throw Exception('Erro no cadastro: ${e.toString()}');
    }
  }

  Future<void> signUpCaregiver({
    required String email,
    required String password,
    required String nome,
    required String phone,
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'nome': nome, 'tipo': 'cuidador', 'phoneNumber': phone},
      );
    } catch (e) {
      throw Exception('Erro no cadastro: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await supabase.from('usuarios').update(data).eq('id', userId);

      if (data.containsKey('profile_completed')) {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              ...?(currentUser?.userMetadata),
              'profile_completed': data['profile_completed'],
            },
          ),
        );
      }
    } catch (e) {
      throw Exception('Erro ao atualizar dados do usuário: $e');
    }
  }
}
