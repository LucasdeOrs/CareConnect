import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/models/caregiver_profile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaregiverService {
  Future<List<CaregiverProfile>> getCaregivers({
    String? searchTerm,
    String? city,
    String? state,
    RangeValues? priceRange,
    bool onlyHealthProfessionals = false,
    String? availability,
    String sortOrder = 'rating_desc',
    int limit = 10,
    int offset = 0,
    bool? fumante,
    bool? habilitaCnh,
    bool? possuiCarro,
    bool? gostaAnimais,
    bool? cozinha,
    bool? limpeza,
    bool? dormirLocal,
  }) async {
    dynamic query = supabase
        .from('cuidadores')
        .select('*, usuarios!inner(*), profissao, formacao_saude')
        .eq('approval_status', 'Aprovado');

    try {
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final rpcResponse = await supabase.rpc(
          'search_cuidadores',
          params: {'search_term': searchTerm},
        );
        final List<String> ids = (rpcResponse as List)
            .map((e) => e.toString())
            .toList();
        if (ids.isEmpty) return [];
        query = query.inFilter('id', ids);
      }

      if (city != null && city.isNotEmpty) {
        query = query.eq('usuarios.city', city);
      }
      if (state != null && state.isNotEmpty) {
        query = query.eq('usuarios.state', state);
      }

      if (priceRange != null) {
        query = query
            .gte('hourly_rate', priceRange.start)
            .lte('hourly_rate', priceRange.end);
      }

      if (onlyHealthProfessionals) query = query.eq('formacao_saude', true);

      if (availability != null) {
        if (availability == "Finais de Semana") {
          query = query.ilike('availability', '%Fins de Semana%');
        } else {
          query = query.not('availability', 'ilike', '%Fins de Semana%');
        }
      }

      if (fumante != null) query = query.eq('fumante', fumante);
      if (habilitaCnh == true) query = query.eq('habilita_cnh', true);
      if (possuiCarro == true) query = query.eq('possui_carro', true);
      if (gostaAnimais == true) query = query.eq('gosta_animais', true);
      if (cozinha == true) query = query.eq('cozinha', true);
      if (limpeza == true) query = query.eq('limpeza', true);
      if (dormirLocal == true) query = query.eq('dormir_local', true);

      switch (sortOrder) {
        case 'rating_asc':
          query = query.order(
            'avaliacao_media',
            ascending: true,
            nullsFirst: false,
          );
          break;
        case 'price_asc':
          query = query.order(
            'hourly_rate',
            ascending: true,
            nullsFirst: false,
          );
          break;
        case 'price_desc':
          query = query.order(
            'hourly_rate',
            ascending: false,
            nullsFirst: false,
          );
          break;
        case 'rating_desc':
        default:
          query = query.order(
            'avaliacao_media',
            ascending: false,
            nullsFirst: false,
          );
      }

      final response = await query.range(offset, offset + limit - 1);

      return (response as List)
          .map((data) => CaregiverProfile.fromSupabase(data))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar cuidadores: $e');
    }
  }

  Future<void> updateProfile(
    String usuarioId,
    Map<String, dynamic> data,
  ) async {
    try {
      await supabase
          .from('cuidadores')
          .update(data)
          .eq('usuario_id', usuarioId);
    } catch (e) {
      throw Exception('Erro ao atualizar perfil do cuidador: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getBlocksStream(String cuidadorId) {
    return supabase
        .from('bloqueios_agenda')
        .stream(primaryKey: ['id'])
        .eq('cuidador_id', cuidadorId)
        .order('hora_inicio', ascending: true);
  }

  Future<void> addBlocks(List<Map<String, dynamic>> blocks) async {
    try {
      if (blocks.isNotEmpty) {
        await supabase.from('bloqueios_agenda').insert(blocks);
      }
    } on PostgrestException catch (e) {
      throw Exception('Erro ao salvar bloqueio: ${e.message}');
    }
  }

  Future<void> deleteBlock(String bloqueioId) async {
    try {
      await supabase.from('bloqueios_agenda').delete().eq('id', bloqueioId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao remover bloqueio: ${e.message}');
    }
  }

  Future<bool> checkExistingBlockConflict({
    required String cuidadorId,
    required String dateStr,
    required double newStart,
    required double newEnd,
  }) async {
    try {
      final bloqueios = await supabase
          .from('bloqueios_agenda')
          .select('hora_inicio, hora_fim')
          .eq('cuidador_id', cuidadorId)
          .eq('data_bloqueio', dateStr);

      for (var bloqueio in bloqueios) {
        final existingStart = _timeStringToDouble(bloqueio['hora_inicio']);
        final existingEnd = _timeStringToDouble(bloqueio['hora_fim']);

        if (newStart < existingEnd && newEnd > existingStart) {
          return true;
        }
      }
      return false;
    } catch (e) {
      throw Exception('Erro ao verificar bloqueios existentes: $e');
    }
  }

  Future<List<String>> checkAndCancelConflictingAppointments({
    required String cuidadorId,
    required List<String> dateStrings,
    required double newStart,
    required double newEnd,
  }) async {
    try {
      final agendamentos = await supabase
          .from('agendamentos')
          .select('id, hora_inicio, hora_fim')
          .eq('cuidador_id', cuidadorId)
          .inFilter('data_agendamento', dateStrings)
          .inFilter('status', ['pago', 'confirmado']);

      final conflictingIds = <String>[];
      for (var agendamento in agendamentos) {
        final existingStart = _timeStringToDouble(agendamento['hora_inicio']);
        final existingEnd = _timeStringToDouble(agendamento['hora_fim']);

        if (newStart < existingEnd && newEnd > existingStart) {
          conflictingIds.add(agendamento['id'] as String);
        }
      }

      if (conflictingIds.isNotEmpty) {
        await supabase
            .from('agendamentos')
            .update({'status': 'cancelado'})
            .inFilter('id', conflictingIds);
      }
      return conflictingIds;
    } catch (e) {
      throw Exception('Erro ao cancelar agendamentos conflitantes: $e');
    }
  }

  double _timeStringToDouble(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return hour + (minute / 60.0);
    } catch (e) {
      return 0.0;
    }
  }
}
