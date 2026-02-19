// Admin Routes
const express = require('express');
const router = express.Router();
const { authenticateToken, authorize } = require('../middleware/auth');

router.use(authenticateToken);
router.use(authorize('admin', 'supervisor'));

router.get('/dashboard-stats', async (req, res) => {
    res.json({ message: 'Dashboard stats endpoint' });
});

router.post('/collectors', async (req, res) => {
    res.json({ message: 'Create collector endpoint' });
});

router.post('/schedules', async (req, res) => {
    res.json({ message: 'Create schedule endpoint' });
});

router.post('/optimize-route', async (req, res) => {
    res.json({ message: 'Route optimization endpoint' });
});

module.exports = router;
