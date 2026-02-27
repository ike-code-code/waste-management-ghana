const express = require('express');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const db = require('../config/database');
const { authenticateToken, authorize } = require('../middleware/auth');

router.use(authenticateToken);
router.use(authorize('client'));

router.get('/profile', async (req, res) => {
    try {
        const result = await db.query(
            `SELECT u.user_id, u.full_name, u.phone_number, u.email,
                    c.client_id, c.premises_type, c.gps_latitude, c.gps_longitude,
                    c.preferred_collection_days, c.number_of_bins, c.bin_size_liters,
                    c.residential_area, c.default_waste_type, c.default_bin_type, c.default_bin_quantity
             FROM users u
             JOIN clients c ON u.user_id = c.user_id
             WHERE u.user_id = $1`,
            [req.user.user_id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Client profile not found' });
        }

        return res.json({ success: true, profile: result.rows[0] });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch profile', details: error.message });
    }
});

router.put('/profile',
    [
        body('full_name').optional().trim().isLength({ min: 3 }),
        body('email').optional({ checkFalsy: true }).isEmail(),
        body('preferred_collection_days').optional().isString(),
        body('number_of_bins').optional().isInt({ min: 1 }),
        body('bin_size_liters').optional().isInt({ min: 1 }),
        body('residential_area').optional().isString()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { full_name, email, preferred_collection_days, number_of_bins, bin_size_liters, residential_area } = req.body;

        try {
            await db.transaction(async (client) => {
                if (full_name !== undefined || email !== undefined) {
                    await client.query(
                        `UPDATE users
                         SET full_name = COALESCE($1, full_name),
                             email = COALESCE($2, email),
                             updated_at = CURRENT_TIMESTAMP
                         WHERE user_id = $3`,
                        [full_name, email, req.user.user_id]
                    );
                }

                await client.query(
                    `UPDATE clients
                     SET preferred_collection_days = COALESCE($1, preferred_collection_days),
                         number_of_bins = COALESCE($2, number_of_bins),
                         bin_size_liters = COALESCE($3, bin_size_liters),
                         residential_area = COALESCE($4, residential_area),
                         updated_at = CURRENT_TIMESTAMP
                     WHERE user_id = $5`,
                    [preferred_collection_days, number_of_bins, bin_size_liters, residential_area, req.user.user_id]
                );
            });

            return res.json({ success: true, message: 'Profile updated successfully' });
        } catch (error) {
            return res.status(500).json({ error: 'Failed to update profile', details: error.message });
        }
    }
);

router.get('/schedule', async (req, res) => {
    try {
        const result = await db.query(
            `SELECT cs.schedule_id, cs.scheduled_date, cs.scheduled_time, cs.status,
                    cs.waste_type, cs.bin_type, cs.bin_quantity,
                    u.full_name AS collector_name, c.assigned_vehicle_number
             FROM collection_schedules cs
             JOIN clients cl ON cs.client_id = cl.client_id
             LEFT JOIN collectors c ON cs.collector_id = c.collector_id
             LEFT JOIN users u ON c.user_id = u.user_id
             WHERE cl.user_id = $1
             ORDER BY cs.scheduled_date DESC, cs.scheduled_time DESC NULLS LAST`,
            [req.user.user_id]
        );

        return res.json({ success: true, schedules: result.rows });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch schedules', details: error.message });
    }
});

router.post('/request-pickup',
    [
        body('waste_type').isIn(['domestic', 'plastics', 'papers']),
        body('bin_type').isIn(['regular_240l', 'dumpster_1100l', 'waste_bag']),
        body('quantity').optional().isInt({ min: 1 }),
        body('pickup_type').isIn(['one_time', 'recurring']),
        body('requested_date').optional().isISO8601(),
        body('recurring_frequency').optional().isIn(['daily', 'weekly', 'biweekly', 'monthly']),
        body('recurring_days').optional().isString(),
        body('special_instructions').optional().isString(),
        body('estimated_weight_kg').optional().isFloat({ min: 0 })
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const {
            waste_type, bin_type, quantity = 1, pickup_type,
            requested_date, recurring_frequency, recurring_days,
            special_instructions, estimated_weight_kg
        } = req.body;

        try {
            const clientResult = await db.query('SELECT client_id FROM clients WHERE user_id = $1', [req.user.user_id]);
            if (clientResult.rows.length === 0) {
                return res.status(404).json({ error: 'Client account not found' });
            }

            const { client_id } = clientResult.rows[0];

            const insertResult = await db.query(
                `INSERT INTO pickup_requests (
                    client_id, waste_type, bin_type, quantity, pickup_type,
                    requested_date, recurring_frequency, recurring_days,
                    special_instructions, estimated_weight_kg
                ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
                RETURNING request_id, status, created_at`,
                [
                    client_id, waste_type, bin_type, quantity, pickup_type,
                    requested_date || null, recurring_frequency || null, recurring_days || null,
                    special_instructions || null, estimated_weight_kg || null
                ]
            );

            return res.status(201).json({
                success: true,
                message: 'Pickup request created successfully',
                request: insertResult.rows[0]
            });
        } catch (error) {
            return res.status(500).json({ error: 'Failed to create pickup request', details: error.message });
        }
    }
);

router.get('/bills', async (req, res) => {
    try {
        const result = await db.query(
            `SELECT b.bill_id, b.total_amount, b.status, b.due_date, b.created_at,
                    b.base_charge, b.weight_charge, b.distance_charge,
                    COALESCE(SUM(CASE WHEN p.payment_status = 'successful' THEN p.amount ELSE 0 END), 0) AS amount_paid
             FROM bills b
             JOIN clients c ON b.client_id = c.client_id
             LEFT JOIN payments p ON p.bill_id = b.bill_id
             WHERE c.user_id = $1
             GROUP BY b.bill_id
             ORDER BY b.created_at DESC`,
            [req.user.user_id]
        );

        return res.json({ success: true, bills: result.rows });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch bills', details: error.message });
    }
});

module.exports = router;
