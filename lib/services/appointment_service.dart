import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';

class AppointmentService {
  Future<String> createAppointment({
    required String caregiverId,
    required String patientId,
    required String serviceType,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String address,
    String? notes,
    required double totalValue,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

    final response = await supabase
        .from('agendamentos')
        .insert({
          'cuidador_id': caregiverId,
          'familiar_id': userId,
          'paciente_id': patientId,
          'tipo_servico': serviceType,
          'data_agendamento': dateStr,
          'hora_inicio': fmtTime(startTime),
          'hora_fim': fmtTime(endTime),
          'endereco_local': address,
          'observacao': notes,
          'valor_total': totalValue,
          'status': 'aguardando_pagamento',
        })
        .select()
        .single();

    return response['id'];
  }

  Future<void> updateStatus(String appointmentId, String newStatus) async {
    await supabase
        .from('agendamentos')
        .update({'status': newStatus})
        .eq('id', appointmentId)
        .select();
  }

  Future<bool> checkAvailability({
    required String caregiverId,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    double toDouble(TimeOfDay t) => t.hour + (t.minute / 60.0);

    final startD = toDouble(start);
    final endD = toDouble(end);

    final bloqueios = await supabase
        .from('bloqueios_agenda')
        .select('hora_inicio, hora_fim')
        .eq('cuidador_id', caregiverId)
        .eq('data_bloqueio', dateStr);

    for (var b in bloqueios) {
      double parse(String s) {
        var p = s.split(':');
        return int.parse(p[0]) + int.parse(p[1]) / 60.0;
      }

      if (startD < parse(b['hora_fim']) && endD > parse(b['hora_inicio'])) {
        return false;
      }
    }

    final agendamentos = await supabase
        .from('agendamentos')
        .select('hora_inicio, hora_fim')
        .eq('cuidador_id', caregiverId)
        .eq('data_agendamento', dateStr)
        .inFilter('status', ['pago', 'confirmado']);

    for (var a in agendamentos) {
      double parse(String s) {
        var p = s.split(':');
        return int.parse(p[0]) + int.parse(p[1]) / 60.0;
      }

      if (startD < parse(a['hora_fim']) && endD > parse(a['hora_inicio'])) {
        return false;
      }
    }

    return true;
  }
}
