import 'package:careconnect_app/core/enums/status_enums.dart';

class UserModel {
  final String id;
  final String nome;
  final String? email;
  final String? avatarUrl;
  final UserType? userType;
  final String? phoneNumber;
  final String? city;
  final String? state;
  final String? fullAddress;

  UserModel({
    required this.id,
    required this.nome,
    this.email,
    this.avatarUrl,
    this.userType,
    this.phoneNumber,
    this.city,
    this.state,
    this.fullAddress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'avatar_url': avatarUrl,
      'tipo': userType?.toDb,
      'phoneNumber': phoneNumber,
      'city': city,
      'state': state,
      'full_address': fullAddress,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userTypeString = json['tipo'] as String?;

    return UserModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Usuário',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      userType: userTypeString != null
          ? UserType.fromString(userTypeString)
          : null,

      phoneNumber: json['phoneNumber'],
      city: json['city'],
      state: json['state'],
      fullAddress: json['full_address'],
    );
  }

  factory UserModel.simple(Map<String, dynamic>? json) {
    if (json == null) {
      return UserModel(id: '', nome: 'Usuário Inválido');
    }
    return UserModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Usuário',
      avatarUrl: json['avatar_url'],
    );
  }
}
