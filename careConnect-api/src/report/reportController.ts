import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * RF014 - Relatórios e Histórico de Atividades
 * Retorna o histórico completo de um familiar (agendamentos, pagamentos e avaliações)
 */
export const relatorioFamiliar = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    // 🔹 Agendamentos do familiar
    const { data: agendamentos, error: agError } = await supabase
      .from('agendamentos')
      .select('id, data, horario, status, observacao, cuidador_id')
      .eq('familiar_id', id)
      .order('data', { ascending: false });

    if (agError) throw agError;

    // 🔹 Pagamentos relacionados ao familiar
    const { data: pagamentos, error: pgError } = await supabase
      .from('pagamentos')
      .select('id, valor, metodo, status, data_pagamento, agendamento_id')
      .eq('familiar_id', id)
      .order('data_pagamento', { ascending: false });

    if (pgError) throw pgError;

    // 🔹 Avaliações feitas pelo familiar
    const { data: avaliacoes, error: avError } = await supabase
      .from('avaliacoes')
      .select('id, cuidador_id, nota, comentario, data_criacao')
      .eq('familiar_id', id)
      .order('data_criacao', { ascending: false });

    if (avError) throw avError;

    return res.status(200).json({
      message: 'Relatório do familiar gerado com sucesso!',
      relatorio: { agendamentos, pagamentos, avaliacoes },
    });
  } catch (err: any) {
    console.error('Erro ao gerar relatório do familiar:', err.message);
    return res.status(400).json({ error: err.message });
  }
};

/**
 * RF014 - Histórico do Cuidador
 * Retorna agendamentos, pagamentos recebidos e avaliações
 */
export const relatorioCuidador = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    // 🔹 Agendamentos do cuidador
    const { data: agendamentos, error: agError } = await supabase
      .from('agendamentos')
      .select('id, data, horario, status, observacao, familiar_id')
      .eq('cuidador_id', id)
      .order('data', { ascending: false });

    if (agError) throw agError;

    // 🔹 Pagamentos recebidos
    const { data: pagamentos, error: pgError } = await supabase
      .from('pagamentos')
      .select('id, valor, metodo, status, data_pagamento, agendamento_id')
      .eq('cuidador_id', id)
      .order('data_pagamento', { ascending: false });

    if (pgError) throw pgError;

    // 🔹 Avaliações recebidas
    const { data: avaliacoes, error: avError } = await supabase
      .from('avaliacoes')
      .select('id, familiar_id, nota, comentario, data_criacao')
      .eq('cuidador_id', id)
      .order('data_criacao', { ascending: false });

    if (avError) throw avError;

    return res.status(200).json({
      message: 'Relatório do cuidador gerado com sucesso!',
      relatorio: { agendamentos, pagamentos, avaliacoes },
    });
  } catch (err: any) {
    console.error('Erro ao gerar relatório do cuidador:', err.message);
    return res.status(400).json({ error: err.message });
  }
};

/**
 * RF014 - Histórico de Agendamentos (por período opcional)
 */
export const relatorioAgendamentos = async (req: Request, res: Response) => {
  const { usuario_id, tipo, inicio, fim } = req.query;

  try {
    if (!usuario_id || !tipo) {
      return res
        .status(400)
        .json({ error: 'Informe usuario_id e tipo (cuidador ou familiar).' });
    }

    let query = supabase.from('agendamentos').select('*');

    if (tipo === 'cuidador') query = query.eq('cuidador_id', usuario_id);
    else query = query.eq('familiar_id', usuario_id);

    if (inicio && fim)
      query = query.gte('data', inicio as string).lte('data', fim as string);

    const { data, error } = await query.order('data', { ascending: false });

    if (error) throw error;

    return res.status(200).json({
      message: 'Relatório de agendamentos gerado com sucesso!',
      agendamentos: data,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};
