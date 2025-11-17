import 'package:careconnect_app/main.dart';
import 'package:careconnect_app/services/auth_service.dart';
import 'package:flutter/material.dart';

class PaymentService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> fetchAppointmentDetails(
    String agendamentoId,
  ) async {
    try {
      final response = await supabase
          .from('agendamentos')
          .select()
          .eq('id', agendamentoId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Erro ao carregar agendamento para pagamento: $e');
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required String agendamentoId,
    required String recebedorId,
    required double valorBruto,
    required String metodo,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    const double feeRate = 0.15;
    final taxa = valorBruto * feeRate;
    final valorLiquido = valorBruto - taxa;

    try {
      await supabase.from('pagamentos').insert({
        'agendamento_id': agendamentoId,
        'pagador_id': user.id,
        'recebedor_id': recebedorId,
        'valor_bruto': valorBruto,
        'taxa_plataforma': taxa,
        'valor_liquido_recebedor': valorLiquido,
        'status_pagamento': 'sucedido',
        'metodo_pagamento': metodo,
      });

      final updatedAgendamento = await supabase
          .from('agendamentos')
          .update({'status': 'pago'})
          .eq('id', agendamentoId)
          .select()
          .single();

      await supabase.rpc(
        'increment_saldo_pendente',
        params: {'cuidador_uuid': recebedorId, 'valor_adicao': valorLiquido},
      );

      return updatedAgendamento;
    } catch (e) {
      throw Exception('Erro ao processar pagamento: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHistory(String userId) async {
    try {
      final data = await supabase
          .from('pagamentos')
          .select(
            'id, valor_bruto, status_pagamento, created_at, metodo_pagamento, agendamento:agendamento_id( cuidador:cuidador_id( usuario:usuario_id(nome) ) )',
          )
          .eq('pagador_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Erro ao buscar pagamentos: $e');
      throw Exception('Erro ao buscar histórico de pagamentos: $e');
    }
  }
}
