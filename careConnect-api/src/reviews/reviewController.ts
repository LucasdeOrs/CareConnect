import { Request, Response } from 'express';
import { supabase } from '../config/supabaseClient';

/**
 * RF008 - Criar avaliação de cuidador
 * Um familiar avalia um cuidador após o término do agendamento.
 */
export const criarAvaliacao = async (req: Request, res: Response) => {
  const { agendamento_id, cuidador_id, familiar_id, nota, comentario } = req.body;

  try {
    // 1️⃣ Verifica se o agendamento foi concluído
    const { data: agendamento, error: agendamentoError } = await supabase
      .from('agendamentos')
      .select('status')
      .eq('id', agendamento_id)
      .single();

    if (agendamentoError) throw agendamentoError;
    if (!agendamento) return res.status(404).json({ error: 'Agendamento não encontrado.' });
    if (agendamento.status !== 'concluido') {
      return res.status(400).json({ error: 'Somente agendamentos concluídos podem ser avaliados.' });
    }

    // 2️⃣ Cria a avaliação
    const { data: avaliacao, error: insertError } = await supabase
      .from('avaliacoes')
      .insert([
        {
          agendamento_id,
          cuidador_id,
          familiar_id,
          nota,
          comentario: comentario || null,
        },
      ])
      .select()
      .single();

    if (insertError) throw insertError;

    // 3️⃣ Atualiza média de avaliações do cuidador
    const { data: mediaResult, error: mediaError } = await supabase
      .from('avaliacoes')
      .select('nota')
      .eq('cuidador_id', cuidador_id);

    if (mediaError) throw mediaError;

    const notas = mediaResult.map((r: any) => r.nota);
    const media = notas.reduce((a: number, b: number) => a + b, 0) / notas.length;

    await supabase
      .from('cuidadores')
      .update({ avaliacao_media: media })
      .eq('id', cuidador_id);

    // 4️⃣ Cria notificação para o cuidador
    await supabase.from('notificacoes').insert([
      {
        usuario_id: cuidador_id,
        agendamento_id,
        tipo: 'nova_avaliacao',
        mensagem: `Você recebeu uma nova avaliação: nota ${nota}.`,
      },
    ]);

    return res.status(201).json({
      message: 'Avaliação registrada com sucesso!',
      avaliacao,
    });
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Lista avaliações de um cuidador
 */
export const listarAvaliacoesPorCuidador = async (req: Request, res: Response) => {
  const { cuidador_id } = req.query;

  try {
    if (!cuidador_id) return res.status(400).json({ error: 'Informe o cuidador_id.' });

    const { data, error } = await supabase
      .from('avaliacoes')
      .select('*')
      .eq('cuidador_id', cuidador_id)
      .order('data_avaliacao', { ascending: false });

    if (error) throw error;

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};

/**
 * Busca avaliação específica
 */
export const buscarAvaliacaoPorId = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const { data, error } = await supabase
      .from('avaliacoes')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (!data) return res.status(404).json({ error: 'Avaliação não encontrada.' });

    return res.status(200).json(data);
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
};
