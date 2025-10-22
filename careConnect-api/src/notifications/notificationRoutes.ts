import express from 'express';
import {
  criarNotificacao,
  listarNotificacoes,
  marcarComoLida,
} from './notificationController';

const router = express.Router();

router.post('/', criarNotificacao);
router.get('/', listarNotificacoes);
router.patch('/:id/lida', marcarComoLida);

export default router;
