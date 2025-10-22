import express from 'express';
import { buscarAvaliacaoPorId, criarAvaliacao, listarAvaliacoesPorCuidador } from './reviewController';


const router = express.Router();

// RF008 - Criar avaliação
router.post('/', criarAvaliacao);

// Listar todas as avaliações de um cuidador
router.get('/', listarAvaliacoesPorCuidador);

// Buscar uma avaliação específica
router.get('/:id', buscarAvaliacaoPorId);

export default router;
