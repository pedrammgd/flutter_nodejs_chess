const router = require('express').Router();
const ctrl   = require('../controllers/userController');
const auth   = require('../middleware/auth');
const multer = require('multer');
const path   = require('path');

const storage = multer.diskStorage({
  destination: 'uploads/',
  filename: (req, file, cb) => cb(null, `${Date.now()}${path.extname(file.originalname)}`),
});
const upload = multer({ storage, limits: { fileSize: 2 * 1024 * 1024 } });

router.get('/search',      auth, ctrl.search);
router.get('/random',      auth, ctrl.random);
router.get('/leaderboard', auth, ctrl.leaderboard);
router.get('/:id',         auth, ctrl.profile);
router.put('/avatar',      auth, upload.single('avatar'), ctrl.uploadAvatar);

module.exports = router;
