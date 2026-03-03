require('dotenv').config();
const express       = require('express');
const http          = require('http');
const { Server }    = require('socket.io');
const cors          = require('cors');
const helmet        = require('helmet');
const rateLimit     = require('express-rate-limit');
const path          = require('path');
const connectDB     = require('./config/db');
const socketHandler = require('./socket');

const app    = express();
const server = http.createServer(app);
const io     = new Server(server, { cors: { origin: '*' } });

connectDB();

// Security middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// Rate limiting for auth routes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 20,
  message: { message: 'Too many requests, please try again later.' },
});

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth',  authLimiter, require('./routes/auth'));
app.use('/api/users', require('./routes/users'));

app.get('/', (_, res) => res.json({ status: '♟ Chess API running!' }));

socketHandler(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
