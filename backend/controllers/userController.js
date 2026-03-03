const User = require('../models/User');
const Game = require('../models/Game');
const path = require('path');

// GET /api/users/search?q=username
exports.search = async (req, res) => {
  try {
    const q = req.query.q || '';
    const users = await User.find({
      username: { $regex: q, $options: 'i' },
      _id: { $ne: req.user.id }
    }).select('-password').limit(20);
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// GET /api/users/random  — random online user
exports.random = async (req, res) => {
  try {
    const users = await User.find({ isOnline: true, _id: { $ne: req.user.id } }).select('-password');
    if (!users.length) return res.status(404).json({ message: 'No online users found' });
    const random = users[Math.floor(Math.random() * users.length)];
    res.json(random);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// GET /api/users/leaderboard
exports.leaderboard = async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ rating: -1 }).limit(50);
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// GET /api/users/:id
exports.profile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const games = await Game.find({
      $or: [{ whitePlayer: user._id }, { blackPlayer: user._id }],
      status: { $ne: 'playing' }
    })
      .populate('whitePlayer blackPlayer winner', 'username rating avatar')
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({ user, games });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// PUT /api/users/avatar  — upload avatar
exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });
    const avatarUrl = `/uploads/${req.file.filename}`;
    await User.findByIdAndUpdate(req.user.id, { avatar: avatarUrl });
    res.json({ avatar: avatarUrl });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
