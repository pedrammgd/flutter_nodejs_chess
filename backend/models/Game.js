const mongoose = require('mongoose');

const gameSchema = new mongoose.Schema({
  whitePlayer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  blackPlayer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  moves:       { type: [String], default: [] },   // e.g. ["e2e4", "e7e5", ...]
  status:      { type: String, enum: ['playing', 'finished', 'draw', 'abandoned'], default: 'playing' },
  winner:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  chat:        [{ sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, message: String, time: { type: Date, default: Date.now } }],
  ratingChange:{ white: { type: Number, default: 0 }, black: { type: Number, default: 0 } },
}, { timestamps: true });

module.exports = mongoose.model('Game', gameSchema);
