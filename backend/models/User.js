const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true, trim: true },
  email:    { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true },
  avatar:   { type: String, default: '' },
  rating:   { type: Number, default: 1200 },
  wins:     { type: Number, default: 0 },
  losses:   { type: Number, default: 0 },
  draws:    { type: Number, default: 0 },
  isOnline: { type: Boolean, default: false },
}, { timestamps: true });

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = function (plain) {
  return bcrypt.compare(plain, this.password);
};

// Virtual: total games
userSchema.virtual('totalGames').get(function () {
  return this.wins + this.losses + this.draws;
});

module.exports = mongoose.model('User', userSchema);
