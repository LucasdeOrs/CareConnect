import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './auth/authRoutes';
import appointmentRoutes from './appointments/appointmentRoutes';
import userRoutes from './users/userRoutes';
import notificationRoutes from './notifications/notificationRoutes';
import reviewRoutes from './reviews/reviewRoutes';
import availabilityRoutes from './availability/availabilityRoutes';
import paymentRoutes from './payments/paymentRoutes';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

app.use('/auth', authRoutes);
app.use('/usuarios', userRoutes);
app.use('/agendamentos', appointmentRoutes);
app.use('/notificacoes', notificationRoutes);
app.use('/avaliacoes', reviewRoutes);
app.use('/disponibilidades', availabilityRoutes);
app.use('/pagamentos', paymentRoutes);

app.get('/', (req, res) => {
  res.send('Consulta Fácil API funcionando!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Servidor rodando na porta ${PORT}`));
