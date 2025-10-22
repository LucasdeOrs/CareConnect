import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * RF003 e RF004 - Listar e visualizar usuários (cuidadores e familiares)
 */

// Lista todos os usuários, podendo filtrar por tipo
export const listUsuarios = async (req: Request, res: Response) => {
  const { tipo } = req.query; // Exemplo: /usuarios?tipo=cuidador

  try {
    let query = supabase.from('usuarios').select('*').order('data_criacao', { ascending: false });

    if (tipo && (tipo === 'cuidador' || tipo === 'familiar')) {
      query = query.eq('tipo', tipo as string);
    }

    const { data, error } = await query;

    if (error) throw error;

    return res.status(200).json(data);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

// Retorna um usuário específico
export const getUsuarioById = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase.from('usuarios').select('*').eq('id', id).single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({ error: 'Usuário não encontrado.' });
    }

    return res.status(200).json(data);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};
