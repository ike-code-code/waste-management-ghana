const express = require('express');
const bcrypt = require('bcrypt');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const db = require('../config/database');
const { authenticateToken, authorize } = require('../middleware/auth');
const { isValidGhanaCard, isValidPhoneNumber, formatPhoneNumber } = require('../utils/helpers');

router.use(authenticateToken);
router.use(authorize('admin', 'supervisor'));

router.get('/dashboard-stats', async (req, res) => {
    try {
        const [users, activeRequests, todaySchedules, pendingBills, revenue] = await Promise.all([
            db.query('SELECT role, COUNT(*)::int AS count FROM users GROUP BY role'),
            db.query("SELECT COUNT(*)::int AS count FROM pickup_requests WHERE status IN ('pending', 'approved', 'scheduled')"),
            db.query('SELECT COUNT(*)::int AS count FROM collection_schedules WHERE scheduled_date = CURRENT_DATE'),
            db.query("SELECT COUNT(*)::int AS count FROM bills WHERE status IN ('pending', 'overdue')"),
            db.query("SELECT COALESCE(SUM(amount), 0)::numeric(12,2) AS total FROM payments WHERE payment_status = 'successful'")
        ]);

        const userBreakdown = users.rows.reduce((acc, row) => {
            acc[row.role] = row.count;
            return acc;
        }, {});

        return res.json({
            success: true,
            stats: {
                users: userBreakdown,
                active_pickup_requests: activeRequests.rows[0].count,
                schedules_today: todaySchedules.rows[0].count,
                pending_or_overdue_bills: pendingBills.rows[0].count,
                total_revenue: revenue.rows[0].total
            }
        });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to load dashboard stats', details: error.message });
    }
});

router.post('/collectors',
    [
        body('ghana_card_number').custom(value => {
            if (!isValidGhanaCard(value)) throw new Error('Invalid Ghana Card format');
            return true;
        }),
        body('full_name').trim().isLength({ min: 3 }),
        body('phone_number').custom(value => {
            if (!isValidPhoneNumber(value)) throw new Error('Invalid phone number format');
            return true;
        }),
        body('password').isLength({ min: 8 }),
        body('assigned_vehicle_number').optional().isString(),
        body('assigned_areas').optional().isArray()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

        const { ghana_card_number, full_name, phone_number, password, assigned_vehicle_number, assigned_areas = [] } = req.body;

        try {
            const passwordHash = await bcrypt.hash(password, 10);
            const formattedPhone = formatPhoneNumber(phone_number);

            const collector = await db.transaction(async (client) => {
                const userInsert = await client.query(
                    `INSERT INTO users (ghana_card_number, full_name, phone_number, password_hash, role)
                     VALUES ($1, $2, $3, $4, 'collector')
                     RETURNING user_id, full_name, phone_number`,
                    [ghana_card_number, full_name, formattedPhone, passwordHash]
                );

                const collectorInsert = await client.query(
                    `INSERT INTO collectors (user_id, assigned_vehicle_number, assigned_areas)
                     VALUES ($1, $2, $3)
                     RETURNING collector_id, assigned_vehicle_number, assigned_areas`,
                    [userInsert.rows[0].user_id, assigned_vehicle_number || null, JSON.stringify(assigned_areas)]
                );

                return {
                    ...userInsert.rows[0],
                    ...collectorInsert.rows[0]
                };
            });

            return res.status(201).json({ success: true, collector });
        } catch (error) {
            return res.status(500).json({ error: 'Failed to create collector', details: error.message });
        }
    }
);

router.post('/schedules', async (req, res) => {
    res.json({ message: 'Create schedule endpoint - coming next' });
});

router.post('/optimize-route', async (req, res) => {
    res.json({ message: 'Route optimization endpoint - AI integration pending' });
});

module.exports = router;
