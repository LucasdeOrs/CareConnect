import express from 'express';
import {
  criarPagamento,
  atualizarStatusPagamento,
  listarPagamentos,
} from './paymentController';

const router = express.Router();

router.post('/', criarPagamento);
router.patch('/:id/status', atualizarStatusPagamento);
router.get('/', listarPagamentos);

export default router;
