import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { supabase } from './config/supabaseClient';
import authRoutes from './auth/authRoutes';
<<<<<<< Updated upstream
import userRoutes from './users/userRoutes';
=======
import appointmentRoutes from './appointments/appointmentRoutes';
>>>>>>> Stashed changes

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth', authRoutes);
<<<<<<< Updated upstream
app.use('/usuarios', userRoutes);
=======
app.use('/agendamentos', appointmentRoutes);
>>>>>>> Stashed changes

app.get('/', (req, res) => {
  res.send('Consulta Fácil API funcionando!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));
