// =============================================
// WASTE MANAGEMENT API - MAIN SERVER
// Atwima Kwanwoma District Assembly
// =============================================

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const db = require('./config/database');
const logger = require('./utils/logger');

// Import routes
const authRoutes = require('./routes/auth');
const clientRoutes = require('./routes/clients');
const collectorRoutes = require('./routes/collectors');
const adminRoutes = require('./routes/admin');
const paymentRoutes = require('./routes/payments');

const app = express();

// =============================================
// MIDDLEWARE
// =============================================

// Security headers
app.use(helmet());

// CORS configuration
const corsOptions = {
    origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
    credentials: true
};
app.use(cors(corsOptions));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 60000,
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.url}`, {
        ip: req.ip,
        userAgent: req.get('user-agent')
    });
    next();
});

// =============================================
// ROUTES
// =============================================

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV 
    });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/clients', clientRoutes);
app.use('/api/collectors', collectorRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/payments', paymentRoutes);

// 404 handler
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Route not found',
        path: req.url 
    });
});

// Global error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error:', err);
    
    // Don't leak error details in production
    const errorResponse = {
        error: process.env.NODE_ENV === 'production' 
            ? 'An error occurred' 
            : err.message,
        ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
    };
    
    res.status(err.status || 500).json(errorResponse);
});

// =============================================
// SERVER STARTUP
// =============================================

const PORT = process.env.PORT || 3000;

// Test database connection before starting server
db.query('SELECT NOW()')
    .then(() => {
        logger.info('Database connection established');
        
        app.listen(PORT, () => {
            logger.info(`Server running on port ${PORT}`);
            logger.info(`Environment: ${process.env.NODE_ENV}`);
            console.log(`
╔═══════════════════════════════════════════════════════╗
║   WASTE MANAGEMENT API - SERVER STARTED              ║
║   Port: ${PORT}                                         ║
║   Environment: ${process.env.NODE_ENV}                           ║
║   Ghana Flag Colors: 🟥🟨🟩⬛                          ║
╚═══════════════════════════════════════════════════════╝
            `);
        });
    })
    .catch(err => {
        logger.error('Database connection failed:', err);
        process.exit(1);
    });

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM received, closing server...');
    db.end();
    process.exit(0);
});

module.exports = app;
