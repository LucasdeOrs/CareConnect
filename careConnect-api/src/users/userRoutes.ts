import express from 'express';
import { getUsuarioById, listUsuarios } from './userController';

const router = express.Router();

// GET /usuarios → lista todos ou filtra por tipo
router.get('/', listUsuarios);

// GET /usuarios/:id → retorna um usuário específico
router.get('/:id', getUsuarioById);

export default router;
