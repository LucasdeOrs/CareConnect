import 'package:flutter/material.dart';

class SimpleUser {
  final String id;

  final String nome;

  final String? avatarUrl;

  SimpleUser({required this.id, required this.nome, this.avatarUrl});

  factory SimpleUser.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return SimpleUser(id: '', nome: 'Usuário Inválido', avatarUrl: null);
    }

    return SimpleUser(
      id: map['id'] ?? '',

      nome: map['nome'] ?? 'Usuário',

      avatarUrl: map['avatar_url'],
    );
  }
}

class SimplePatient {
  final String id;

  final String nome;

  final int? idade;

  final String? condicoes;

  final String? observacoes;

  SimplePatient({
    required this.id,

    required this.nome,

    this.idade,

    this.condicoes,

    this.observacoes,
  });

  factory SimplePatient.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SimplePatient(id: '', nome: 'Não informado');

    return SimplePatient(
      id: map['id'] ?? '',

      nome: map['nome'] ?? 'Não informado',

      idade: map['idade'],

      condicoes: map['condicoes'],

      observacoes: map['observacoes'],
    );
  }
}

class AppointmentDetails {
  final String id;

  final String cuidadorId;

  final String familiarId;

  final String tipoServico;

  final DateTime dataAgendamento;

  final TimeOfDay horaInicio;

  final TimeOfDay horaFim;

  final String enderecoLocal;

  final double valorTotal;

  final String status;

  final String codigoConfirmacao;

  final bool avaliado;

  final SimpleUser familiar;

  final SimpleUser cuidador;

  final SimplePatient? paciente;

  final Map<String, dynamic>? rawCaregiverData;

  AppointmentDetails({
    required this.id,

    required this.cuidadorId,

    required this.familiarId,

    required this.tipoServico,

    required this.dataAgendamento,

    required this.horaInicio,

    required this.horaFim,

    required this.enderecoLocal,

    required this.valorTotal,

    required this.status,

    required this.codigoConfirmacao,

    required this.avaliado,

    required this.familiar,

    required this.cuidador,

    this.paciente,

    this.rawCaregiverData,
  });

  static TimeOfDay _timeFromStr(String timeStr) {
    try {
      final parts = timeStr.split(':');

      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  factory AppointmentDetails.fromMap(
    Map<String, dynamic> map, {

    required String userType,

    required Map<String, dynamic> selfUserMap,

    Map<String, dynamic>? selfCaregiverMap,
  }) {
    SimpleUser familiarObj;

    SimpleUser cuidadorObj;

    Map<String, dynamic>? cuidadorJoinData;

    if (userType == 'familiar') {
      familiarObj = SimpleUser.fromMap(selfUserMap);

      final cuidadorJoin = map['cuidador'];

      final cuidadorUserJoin = cuidadorJoin?['usuarios'];

      cuidadorObj = SimpleUser.fromMap(cuidadorUserJoin);

      cuidadorJoinData = cuidadorJoin;
    } else {
      cuidadorObj = SimpleUser.fromMap(selfUserMap);

      cuidadorJoinData = selfCaregiverMap;

      final familiarJoin = map['familiar'];

      familiarObj = SimpleUser.fromMap(familiarJoin);
    }

    SimplePatient? pacienteObj;

    if (map['pacientes'] != null) {
      pacienteObj = SimplePatient.fromMap(map['pacientes']);
    }

    return AppointmentDetails(
      id: map['id'],

      cuidadorId: map['cuidador_id'],

      familiarId: map['familiar_id'],

      tipoServico: map['tipo_servico'] ?? 'Serviço',

      dataAgendamento: DateTime.parse(map['data_agendamento']),

      horaInicio: _timeFromStr(map['hora_inicio']),

      horaFim: _timeFromStr(map['hora_fim']),

      enderecoLocal: map['endereco_local'] ?? 'Endereço não informado',

      valorTotal: (map['valor_total'] as num).toDouble(),

      status: map['status'] ?? 'pendente',

      codigoConfirmacao: map['codigo_confirmacao'] ?? '---',

      avaliado: map['avaliado'] ?? false,

      familiar: familiarObj,

      cuidador: cuidadorObj,

      paciente: pacienteObj,

      rawCaregiverData: cuidadorJoinData,
    );
  }
}
