import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './auth/authRoutes';
import appointmentRoutes from './appointments/appointmentRoutes';
import userRoutes from './users/userRoutes';
import notificationRoutes from './notifications/notificationRoutes';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/usuarios', userRoutes);
app.use('/agendamentos', appointmentRoutes);
app.use('/notificacoes', notificationRoutes);

app.get('/', (req, res) => {
  res.send('Consulta Fácil API funcionando!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));
