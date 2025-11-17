import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

export const registerUser = async (req: Request, res: Response) => {
  const { email, password, tipo, nome } = req.body;

  try {
    const { data: authUser, error: authError } = await supabase.auth.signUp({
      email,
      password,
    });

    if (authError) throw authError;

    const userId = authUser.user?.id;
    if (!userId) {
      return res.status(400).json({
        error: 'Usuário criado, mas é necessário confirmar o e-mail antes de continuar.'
      });
    }

    const { error: insertError } = await supabase.from('usuarios').insert([
      { id: userId, nome, email, tipo },
    ]);

    if (insertError) throw insertError;

    return res.status(201).json({
      message: 'Usuário registrado com sucesso!',
      user: { id: userId, email, tipo },
    });
  } catch (error: any) {
    return res.status(400).json({ error: error.message });
  }
};

export const loginUser = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  try {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) throw error;

    return res.status(200).json({
      message: 'Login realizado com sucesso!',
      token: data.session?.access_token,
      refresh_token: data.session?.refresh_token,
      user: data.user,
    });
  } catch (error: any) {
    return res.status(401).json({ error: error.message });
  }
};
