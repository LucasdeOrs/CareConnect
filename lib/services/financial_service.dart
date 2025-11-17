import 'package:careconnect_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinancialService {
  Future<Map<String, dynamic>> fetchCaregiverFinancialData(
    String caregiverId,
  ) async {
    try {
      final pixData = await supabase
          .from('cuidadores')
          .select('pix_key_type, pix_key')
          .eq('id', caregiverId)
          .single();

      final payments = await supabase
          .from('pagamentos')
          .select(
            'valor_liquido_recebedor, status_pagamento, created_at, agendamento:agendamento_id(familiar:familiar_id(nome))',
          )
          .eq('recebedor_id', caregiverId)
          .order('created_at', ascending: false);

      double saldoDisponivel = 0.0;
      double saldoPendente = 0.0;

      for (var p in payments) {
        final status = p['status_pagamento'];
        final valor = (p['valor_liquido_recebedor'] as num).toDouble();

        if (status == 'sucedido') {
          saldoDisponivel += valor;
        } else if (status == 'processando') {
          saldoPendente += valor;
        }
      }

      return {
        'pix_key_type': pixData['pix_key_type'],
        'pix_key': pixData['pix_key'],
        'payments': payments,
        'saldo_disponivel': saldoDisponivel,
        'saldo_pendente': saldoPendente,
      };
    } on PostgrestException catch (e) {
      throw Exception('Erro no banco ao buscar recebimentos: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado ao buscar dados financeiros: $e');
    }
  }
}
