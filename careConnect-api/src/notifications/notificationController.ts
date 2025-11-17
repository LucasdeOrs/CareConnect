import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * Cria uma nova notificação (manual ou via integração automática)
 */
export const criarNotificacao = async (req: Request, res: Response) => {
  const { usuario_id, agendamento_id, mensagem, tipo } = req.body;

  try {
    const { data, error } = await supabase
      .from('notificacoes')
      .insert([{ usuario_id, agendamento_id, mensagem, tipo }])
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: 'Notificação criada com sucesso!',
      notificacao: data,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Lista notificações de um usuário específico
 */
export const listarNotificacoes = async (req: Request, res: Response) => {
  const { usuario_id } = req.query;

  try {
    if (!usuario_id) {
      return res.status(400).json({ error: 'É necessário informar o usuario_id.' });
    }

    const { data, error } = await supabase
      .from('notificacoes')
      .select('*')
      .eq('usuario_id', usuario_id)
      .order('data_criacao', { ascending: false });

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Marca uma notificação como lida
 */
export const marcarComoLida = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('notificacoes')
      .update({ lida: true })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.status(200).json({
      message: 'Notificação marcada como lida!',
      notificacao: data,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};
