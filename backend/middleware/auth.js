// =============================================
// AUTHENTICATION MIDDLEWARE
// JWT Token Verification
// =============================================

const jwt = require('jsonwebtoken');
const db = require('../config/database');
const logger = require('../utils/logger');

/**
 * Verify JWT token and attach user to request
 */
async function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
    
    if (!token) {
        return res.status(401).json({ error: 'Access token required' });
    }
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Get user from database
        const result = await db.query(
            'SELECT user_id, role, full_name, phone_number, is_active FROM users WHERE user_id = $1',
            [decoded.userId]
        );
        
        if (result.rows.length === 0) {
            return res.status(401).json({ error: 'User not found' });
        }
        
        const user = result.rows[0];
        
        if (!user.is_active) {
            return res.status(401).json({ error: 'Account is deactivated' });
        }
        
        req.user = user;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired' });
        }
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ error: 'Invalid token' });
        }
        logger.error('Authentication error:', error);
        return res.status(500).json({ error: 'Authentication failed' });
    }
}

/**
 * Check if user has required role
 */
function authorize(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Not authenticated' });
        }
        
        if (!allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ 
                error: 'Access denied', 
                required_role: allowedRoles,
                your_role: req.user.role
            });
        }
        
        next();
    };
}

module.exports = {
    authenticateToken,
    authorize
};
