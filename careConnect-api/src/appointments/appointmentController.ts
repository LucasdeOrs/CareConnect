import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * RF005 - Solicitar Agendamento
 * RF011 - Verificação automática de disponibilidade
 */
export const criarAgendamento = async (req: Request, res: Response) => {
  const { cuidador_id, familiar_id, data, horario, observacao } = req.body;

  try {
    const dias = ['domingo', 'segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'];
    const dataObj = new Date(data);
    const diaSemana = dias[dataObj.getDay()];

    const { data: disponibilidade, error: dispError } = await supabase
      .from('disponibilidades')
      .select('*')
      .eq('cuidador_id', cuidador_id)
      .eq('dia_semana', diaSemana)
      .lte('horario_inicio', horario)
      .gte('horario_fim', horario)
      .maybeSingle();

    if (dispError) throw dispError;

    if (!disponibilidade) {
      return res.status(400).json({
        error: 'O cuidador não está disponível neste dia e horário.',
      });
    }

    const { data: conflito, error: conflitoError } = await supabase
      .from('agendamentos')
      .select('id')
      .eq('cuidador_id', cuidador_id)
      .eq('data', data)
      .eq('horario', horario)
      .maybeSingle();

    if (conflitoError) throw conflitoError;

    if (conflito) {
      return res.status(400).json({
        error: 'Este horário já está reservado para o cuidador.',
      });
    }

    const { data: agendamento, error } = await supabase
      .from('agendamentos')
      .insert([
        {
          cuidador_id,
          familiar_id,
          data,
          horario,
          observacao: observacao || null,
          status: 'pendente',
        },
      ])
      .select()
      .single();

    if (error) throw error;

    await supabase.from('notificacoes').insert([
      {
        usuario_id: cuidador_id,
        agendamento_id: agendamento.id,
        tipo: 'novo_agendamento',
        mensagem: `Você recebeu um novo pedido de agendamento para ${data} às ${horario}.`,
      },
    ]);

    return res.status(201).json({
      message: 'Agendamento solicitado com sucesso!',
      agendamento,
    });
  } catch (err: any) {
    console.error('Erro ao criar agendamento:', err.message);
    return res.status(400).json({ error: err.message });
  }
};

/**
 * RF006 - Atualizar Status de Agendamento
 */
export const atualizarStatus = async (req: Request, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;

  try {
    const statusPermitidos = [
      'pendente',
      'aceito',
      'recusado',
      'concluido',
      'cancelado',
    ];
    if (!statusPermitidos.includes(status)) {
      return res.status(400).json({ error: 'Status inválido.' });
    }

    const { data: agendamento, error } = await supabase
      .from('agendamentos')
      .update({ status })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // 🔔 Cria notificação automática para o familiar
    if (agendamento?.familiar_id) {
      let mensagem = '';
      switch (status) {
        case 'aceito':
          mensagem = 'Seu agendamento foi aceito pelo cuidador.';
          break;
        case 'recusado':
          mensagem = 'Seu agendamento foi recusado.';
          break;
        case 'concluido':
          mensagem = 'O agendamento foi concluído com sucesso.';
          break;
        case 'cancelado':
          mensagem = 'O agendamento foi cancelado.';
          break;
      }

      await supabase.from('notificacoes').insert([
        {
          usuario_id: agendamento.familiar_id,
          agendamento_id: agendamento.id,
          tipo: 'status_atualizado',
          mensagem,
        },
      ]);
    }

    return res.status(200).json({
      message: 'Status atualizado com sucesso!',
      agendamento,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Lista agendamentos
 */
export const listarAgendamentos = async (req: Request, res: Response) => {
  const { cuidador_id, familiar_id } = req.query;

  try {
    let query = supabase.from('agendamentos').select('*');

    if (cuidador_id) query = query.eq('cuidador_id', cuidador_id);
    if (familiar_id) query = query.eq('familiar_id', familiar_id);

    const { data, error } = await query.order('data', { ascending: true });

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Busca um agendamento específico
 */
export const buscarAgendamentoPorId = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('agendamentos')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(404).json({ error: 'Agendamento não encontrado.' });
  }
};
