const jwt = require('jsonwebtoken');
const User = require('./models/User');
const Game = require('./models/Game');

function updateElo(winnerRating, loserRating) {
  const K = 32;
  const expected = 1 / (1 + Math.pow(10, (loserRating - winnerRating) / 400));
  return Math.round(K * (1 - expected));
}

const queue = [];
const activeGames = {};

module.exports = (io) => {

  // ── AUTH MIDDLEWARE ───────────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Unauthorized'));
    try {
      socket.user = jwt.verify(token, process.env.JWT_SECRET);
      next();
    } catch {
      next(new Error('Unauthorized'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`🔌 Connected: ${socket.user.id}`);
    await User.findByIdAndUpdate(socket.user.id, { isOnline: true });

    // ── QUEUE ─────────────────────────────────────────────────
    socket.on('join_queue', async (data) => {
      // data ممکنه undefined باشه - safe destructure
      const timeLimit = (data && data.timeLimit) ? Number(data.timeLimit) : 600;

      // اگه قبلاً توی صف بود حذفش کن
      const idx = queue.findIndex(q => q.userId === socket.user.id);
      if (idx !== -1) queue.splice(idx, 1);

      const user = await User.findById(socket.user.id).select('username rating');
      queue.push({
        socketId: socket.id,
        userId: socket.user.id,
        username: user.username,
        rating: user.rating,
        timeLimit,
      });

      console.log(`📋 Queue length: ${queue.length}`);

      if (queue.length >= 2) {
        const p1 = queue.shift();
        const p2 = queue.shift();
        await _startGame(io, p1, p2, p1.timeLimit);
      } else {
        socket.emit('waiting_for_opponent');
      }
    });

    socket.on('leave_queue', () => {
      const idx = queue.findIndex(q => q.userId === socket.user.id);
      if (idx !== -1) queue.splice(idx, 1);
      console.log(`📋 Left queue. Length: ${queue.length}`);
    });

    // ── INVITE ────────────────────────────────────────────────
    socket.on('invite_user', async (data) => {
      const { targetUserId, timeLimit = 600 } = data;

      const user = await User.findById(socket.user.id).select('username rating');
      const targetSockets = await getUserSockets(io, targetUserId);

      console.log(`📨 Invite to ${targetUserId} | sockets: ${targetSockets.length}`);

      if (targetSockets.length === 0) {
        // کاربر socket نداره (آفلاینه) - به فرستنده اطلاع بده
        socket.emit('invite_failed', { reason: 'User is not available' });
        return;
      }

      targetSockets.forEach(s => {
        io.to(s).emit('game_invite', {
          from: {
            id: socket.user.id,
            username: user.username,
            rating: user.rating,
          },
          socketId: socket.id,
          timeLimit: Number(timeLimit),
        });
      });
    });

    socket.on('accept_invite', async (data) => {
      const { fromSocketId, fromUserId, timeLimit = 600 } = data;

      const [u1, u2] = await Promise.all([
        User.findById(socket.user.id).select('username rating'),
        User.findById(fromUserId).select('username rating'),
      ]);

      const p1 = {
        socketId: fromSocketId,
        userId: fromUserId,
        username: u2.username,
        rating: u2.rating,
      };
      const p2 = {
        socketId: socket.id,
        userId: socket.user.id,
        username: u1.username,
        rating: u1.rating,
      };

      await _startGame(io, p1, p2, Number(timeLimit));
    });

    socket.on('decline_invite', (data) => {
      const { fromSocketId } = data;
      io.to(fromSocketId).emit('invite_declined');
    });

    // ── MOVES ─────────────────────────────────────────────────
    socket.on('make_move', async (data) => {
      const { gameId, move, fen } = data;
      const g = activeGames[gameId];
      if (!g) return;

      g.moves.push(move);
      await Game.findByIdAndUpdate(gameId, { $push: { moves: move } });

      const opponentSocket = g.white.userId === socket.user.id
          ? g.black.socketId
          : g.white.socketId;

      io.to(opponentSocket).emit('opponent_move', { move, fen });
    });

    // ── GAME OVER ─────────────────────────────────────────────
    socket.on('game_over', async (data) => {
      const { gameId, result } = data;
      await _endGame(io, gameId, result, 'normal');
    });

    socket.on('resign', async (data) => {
      const { gameId } = data;
      const g = activeGames[gameId];
      if (!g) return;
      const winner = g.white.userId === socket.user.id ? 'black' : 'white';
      await _endGame(io, gameId, winner, 'resign');
    });

    socket.on('time_out', async (data) => {
      const { gameId, loserColor } = data;
      const winner = loserColor === 'white' ? 'black' : 'white';
      await _endGame(io, gameId, winner, 'timeout');
    });

    // ── CHAT ──────────────────────────────────────────────────
    socket.on('send_message', async (data) => {
      const { gameId, message } = data;
      const g = activeGames[gameId];
      if (!g) return;

      const opponentSocket = g.white.userId === socket.user.id
          ? g.black.socketId
          : g.white.socketId;

      await Game.findByIdAndUpdate(gameId, {
        $push: { chat: { sender: socket.user.id, message } },
      });

      io.to(opponentSocket).emit('new_message', {
        senderId: socket.user.id,
        message,
        time: new Date(),
      });
    });

    // ── DISCONNECT ────────────────────────────────────────────
    socket.on('disconnect', async () => {
      console.log(`🔌 Disconnected: ${socket.user.id}`);
      await User.findByIdAndUpdate(socket.user.id, { isOnline: false });

      // از صف حذف کن
      const idx = queue.findIndex(q => q.userId === socket.user.id);
      if (idx !== -1) queue.splice(idx, 1);

      // بازی‌های فعال رو تموم کن
      for (const [gId, g] of Object.entries(activeGames)) {
        if (g.white.userId === socket.user.id || g.black.userId === socket.user.id) {
          const winner = g.white.userId === socket.user.id ? 'black' : 'white';
          await _endGame(io, gId, winner, 'disconnect');
        }
      }
    });
  });

  // ══ HELPERS ══════════════════════════════════════════════════

  async function _startGame(io, p1, p2, timeLimit) {
    const tl = timeLimit || 600;
    const game = await Game.create({
      whitePlayer: p1.userId,
      blackPlayer: p2.userId,
    });
    const gId = game._id.toString();

    activeGames[gId] = {
      gameId: gId,
      white: p1,
      black: p2,
      moves: [],
      timeLimit: tl,
    };

    console.log(`♟  Game started: ${gId} | ${p1.username} vs ${p2.username} | ${tl}s`);

    io.to(p1.socketId).emit('game_start', {
      gameId: gId,
      color: 'white',
      timeLimit: tl,
      opponent: { id: p2.userId, username: p2.username, rating: p2.rating },
    });

    io.to(p2.socketId).emit('game_start', {
      gameId: gId,
      color: 'black',
      timeLimit: tl,
      opponent: { id: p1.userId, username: p1.username, rating: p1.rating },
    });
  }

  async function _endGame(io, gameId, result, reason) {
    const g = activeGames[gameId];
    if (!g) return;

    const white = await User.findById(g.white.userId);
    const black = await User.findById(g.black.userId);

    let winnerId = null;
    let ratingChangeWhite = 0;
    let ratingChangeBlack = 0;

    if (result === 'draw') {
      white.draws++;
      black.draws++;
    } else if (result === 'white') {
      winnerId = white._id;
      const change = updateElo(white.rating, black.rating);
      ratingChangeWhite = change;
      ratingChangeBlack = -change;
      white.wins++;
      white.rating += change;
      black.losses++;
      black.rating -= change;
    } else {
      winnerId = black._id;
      const change = updateElo(black.rating, white.rating);
      ratingChangeBlack = change;
      ratingChangeWhite = -change;
      black.wins++;
      black.rating += change;
      white.losses++;
      white.rating -= change;
    }

    await Promise.all([white.save(), black.save()]);
    await Game.findByIdAndUpdate(gameId, {
      status: result === 'draw' ? 'draw' : 'finished',
      winner: winnerId,
      ratingChange: { white: ratingChangeWhite, black: ratingChangeBlack },
    });

    console.log(`🏁 Game ended: ${gameId} | result: ${result} | reason: ${reason}`);

    io.to(g.white.socketId).emit('game_ended', {
      result,
      reason,
      ratingChange: ratingChangeWhite,
      newRating: white.rating,
    });

    io.to(g.black.socketId).emit('game_ended', {
      result,
      reason,
      ratingChange: ratingChangeBlack,
      newRating: black.rating,
    });

    delete activeGames[gameId];
  }
};

// ── خارج از module.exports ────────────────────────────────
async function getUserSockets(io, userId) {
  const sockets = await io.fetchSockets();
  return sockets
      .filter(s => s.user?.id === userId)
      .map(s => s.id);
}