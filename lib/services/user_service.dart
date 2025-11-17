import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef UserProfileData = (
  UserModel userModel,
  CaregiverProfile? caregiverProfile,
  Map<String, dynamic> userMap,
  Map<String, dynamic>? caregiverMap,
);

class UserService {
  final AuthService _authService = AuthService();

  Future<UserProfileData> getFullUserProfileAndMaps() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      final userDataMap = await supabase
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .single();
      final userModel = UserModel.fromJson(userDataMap);

      CaregiverProfile? caregiverProfile;
      Map<String, dynamic>? caregiverDataMap;

      if (userModel.userType == UserType.cuidador) {
        caregiverDataMap = await supabase
            .from('cuidadores')
            .select('*, usuarios!inner(*)')
            .eq('usuario_id', user.id)
            .single();
        caregiverProfile = CaregiverProfile.fromSupabase(caregiverDataMap);
      }
      return (userModel, caregiverProfile, userDataMap, caregiverDataMap);
    } catch (e) {
      throw Exception('Erro ao carregar dados do usuário: $e');
    }
  }

  Stream<UserModel?> getUserProfileStream(String userId) {
    return supabase
        .from('usuarios')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((list) {
          if (list.isEmpty) return null;
          return UserModel.fromJson(list.first);
        });
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await supabase.from('usuarios').update(data).eq('id', userId);

      if (data.containsKey('profile_completed')) {
        final user = _authService.currentUser;
        if (user != null) {
          await supabase.auth.updateUser(
            UserAttributes(
              data: {
                ...?(user.userMetadata),
                'profile_completed': data['profile_completed'],
              },
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Erro ao atualizar dados do usuário: $e');
    }
  }
}
