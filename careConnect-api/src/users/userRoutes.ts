import express from 'express';
import { getUsuarioById, listUsuarios } from './userController';

const router = express.Router();

router.get('/', listUsuarios);

router.get('/:id', getUsuarioById);

export default router;
