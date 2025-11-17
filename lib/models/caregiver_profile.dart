import 'package:flutter/material.dart';

class CaregiverProfile {
  String id;
  String usuario_id;
  final String nome;
  final String? avatarUrl;
  final String? city;
  final String? state;
  final List<String> especialidades;
  final double avaliacaoMedia;
  final String availabilityText;

  final String? experiencia;

  final List<Map<String, String>> certificados;

  final int experienceYears;
  final double hourlyRate;
  final String? birthDate;
  final String? profissao;
  final bool formacaoSaude;

  CaregiverProfile({
    required this.id,
    required this.usuario_id,
    required this.nome,
    this.avatarUrl,
    this.city,
    this.state,
    required this.especialidades,
    required this.avaliacaoMedia,
    required this.availabilityText,
    this.experiencia,
    this.certificados = const [],
    this.experienceYears = 0,
    this.hourlyRate = 0.0,
    this.birthDate,
    this.profissao,
    this.formacaoSaude = false,
  });

  factory CaregiverProfile.fromSupabase(Map<String, dynamic> data) {
    final usuario = data['usuarios'];
    if (usuario == null || usuario is! Map<String, dynamic>) {
      throw Exception('Dados do usuário ausentes ou em formato inválido');
    }

    final String especialidadesString = data['especialidades'] ?? '';
    final List<String> especialidadesList = especialidadesString.isNotEmpty
        ? especialidadesString.split(',').map((e) => e.trim()).toList()
        : [];

    final avaliacao = data['avaliacao_media'];
    double avaliacaoMedia = 0.0;
    if (avaliacao is num) {
      avaliacaoMedia = avaliacao.toDouble();
    } else if (avaliacao is String) {
      avaliacaoMedia = double.tryParse(avaliacao) ?? 0.0;
    }

    final List<Map<String, String>> certsParsed = [];
    final rawCerts = data['certificado_url'];

    if (rawCerts is List) {
      for (var item in rawCerts) {
        if (item is Map) {
          certsParsed.add({
            'url': item['url']?.toString() ?? '',
            'name': item['name']?.toString() ?? 'Certificado',
          });
        }
        else if (item is String) {
          certsParsed.add({
            'url': item,
            'name': 'Certificado',
          });
        }
      }
    }

    return CaregiverProfile(
      id: data['id'] ?? '',
      usuario_id: usuario['usuario_id'] ?? '',
      nome: usuario['nome'] ?? 'Nome não informado',
      avatarUrl: usuario['avatar_url'],
      city: usuario['city'],
      state: usuario['state'],
      especialidades: especialidadesList,
      avaliacaoMedia: avaliacaoMedia,
      availabilityText: data['availability'] ?? 'Disponível',
      experiencia: data['experiencia'],
      certificados: certsParsed,
      experienceYears: (data['experience_years'] ?? 0) as int,
      hourlyRate: ((data['hourly_rate'] ?? 0.0) as num).toDouble(),
      birthDate: usuario['birthDate'],
      profissao: data['profissao'] as String?,
      formacaoSaude: (data['formacao_saude'] ?? false) as bool,
    );
  }

  int? get age {
    if (birthDate == null) return null;
    try {
      final dob = DateTime.parse(birthDate!);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      debugPrint("Erro ao parsear data de nascimento: $e");
      return null;
    }
  }

  List<String> get certificadoUrls =>
      certificados.map((e) => e['url']!).toList();
}
