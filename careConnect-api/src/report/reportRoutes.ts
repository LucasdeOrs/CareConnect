import express from 'express';
import { relatorioFamiliar, relatorioCuidador,relatorioAgendamentos } from './reportController';

const router = express.Router();

router.get('/familiar/:id', relatorioFamiliar);

router.get('/cuidador/:id', relatorioCuidador);

router.get('/agendamentos', relatorioAgendamentos);

export default router;
