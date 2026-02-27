const express = require('express');
const { body, validationResult } = require('express-validator');

const router = express.Router();
const db = require('../config/database');
const { authenticateToken, authorize } = require('../middleware/auth');

router.use(authenticateToken);
router.use(authorize('collector'));

router.get('/tasks', async (req, res) => {
    try {
        const result = await db.query(
            `SELECT cs.schedule_id, cs.client_id, cs.scheduled_date, cs.scheduled_time,
                    cs.waste_type, cs.bin_type, cs.bin_quantity, cs.status,
                    u.full_name AS client_name, u.phone_number AS client_phone,
                    c.gps_latitude, c.gps_longitude, c.residential_area
             FROM collection_schedules cs
             JOIN collectors col ON cs.collector_id = col.collector_id
             JOIN clients c ON cs.client_id = c.client_id
             JOIN users u ON c.user_id = u.user_id
             WHERE col.user_id = $1
             ORDER BY cs.scheduled_date ASC, cs.scheduled_time ASC NULLS LAST`,
            [req.user.user_id]
        );

        return res.json({ success: true, tasks: result.rows });
    } catch (error) {
        return res.status(500).json({ error: 'Failed to fetch collector tasks', details: error.message });
    }
});

router.post('/submit-report',
    [
        body('schedule_id').isUUID(),
        body('waste_weight_kg').isFloat({ min: 0 }),
        body('distance_to_disposal_km').optional().isFloat({ min: 0 }),
        body('gps_latitude').isFloat({ min: -90, max: 90 }),
        body('gps_longitude').isFloat({ min: -180, max: 180 }),
        body('notes').optional().isString(),
        body('is_offline_submission').optional().isBoolean()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const {
            schedule_id,
            waste_weight_kg,
            distance_to_disposal_km,
            gps_latitude,
            gps_longitude,
            notes,
            is_offline_submission = false
        } = req.body;

        try {
            const scheduleResult = await db.query(
                `SELECT cs.schedule_id, cs.client_id, cs.collector_id, cs.waste_type, cs.bin_type, cs.bin_quantity
                 FROM collection_schedules cs
                 JOIN collectors col ON cs.collector_id = col.collector_id
                 WHERE cs.schedule_id = $1 AND col.user_id = $2`,
                [schedule_id, req.user.user_id]
            );

            if (scheduleResult.rows.length === 0) {
                return res.status(404).json({ error: 'Schedule not found for collector' });
            }

            const schedule = scheduleResult.rows[0];

            const reportResult = await db.query(
                `INSERT INTO collection_reports (
                    schedule_id, collector_id, client_id, waste_type, bin_type, bin_quantity,
                    collection_date, collection_time, gps_location, gps_latitude, gps_longitude,
                    waste_weight_kg, distance_to_disposal_km, notes, is_offline_submission
                ) VALUES (
                    $1, $2, $3, $4, $5, $6,
                    CURRENT_DATE, CURRENT_TIMESTAMP,
                    ST_SetSRID(ST_MakePoint($7, $8), 4326), $8, $7,
                    $9, $10, $11, $12
                ) RETURNING report_id, submitted_at`,
                [
                    schedule.schedule_id,
                    schedule.collector_id,
                    schedule.client_id,
                    schedule.waste_type,
                    schedule.bin_type,
                    schedule.bin_quantity,
                    gps_longitude,
                    gps_latitude,
                    waste_weight_kg,
                    distance_to_disposal_km || null,
                    notes || null,
                    is_offline_submission
                ]
            );

            await db.query(
                'UPDATE collection_schedules SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE schedule_id = $2',
                ['completed', schedule.schedule_id]
            );

            return res.status(201).json({
                success: true,
                message: 'Collection report submitted',
                report: reportResult.rows[0]
            });
        } catch (error) {
            return res.status(500).json({ error: 'Failed to submit report', details: error.message });
        }
    }
);

router.post('/sync-offline-reports',
    [
        body('reports').isArray({ min: 1 }),
        body('reports.*.schedule_id').isUUID(),
        body('reports.*.waste_weight_kg').isFloat({ min: 0 }),
        body('reports.*.gps_latitude').isFloat({ min: -90, max: 90 }),
        body('reports.*.gps_longitude').isFloat({ min: -180, max: 180 })
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }

        const { reports } = req.body;
        const synced = [];
        const failed = [];

        for (const report of reports) {
            try {
                const result = await db.query(
                    `SELECT cs.schedule_id, cs.client_id, cs.collector_id, cs.waste_type, cs.bin_type, cs.bin_quantity
                     FROM collection_schedules cs
                     JOIN collectors col ON cs.collector_id = col.collector_id
                     WHERE cs.schedule_id = $1 AND col.user_id = $2`,
                    [report.schedule_id, req.user.user_id]
                );

                if (result.rows.length === 0) {
                    failed.push({ schedule_id: report.schedule_id, reason: 'Schedule not found' });
                    continue;
                }

                const schedule = result.rows[0];
                const insert = await db.query(
                    `INSERT INTO collection_reports (
                        schedule_id, collector_id, client_id, waste_type, bin_type, bin_quantity,
                        collection_date, collection_time, gps_location, gps_latitude, gps_longitude,
                        waste_weight_kg, distance_to_disposal_km, notes, is_offline_submission, synced_at
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6,
                        CURRENT_DATE, CURRENT_TIMESTAMP,
                        ST_SetSRID(ST_MakePoint($7, $8), 4326), $8, $7,
                        $9, $10, $11, TRUE, CURRENT_TIMESTAMP
                    ) RETURNING report_id`,
                    [
                        schedule.schedule_id,
                        schedule.collector_id,
                        schedule.client_id,
                        schedule.waste_type,
                        schedule.bin_type,
                        schedule.bin_quantity,
                        report.gps_longitude,
                        report.gps_latitude,
                        report.waste_weight_kg,
                        report.distance_to_disposal_km || null,
                        report.notes || null
                    ]
                );

                await db.query(
                    'UPDATE collection_schedules SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE schedule_id = $2',
                    ['completed', schedule.schedule_id]
                );

                synced.push({ schedule_id: report.schedule_id, report_id: insert.rows[0].report_id });
            } catch (error) {
                failed.push({ schedule_id: report.schedule_id, reason: error.message });
            }
        }

        return res.json({
            success: failed.length === 0,
            synced_count: synced.length,
            failed_count: failed.length,
            synced,
            failed
        });
    }
);

module.exports = router;
