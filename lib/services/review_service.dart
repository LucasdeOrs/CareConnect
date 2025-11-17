import 'package:careconnect_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  Future<void> submitReview({
    required String agendamentoId,
    required String cuidadorId,
    required String familiarId,
    required int nota,
    required String comentario,
  }) async {
    try {
      await supabase.from('avaliacoes').insert({
        'agendamento_id': agendamentoId,
        'cuidador_id': cuidadorId,
        'familiar_id': familiarId,
        'nota': nota,
        'comentario': comentario.trim(),
      });

      await supabase
          .from('agendamentos')
          .update({'avaliado': true})
          .eq('id', agendamentoId);
    } on PostgrestException catch (e) {
      throw Exception('Erro ao salvar avaliação: ${e.message}');
    } catch (e) {
      throw Exception('Um erro inesperado ocorreu: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForCaregiver(
    String caregiverId,
  ) async {
    try {
      final response = await supabase
          .from('avaliacoes')
          .select('*, familiar:familiar_id(nome, avatar_url)')
          .eq('cuidador_id', caregiverId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Erro ao buscar avaliações: $e");
      return [];
    }
  }
}
