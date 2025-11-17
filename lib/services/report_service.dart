import 'package:careconnect_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  Future<void> submitReport({
    required String agendamentoId,
    required String reporterId,
    required String reportedCuidadorId,
    required String motivo,
    required String detalhes,
    List<String>? anexosUrls,
  }) async {
    try {
      await supabase.from('reports').insert({
        'agendamento_id': agendamentoId,
        'reporter_id': reporterId,
        'reported_cuidador_id': reportedCuidadorId,
        'motivo': motivo,
        'detalhes': detalhes,
        'anexos_urls': anexosUrls,
      });
    } on PostgrestException catch (e) {
      throw Exception('Erro ao registrar denúncia: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao enviar denúncia: $e');
    }
  }
}
