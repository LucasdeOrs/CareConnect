import 'package:careconnect_app/core/enums/status_enums.dart';
import 'package:careconnect_app/models/appointment_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class AppointmentService {
  Future<String> createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await supabase
          .from('agendamentos')
          .insert(data)
          .select()
          .single();
      return response['id'];
    } catch (e) {
      throw Exception('Erro ao criar agendamento: $e');
    }
  }

  Future<void> updateStatus(String id, AppointmentStatus newStatus) async {
    try {
      await supabase
          .from('agendamentos')
          .update({'status': newStatus.dbValue})
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  Future<void> updateAppointmentPatient(
    String appointmentId,
    String newPatientId,
  ) async {
    try {
      await supabase
          .from('agendamentos')
          .update({'paciente_id': newPatientId})
          .eq('id', appointmentId);
    } catch (e) {
      throw Exception('Erro ao trocar paciente: $e');
    }
  }

  Stream<List<AppointmentDetails>> getAppointmentsStream({
    required String userId,
    required String? cuidadorId,
    required UserType userType,
    required String filterKey,
    required Map<String, dynamic> selfUserMap,
    Map<String, dynamic>? selfCaregiverMap,
  }) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    dynamic query = supabase.from('agendamentos').stream(primaryKey: ['id']);

    if (userType == UserType.cuidador) {
      if (cuidadorId == null) {
        return Stream.value([]);
      }
      query = query.eq('cuidador_id', cuidadorId);
    } else {
      query = query.eq('familiar_id', userId);
    }

    if (filterKey == 'todos') {
      query = query.order('data_agendamento', ascending: false);
    } else {
      query = query.order('data_agendamento', ascending: true);
    }

    final rawStream = (query as Stream<List<dynamic>>).map(
      (list) => list.cast<Map<String, dynamic>>(),
    );

    return rawStream.asyncMap((rawDataList) async {
      final filteredList = rawDataList.where((item) {
        final status = item['status'];
        final date = item['data_agendamento'];

        if (filterKey == 'pago') return status == 'pago';
        if (filterKey == 'confirmado') return status == 'confirmado';
        if (filterKey == 'concluido') return status == 'concluido';
        if (filterKey == 'recusado') {
          return ['recusado', 'cancelado'].contains(status);
        }
        if (filterKey == 'distantes') return date.compareTo(today) < 0;

        return true;
      }).toList();

      final enrichedList = <Map<String, dynamic>>[];

      for (var rawAgendamento in filteredList) {
        try {
          if (rawAgendamento['paciente_id'] != null) {
            final pData = await supabase
                .from('pacientes')
                .select()
                .eq('id', rawAgendamento['paciente_id'])
                .single();
            rawAgendamento['pacientes'] = pData;
          }

          if (userType == UserType.cuidador) {
            final fData = await supabase
                .from('usuarios')
                .select('*')
                .eq('id', rawAgendamento['familiar_id'])
                .single();
            rawAgendamento['familiar'] = fData;
          } else {
            final cData = await supabase
                .from('cuidadores')
                .select('*, usuarios(*)')
                .eq('id', rawAgendamento['cuidador_id'])
                .single();
            rawAgendamento['cuidador'] = cData;
          }

          enrichedList.add(rawAgendamento);
        } catch (e) {
          debugPrint(
            'Erro ao enriquecer agendamento ${rawAgendamento['id']}: $e',
          );
        }
      }

      return enrichedList.map((map) {
        return AppointmentDetails.fromMap(
          map,
          userType: userType.toDb,
          selfUserMap: selfUserMap,
          selfCaregiverMap: selfCaregiverMap,
        );
      }).toList();
    });
  }

  Future<bool> checkConflict({
    required String caregiverId,
    required String dateStr,
    required double startTime,
    required double endTime,
  }) async {
    final bloqueios = await supabase
        .from('bloqueios_agenda')
        .select('hora_inicio, hora_fim')
        .eq('cuidador_id', caregiverId)
        .eq('data_bloqueio', dateStr);

    for (var b in bloqueios) {
      if (_isTimeOverlapping(
        startTime,
        endTime,
        b['hora_inicio'],
        b['hora_fim'],
      )) {
        return true;
      }
    }

    final agendamentos = await supabase
        .from('agendamentos')
        .select('hora_inicio, hora_fim')
        .eq('cuidador_id', caregiverId)
        .eq('data_agendamento', dateStr)
        .inFilter('status', ['pago', 'confirmado']);

    for (var a in agendamentos) {
      if (_isTimeOverlapping(
        startTime,
        endTime,
        a['hora_inicio'],
        a['hora_fim'],
      )) {
        return true;
      }
    }

    return false;
  }

  bool _isTimeOverlapping(
    double newStart,
    double newEnd,
    String existStartStr,
    String existEndStr,
  ) {
    final existStart = _timeStringToDouble(existStartStr);
    final existEnd = _timeStringToDouble(existEndStr);
    return newStart < existEnd && newEnd > existStart;
  }

  double _timeStringToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + (minute / 60.0);
    } catch (e) {
      debugPrint("Erro ao converter time string '$timeStr': $e");
      return 0.0;
    }
  }
}
