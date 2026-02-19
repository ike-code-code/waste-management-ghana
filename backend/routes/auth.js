// =============================================
// AUTHENTICATION ROUTES
// Register, Login, Logout
// =============================================

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const db = require('../config/database');
const { isValidGhanaCard, isValidPhoneNumber, formatPhoneNumber } = require('../utils/helpers');
const logger = require('../utils/logger');

// =============================================
// REGISTER CLIENT
// =============================================

router.post('/register',
    [
        body('ghana_card_number').custom(value => {
            if (!isValidGhanaCard(value)) {
                throw new Error('Invalid Ghana Card format (GHA-XXXXXXXXX-X)');
            }
            return true;
        }),
        body('full_name').trim().isLength({ min: 3 }).withMessage('Name must be at least 3 characters'),
        body('phone_number').custom(value => {
            if (!isValidPhoneNumber(value)) {
                throw new Error('Invalid phone number format');
            }
            return true;
        }),
        body('password').isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
            .matches(/[A-Z]/).withMessage('Password must contain uppercase letter')
            .matches(/[0-9]/).withMessage('Password must contain number'),
        body('premises_type').isIn(['owned', 'rented', 'company', 'institution']),
        body('gps_latitude').isFloat({ min: -90, max: 90 }),
        body('gps_longitude').isFloat({ min: -180, max: 180 }),
        body('number_of_bins').optional().isInt({ min: 1 }),
        body('bin_size_liters').optional().isInt(),
        body('default_waste_type').optional().isIn(['domestic', 'plastics', 'papers']),
        body('default_bin_type').optional().isIn(['regular_240l', 'dumpster_1100l', 'waste_bag'])
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const {
            ghana_card_number,
            full_name,
            phone_number,
            email,
            password,
            premises_type,
            gps_latitude,
            gps_longitude,
            preferred_collection_days,
            number_of_bins = 1,
            bin_size_liters = 240,
            residential_area,
            default_waste_type = 'domestic',
            default_bin_type = 'regular_240l',
            default_bin_quantity = 1
        } = req.body;
        
        try {
            // Format phone number
            const formattedPhone = formatPhoneNumber(phone_number);
            
            // Check if user already exists
            const existingUser = await db.query(
                'SELECT user_id FROM users WHERE ghana_card_number = $1 OR phone_number = $2',
                [ghana_card_number, formattedPhone]
            );
            
            if (existingUser.rows.length > 0) {
                return res.status(400).json({ 
                    error: 'User already exists with this Ghana Card or phone number' 
                });
            }
            
            // Hash password
            const passwordHash = await bcrypt.hash(
                password, 
                parseInt(process.env.BCRYPT_ROUNDS) || 12
            );
            
            // Start transaction
            const result = await db.transaction(async (client) => {
                // Create user
                const userResult = await client.query(
                    `INSERT INTO users (ghana_card_number, full_name, phone_number, email, password_hash, role)
                     VALUES ($1, $2, $3, $4, $5, 'client')
                     RETURNING user_id, ghana_card_number, full_name, phone_number, role, created_at`,
                    [ghana_card_number, full_name, formattedPhone, email, passwordHash]
                );
                
                const user = userResult.rows[0];
                
                // Create client profile
                await client.query(
                    `INSERT INTO clients (
                        user_id, premises_type, gps_latitude, gps_longitude, gps_location,
                        preferred_collection_days, number_of_bins, bin_size_liters,
                        residential_area, default_waste_type, default_bin_type, default_bin_quantity
                    ) VALUES ($1, $2, $3, $4, ST_SetSRID(ST_MakePoint($5, $4), 4326), $6, $7, $8, $9, $10, $11, $12)
                     RETURNING client_id`,
                    [
                        user.user_id, premises_type, gps_latitude, gps_longitude, gps_longitude,
                        preferred_collection_days, number_of_bins, bin_size_liters,
                        residential_area, default_waste_type, default_bin_type, default_bin_quantity
                    ]
                );
                
                return user;
            });
            
            // Generate JWT token
            const token = jwt.sign(
                { userId: result.user_id, role: result.role },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
            );
            
            logger.info(`New client registered: ${result.user_id}`);
            
            res.status(201).json({
                success: true,
                message: 'Registration successful',
                user: {
                    user_id: result.user_id,
                    full_name: result.full_name,
                    phone_number: result.phone_number,
                    role: result.role
                },
                token
            });
            
        } catch (error) {
            logger.error('Registration error:', error);
            res.status(500).json({ error: 'Registration failed', details: error.message });
        }
    }
);

// =============================================
// LOGIN
// =============================================

router.post('/login',
    [
        body('phone_number').notEmpty(),
        body('password').notEmpty()
    ],
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ errors: errors.array() });
        }
        
        const { phone_number, password } = req.body;
        
        try {
            const formattedPhone = formatPhoneNumber(phone_number);
            
            // Get user
            const result = await db.query(
                `SELECT u.*, 
                        c.client_id, c.residential_area,
                        col.collector_id
                 FROM users u
                 LEFT JOIN clients c ON u.user_id = c.user_id
                 LEFT JOIN collectors col ON u.user_id = col.user_id
                 WHERE u.phone_number = $1`,
                [formattedPhone]
            );
            
            if (result.rows.length === 0) {
                return res.status(401).json({ error: 'Invalid phone number or password' });
            }
            
            const user = result.rows[0];
            
            if (!user.is_active) {
                return res.status(401).json({ error: 'Account is deactivated' });
            }
            
            // Verify password
            const passwordMatch = await bcrypt.compare(password, user.password_hash);
            
            if (!passwordMatch) {
                return res.status(401).json({ error: 'Invalid phone number or password' });
            }
            
            // Update last login
            await db.query(
                'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = $1',
                [user.user_id]
            );
            
            // Generate JWT token
            const token = jwt.sign(
                { userId: user.user_id, role: user.role },
                process.env.JWT_SECRET,
                { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
            );
            
            logger.info(`User logged in: ${user.user_id} (${user.role})`);
            
            res.json({
                success: true,
                message: 'Login successful',
                token,
                user: {
                    user_id: user.user_id,
                    full_name: user.full_name,
                    phone_number: user.phone_number,
                    role: user.role,
                    client_id: user.client_id,
                    collector_id: user.collector_id,
                    residential_area: user.residential_area
                }
            });
            
        } catch (error) {
            logger.error('Login error:', error);
            res.status(500).json({ error: 'Login failed' });
        }
    }
);

// =============================================
// LOGOUT
// =============================================

router.post('/logout', (req, res) => {
    // With JWT, logout is handled client-side by removing the token
    // We just log the event here
    res.json({ success: true, message: 'Logged out successfully' });
});

module.exports = router;
