import express from 'express';
import {
  criarDisponibilidade,
  listarDisponibilidades,
  excluirDisponibilidade,
} from './availabilityController';

const router = express.Router();

router.post('/', criarDisponibilidade);

router.get('/', listarDisponibilidades);

router.delete('/:id', excluirDisponibilidade);

export default router;
