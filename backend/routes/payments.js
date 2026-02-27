const express = require('express');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

router.post('/initiate',
    authenticateToken,
    [
        body('bill_id').isUUID(),
        body('payment_method').isIn(['momo_mtn', 'momo_vodafone', 'momo_airteltigo', 'cash', 'bank_transfer']),
        body('momo_phone_number').optional().isString()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

        const { bill_id, payment_method, momo_phone_number } = req.body;

        try {
            const billResult = await db.query(
                `SELECT b.bill_id, b.client_id, b.total_amount, b.status
                 FROM bills b
                 JOIN clients c ON b.client_id = c.client_id
                 WHERE b.bill_id = $1 AND c.user_id = $2`,
                [bill_id, req.user.user_id]
            );

            if (billResult.rows.length === 0) {
                return res.status(404).json({ error: 'Bill not found' });
            }

            const bill = billResult.rows[0];
            const paymentResult = await db.query(
                `INSERT INTO payments (bill_id, client_id, amount, payment_method, momo_phone_number, payment_status)
                 VALUES ($1, $2, $3, $4, $5, 'pending')
                 RETURNING payment_id, bill_id, amount, payment_status, created_at`,
                [bill.bill_id, bill.client_id, bill.total_amount, payment_method, momo_phone_number || null]
            );

            return res.status(201).json({
                success: true,
                message: 'Payment initiated. Awaiting gateway confirmation.',
                payment: paymentResult.rows[0]
            });
        } catch (error) {
            return res.status(500).json({ error: 'Failed to initiate payment', details: error.message });
        }
    }
);

router.get('/status/:payment_id', authenticateToken, async (req, res) => {
    try {
        const result = await db.query(
            `SELECT p.payment_id, p.bill_id, p.amount, p.payment_method, p.payment_status,
                    p.payment_date, p.receipt_number, p.failure_reason
             FROM payments p
             JOIN clients c ON p.client_id = c.client_id
             WHERE p.payment_id = $1 AND c.user_id = $2`,
            [req.params.payment_id, req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Payment not found' });
        }

        return res.json({ success: true, payment: result.rows[0] });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch payment status', details: error.message });
    }
});

router.post('/webhook', async (req, res) => {
    const { payment_id, status, momo_transaction_id, receipt_number, failure_reason } = req.body;

    if (!payment_id || !status) {
        return res.status(400).json({ error: 'payment_id and status are required' });
    }

    try {
        const mappedStatus = status === 'successful' ? 'successful' : status === 'failed' ? 'failed' : 'pending';

        const updated = await db.query(
            `UPDATE payments
             SET payment_status = $1,
                 momo_transaction_id = COALESCE($2, momo_transaction_id),
                 receipt_number = COALESCE($3, receipt_number),
                 failure_reason = COALESCE($4, failure_reason),
                 payment_date = CURRENT_TIMESTAMP
             WHERE payment_id = $5
             RETURNING payment_id, bill_id, payment_status`,
            [mappedStatus, momo_transaction_id || null, receipt_number || null, failure_reason || null, payment_id]
        );

        if (updated.rows.length === 0) {
            return res.status(404).json({ error: 'Payment record not found' });
        }

        if (mappedStatus === 'successful') {
            await db.query('UPDATE bills SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE bill_id = $2', ['paid', updated.rows[0].bill_id]);
        }

        return res.json({ success: true, payment: updated.rows[0] });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to process webhook', details: error.message });
    }
});

module.exports = router;
