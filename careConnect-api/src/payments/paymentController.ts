import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * RF012 - Criar Pagamento de um Agendamento
 */
export const criarPagamento = async (req: Request, res: Response) => {
  const { agendamento_id, valor, metodo } = req.body;

  try {
    // 🔍 Verifica se o agendamento existe
    const { data: agendamento, error: agendamentoError } = await supabase
      .from('agendamentos')
      .select('*')
      .eq('id', agendamento_id)
      .single();

    if (agendamentoError || !agendamento) {
      return res.status(404).json({ error: 'Agendamento não encontrado.' });
    }

    // 💳 Cria o pagamento pendente
    const { data: pagamento, error } = await supabase
      .from('pagamentos')
      .insert([
        {
          agendamento_id,
          valor,
          metodo,
          status: 'pendente',
        },
      ])
      .select()
      .single();

    if (error) throw error;

    // 🔔 Notificação para o cuidador sobre o novo pagamento pendente
    await supabase.from('notificacoes').insert([
      {
        usuario_id: agendamento.cuidador_id,
        agendamento_id,
        tipo: 'outro',
        mensagem: `Novo pagamento pendente no valor de R$${valor.toFixed(2)}.`,
      },
    ]);

    return res.status(201).json({
      message: 'Pagamento criado com sucesso!',
      pagamento,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * RF013 - Atualizar Status de Pagamento
 */
export const atualizarStatusPagamento = async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const statusPermitidos = ['pendente', 'aprovado', 'recusado', 'cancelado'];
    if (!statusPermitidos.includes(status)) {
      return res.status(400).json({ error: 'Status inválido.' });
    }

    const { data: pagamento, error } = await supabase
      .from('pagamentos')
      .update({ status })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Busca o agendamento vinculado para identificar o familiar e o cuidador
    const { data: agendamento } = await supabase
      .from('agendamentos')
      .select('familiar_id, cuidador_id')
      .eq('id', pagamento.agendamento_id)
      .single();

    // 🔔 Cria notificações automáticas baseadas no novo status
    let mensagem = '';
    switch (status) {
      case 'aprovado':
        mensagem = 'Pagamento aprovado com sucesso!';
        break;
      case 'recusado':
        mensagem = 'Pagamento recusado. Verifique os dados e tente novamente.';
        break;
      case 'cancelado':
        mensagem = 'Pagamento cancelado pelo usuário.';
        break;
    }

    if (mensagem && agendamento?.familiar_id) {
      await supabase.from('notificacoes').insert([
        {
          usuario_id: agendamento.familiar_id,
          agendamento_id: pagamento.agendamento_id,
          tipo: 'status_atualizado',
          mensagem,
        },
      ]);
    }

    return res.status(200).json({
      message: 'Status do pagamento atualizado com sucesso!',
      pagamento,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Listar todos os pagamentos
 */
export const listarPagamentos = async (req: Request, res: Response) => {
  const { usuario_id } = req.query;

  try {
    let query = supabase.from('pagamentos').select('*, agendamentos(*)');

    if (usuario_id) {
      query = query
        .eq('agendamentos.familiar_id', usuario_id)
        .or(`agendamentos.cuidador_id.eq.${usuario_id}`);
    }

    const { data, error } = await query.order('data_criacao', { ascending: false });

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};
