import 'package:careconnect_app/core/enums/user_type.dart';

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      nome: json['nome'] ?? 'Usuário',
      email: json['email'],
      avatarUrl: json['avatar_url'],
      userType: json['tipo'],
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
