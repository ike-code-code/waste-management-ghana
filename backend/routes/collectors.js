// Collector Routes
const express = require('express');
const router = express.Router();
const { authenticateToken, authorize } = require('../middleware/auth');

router.use(authenticateToken);
router.use(authorize('collector'));

router.get('/tasks', async (req, res) => {
    res.json({ message: 'Get collector tasks endpoint' });
});

router.post('/submit-report', async (req, res) => {
    res.json({ message: 'Submit collection report endpoint' });
});

router.post('/sync-offline-reports', async (req, res) => {
    res.json({ message: 'Sync offline reports endpoint' });
});

module.exports = router;
