import express from 'express';
import { criarAgendamento, atualizarStatus, listarAgendamentos, buscarAgendamentoPorId } from './appointmentController';

const router = express.Router();

router.post('/', criarAgendamento);

router.patch('/:id/status', atualizarStatus);

router.get('/', listarAgendamentos);

router.get('/:id', buscarAgendamentoPorId);

export default router;
