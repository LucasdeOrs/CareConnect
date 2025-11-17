import 'package:careconnect_app/models/patient_model.dart';
import 'package:careconnect_app/models/user_model.dart';
import 'package:flutter/material.dart';
import '../core/enums/status_enums.dart';
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
  final AppointmentStatus status;
  final String codigoConfirmacao;
  final bool avaliado;

  final UserModel familiar;
  final UserModel cuidador;
  final PatientModel? paciente;

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
    UserModel familiarObj;
    UserModel cuidadorObj;
    Map<String, dynamic>? cuidadorJoinData;

    // Lógica de conversão usando UserModel.simple ou fromJson
    if (userType == 'familiar') {
      familiarObj = UserModel.fromJson(selfUserMap);
      final cuidadorJoin = map['cuidador'];
      final cuidadorUserJoin = cuidadorJoin?['usuarios'];
      cuidadorObj = UserModel.fromJson(cuidadorUserJoin ?? {});
      cuidadorJoinData = cuidadorJoin;
    } else {
      cuidadorObj = UserModel.fromJson(selfUserMap);
      cuidadorJoinData = selfCaregiverMap;
      final familiarJoin = map['familiar'];
      familiarObj = UserModel.fromJson(familiarJoin ?? {});
    }

    PatientModel? pacienteObj;
    if (map['pacientes'] != null) {
      pacienteObj = PatientModel.fromJson(map['pacientes']);
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

      // Conversão do Enum aqui
      status: AppointmentStatus.fromString(map['status'] ?? ''),

      codigoConfirmacao: map['codigo_confirmacao'] ?? '---',
      avaliado: map['avaliado'] ?? false,
      familiar: familiarObj,
      cuidador: cuidadorObj,
      paciente: pacienteObj,
      rawCaregiverData: cuidadorJoinData,
    );
  }
}
