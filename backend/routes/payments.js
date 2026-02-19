// Payment Routes
const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');

router.post('/initiate', authenticateToken, async (req, res) => {
    res.json({ message: 'Initiate payment endpoint' });
});

router.get('/status/:payment_id', authenticateToken, async (req, res) => {
    res.json({ message: 'Payment status endpoint' });
});

router.post('/webhook', async (req, res) => {
    // No auth - webhook from Hubtel
    res.json({ message: 'Payment webhook endpoint' });
});

module.exports = router;
