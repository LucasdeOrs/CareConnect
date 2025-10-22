import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

export const criarAgendamento = async (req: Request, res: Response) => {
  const { cuidador_id, familiar_id, data, horario, observacao } = req.body;

  try {
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

    return res.status(201).json({
      message: 'Agendamento solicitado com sucesso!',
      agendamento,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

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

    const { data, error } = await supabase
      .from('agendamentos')
      .update({ status })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.status(200).json({
      message: 'Status atualizado com sucesso!',
      agendamento: data,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

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
