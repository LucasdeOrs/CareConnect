import 'package:flutter/material.dart';

class CaregiverProfile {
  final String id;
  final String usuario_id;
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
  final bool fumante;
  final bool habilitaCnh;
  final bool possuiCarro;
  final bool gostaAnimais;
  final bool cozinha;
  final bool limpeza;
  final bool dormirLocal;

  String get location {
    if (city != null && state != null) return '$city, $state';
    if (city != null) return city!;
    return 'Localização não informada';
  }

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
    this.fumante = false,
    this.habilitaCnh = false,
    this.possuiCarro = false,
    this.gostaAnimais = false,
    this.cozinha = false,
    this.limpeza = false,
    this.dormirLocal = false,
  });

  factory CaregiverProfile.fromSupabase(Map<String, dynamic> data) {
    final usuario = data['usuarios'];
    final safeUsuario = (usuario is Map<String, dynamic>)
        ? usuario
        : <String, dynamic>{};

    final String especialidadesString =
        data['especialidades']?.toString() ?? '';
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
        } else if (item is String) {
          certsParsed.add({'url': item, 'name': 'Certificado'});
        }
      }
    }

    return CaregiverProfile(
      id: data['id']?.toString() ?? '',
      usuario_id:
          data['usuario_id']?.toString() ?? safeUsuario['id']?.toString() ?? '',
      nome: safeUsuario['nome']?.toString() ?? 'Nome não informado',
      avatarUrl: safeUsuario['avatar_url']?.toString(),
      city: safeUsuario['city']?.toString(),
      state: safeUsuario['state']?.toString(),
      especialidades: especialidadesList,
      avaliacaoMedia: avaliacaoMedia,
      availabilityText: data['availability']?.toString() ?? 'Disponível',
      experiencia: data['experiencia']?.toString(),
      certificados: certsParsed,
      experienceYears: (data['experience_years'] as num?)?.toInt() ?? 0,
      hourlyRate: (data['hourly_rate'] as num?)?.toDouble() ?? 0.0,
      birthDate: safeUsuario['birthDate']?.toString(),
      profissao: data['profissao']?.toString(),
      formacaoSaude: data['formacao_saude'] as bool? ?? false,
      fumante: data['fumante'] as bool? ?? false,
      habilitaCnh: data['habilita_cnh'] as bool? ?? false,
      possuiCarro: data['possui_carro'] as bool? ?? false,
      gostaAnimais: data['gosta_animais'] as bool? ?? false,
      cozinha: data['cozinha'] as bool? ?? false,
      limpeza: data['limpeza'] as bool? ?? false,
      dormirLocal: data['dormir_local'] as bool? ?? false,
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
