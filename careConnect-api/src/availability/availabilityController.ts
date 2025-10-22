import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

export const criarDisponibilidade = async (req: Request, res: Response) => {
  const { cuidador_id, dia_semana, horario_inicio, horario_fim } = req.body;

  try {
    const { data: existente, error: existeError } = await supabase
      .from('disponibilidades')
      .select('*')
      .eq('cuidador_id', cuidador_id)
      .eq('dia_semana', dia_semana);

    if (existeError) throw existeError;

    const conflito = existente.some(
      (d: any) =>
        (horario_inicio >= d.horario_inicio && horario_inicio < d.horario_fim) ||
        (horario_fim > d.horario_inicio && horario_fim <= d.horario_fim)
    );

    if (conflito) {
      return res.status(400).json({ error: 'Já existe uma disponibilidade nesse horário.' });
    }

    const { data, error } = await supabase
      .from('disponibilidades')
      .insert([{ cuidador_id, dia_semana, horario_inicio, horario_fim }])
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      message: 'Disponibilidade cadastrada com sucesso!',
      disponibilidade: data,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

export const listarDisponibilidades = async (req: Request, res: Response) => {
  const { cuidador_id } = req.query;

  try {
    if (!cuidador_id) {
      return res.status(400).json({ error: 'Informe o cuidador_id.' });
    }

    const { data, error } = await supabase
      .from('disponibilidades')
      .select('*')
      .eq('cuidador_id', cuidador_id)
      .order('dia_semana', { ascending: true });

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

export const excluirDisponibilidade = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { error } = await supabase.from('disponibilidades').delete().eq('id', id);

    if (error) throw error;

    return res.status(200).json({ message: 'Disponibilidade excluída com sucesso!' });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};
