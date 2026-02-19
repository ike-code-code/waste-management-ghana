// =============================================
// UTILITY FUNCTIONS
// Business Logic Helpers
// =============================================

const db = require('../config/database');

/**
 * Calculate distance between two GPS coordinates using Haversine formula
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lon1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lon2 - Longitude of point 2
 * @returns {number} Distance in kilometers
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    
    return Math.round(distance * 100) / 100; // Round to 2 decimal places
}

function toRadians(degrees) {
    return degrees * (Math.PI / 180);
}

/**
 * Get active pricing configuration for waste type and bin type
 * @param {string} wasteType - Type of waste
 * @param {string} binType - Type of bin
 * @returns {Object} Pricing configuration
 */
async function getPricingConfig(wasteType, binType) {
    const result = await db.query(
        `SELECT * FROM pricing_config 
         WHERE waste_type = $1 AND bin_type = $2 
         AND is_active = TRUE 
         AND effective_from <= CURRENT_DATE
         AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)
         ORDER BY effective_from DESC
         LIMIT 1`,
        [wasteType, binType]
    );
    
    if (result.rows.length === 0) {
        throw new Error(`No pricing found for ${wasteType} + ${binType}`);
    }
    
    return result.rows[0];
}

/**
 * Calculate bill amount based on collection report
 * @param {Object} report - Collection report data
 * @returns {Object} Bill breakdown
 */
async function calculateBill(report) {
    // Get disposal site coordinates
    const disposalSite = await db.query(
        'SELECT gps_latitude, gps_longitude FROM disposal_sites WHERE is_active = TRUE LIMIT 1'
    );
    
    if (disposalSite.rows.length === 0) {
        throw new Error('No active disposal site found');
    }
    
    const { gps_latitude: siteLat, gps_longitude: siteLng } = disposalSite.rows[0];
    
    // Calculate distance
    const distance = calculateDistance(
        report.gps_latitude,
        report.gps_longitude,
        siteLat,
        siteLng
    );
    
    // Get pricing
    const pricing = await getPricingConfig(report.waste_type, report.bin_type);
    
    // Calculate charges
    const baseCharge = parseFloat(pricing.base_fee);
    const weightCharge = parseFloat(report.waste_weight_kg) * parseFloat(pricing.rate_per_kg);
    const distanceCharge = distance * parseFloat(pricing.rate_per_km);
    const quantityMultiplier = report.bin_quantity || 1;
    
    const totalAmount = (baseCharge + weightCharge + distanceCharge) * quantityMultiplier;
    
    return {
        distance_to_disposal_km: distance,
        base_charge: baseCharge,
        weight_charge: weightCharge,
        distance_charge: distanceCharge,
        waste_type_charge: weightCharge,
        bin_type_charge: baseCharge,
        quantity_multiplier: quantityMultiplier,
        total_amount: Math.round(totalAmount * 100) / 100 // Round to 2 decimal places
    };
}

/**
 * Generate unique receipt number
 * @returns {string} Receipt number in format WM-YYYYMMDD-XXXX
 */
function generateReceiptNumber() {
    const date = new Date();
    const dateStr = date.toISOString().slice(0, 10).replace(/-/g, '');
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `WM-${dateStr}-${random}`;
}

/**
 * Validate Ghana Card number format
 * @param {string} cardNumber - Ghana Card number
 * @returns {boolean} Valid or not
 */
function isValidGhanaCard(cardNumber) {
    const regex = /^GHA-[0-9]{9}-[0-9]$/;
    return regex.test(cardNumber);
}

/**
 * Validate Ghana phone number format
 * @param {string} phoneNumber - Phone number
 * @returns {boolean} Valid or not
 */
function isValidPhoneNumber(phoneNumber) {
    const regex = /^(\+233|0)[0-9]{9}$/;
    return regex.test(phoneNumber);
}

/**
 * Format phone number to international format
 * @param {string} phoneNumber - Phone number
 * @returns {string} Formatted phone number
 */
function formatPhoneNumber(phoneNumber) {
    if (phoneNumber.startsWith('0')) {
        return '+233' + phoneNumber.slice(1);
    }
    return phoneNumber;
}

/**
 * Optimize route using nearest neighbor algorithm
 * @param {Array} locations - Array of {client_id, gps_latitude, gps_longitude}
 * @param {Object} startLocation - {lat, lng}
 * @returns {Object} Optimized route
 */
function optimizeRoute(locations, startLocation) {
    const unvisited = [...locations];
    const route = [];
    let currentLocation = startLocation;
    let totalDistance = 0;
    
    while (unvisited.length > 0) {
        let nearest = null;
        let minDistance = Infinity;
        let nearestIndex = -1;
        
        unvisited.forEach((location, index) => {
            const dist = calculateDistance(
                currentLocation.lat,
                currentLocation.lng,
                location.gps_latitude,
                location.gps_longitude
            );
            
            if (dist < minDistance) {
                minDistance = dist;
                nearest = location;
                nearestIndex = index;
            }
        });
        
        route.push(nearest.client_id || nearest.schedule_id);
        totalDistance += minDistance;
        currentLocation = { 
            lat: nearest.gps_latitude, 
            lng: nearest.gps_longitude 
        };
        unvisited.splice(nearestIndex, 1);
    }
    
    return {
        optimized_order: route,
        total_distance_km: Math.round(totalDistance * 100) / 100,
        estimated_duration_minutes: Math.ceil(totalDistance * 3) // Assume ~3 min per km
    };
}

/**
 * Send notification (placeholder - integrate with SMS/Push service)
 * @param {string} userId - User ID
 * @param {string} title - Notification title
 * @param {string} message - Notification message
 * @param {string} type - Notification type
 */
async function sendNotification(userId, title, message, type = 'general') {
    await db.query(
        `INSERT INTO notifications (user_id, title, message, type)
         VALUES ($1, $2, $3, $4)`,
        [userId, title, message, type]
    );
    
    // TODO: Integrate with SMS or Push notification service
    // For now, just log it
    console.log(`Notification sent to ${userId}: ${title}`);
}

module.exports = {
    calculateDistance,
    calculateBill,
    getPricingConfig,
    generateReceiptNumber,
    isValidGhanaCard,
    isValidPhoneNumber,
    formatPhoneNumber,
    optimizeRoute,
    sendNotification
};
