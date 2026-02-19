-- =============================================
-- WASTE MANAGEMENT SYSTEM - DATABASE SCHEMA
-- Atwima Kwanwoma District Assembly
-- PostgreSQL 14+ with PostGIS Extension
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================
-- USERS & AUTHENTICATION
-- =============================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ghana_card_number VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255),
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('client', 'collector', 'admin', 'supervisor')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    CONSTRAINT valid_ghana_card CHECK (ghana_card_number ~ '^GHA-[0-9]{9}-[0-9]$'),
    CONSTRAINT valid_phone CHECK (phone_number ~ '^\+233[0-9]{9}$' OR phone_number ~ '^0[0-9]{9}$')
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_ghana_card ON users(ghana_card_number);
CREATE INDEX idx_users_role ON users(role);

-- =============================================
-- CLIENTS
-- =============================================

CREATE TABLE clients (
    client_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    premises_type VARCHAR(20) CHECK (premises_type IN ('owned', 'rented', 'company', 'institution')),
    gps_location GEOGRAPHY(POINT, 4326) NOT NULL,
    gps_latitude DECIMAL(10,8) NOT NULL,
    gps_longitude DECIMAL(11,8) NOT NULL,
    preferred_collection_days VARCHAR(100), -- e.g., "Monday,Thursday"
    number_of_bins INTEGER DEFAULT 1,
    bin_size_liters INTEGER DEFAULT 240,
    residential_area VARCHAR(255),
    default_waste_type VARCHAR(20) CHECK (default_waste_type IN ('domestic', 'plastics', 'papers')),
    default_bin_type VARCHAR(20) DEFAULT 'regular_240l' CHECK (default_bin_type IN ('regular_240l', 'dumpster_1100l', 'waste_bag')),
    default_bin_quantity INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_clients_user ON clients(user_id);
CREATE INDEX idx_clients_area ON clients(residential_area);
CREATE INDEX idx_clients_location ON clients USING GIST(gps_location);

-- =============================================
-- COLLECTORS
-- =============================================

CREATE TABLE collectors (
    collector_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    assigned_vehicle_number VARCHAR(50),
    assigned_areas TEXT, -- JSON array: ["Area 1", "Area 2"]
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_collectors_user ON collectors(user_id);

-- =============================================
-- DISPOSAL SITES
-- =============================================

CREATE TABLE disposal_sites (
    site_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_name VARCHAR(255) NOT NULL,
    gps_location GEOGRAPHY(POINT, 4326) NOT NULL,
    gps_latitude DECIMAL(10,8) NOT NULL,
    gps_longitude DECIMAL(11,8) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_disposal_sites_active ON disposal_sites(is_active);

-- Insert Kumasi Compost and Recycling Plant
INSERT INTO disposal_sites (site_name, gps_latitude, gps_longitude, gps_location) 
VALUES (
    'Kumasi Compost and Recycling Plant', 
    6.6885, 
    -1.6244,
    ST_SetSRID(ST_MakePoint(-1.6244, 6.6885), 4326)
);

-- =============================================
-- PICKUP REQUESTS
-- =============================================

CREATE TABLE pickup_requests (
    request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(client_id) ON DELETE CASCADE,
    waste_type VARCHAR(20) NOT NULL CHECK (waste_type IN ('domestic', 'plastics', 'papers')),
    bin_type VARCHAR(20) NOT NULL CHECK (bin_type IN ('regular_240l', 'dumpster_1100l', 'waste_bag')),
    quantity INTEGER NOT NULL DEFAULT 1,
    pickup_type VARCHAR(20) NOT NULL CHECK (pickup_type IN ('one_time', 'recurring')),
    requested_date DATE, -- for one_time
    recurring_frequency VARCHAR(20) CHECK (recurring_frequency IN ('daily', 'weekly', 'biweekly', 'monthly')),
    recurring_days VARCHAR(100), -- e.g., "Monday,Thursday"
    special_instructions TEXT,
    estimated_weight_kg DECIMAL(8,2),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'scheduled', 'rejected')),
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_by_admin_id UUID REFERENCES users(user_id),
    processed_at TIMESTAMP
);

CREATE INDEX idx_pickup_requests_client ON pickup_requests(client_id);
CREATE INDEX idx_pickup_requests_status ON pickup_requests(status);
CREATE INDEX idx_pickup_requests_created ON pickup_requests(created_at);

-- =============================================
-- COLLECTION SCHEDULES
-- =============================================

CREATE TABLE collection_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(client_id) ON DELETE CASCADE,
    collector_id UUID REFERENCES collectors(collector_id),
    waste_type VARCHAR(20) NOT NULL,
    bin_type VARCHAR(20) NOT NULL,
    bin_quantity INTEGER DEFAULT 1,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'missed', 'rescheduled', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    pickup_request_id UUID REFERENCES pickup_requests(request_id)
);

CREATE INDEX idx_schedules_client ON collection_schedules(client_id);
CREATE INDEX idx_schedules_collector ON collection_schedules(collector_id);
CREATE INDEX idx_schedules_date ON collection_schedules(scheduled_date);
CREATE INDEX idx_schedules_status ON collection_schedules(status);

-- =============================================
-- COLLECTION REPORTS
-- =============================================

CREATE TABLE collection_reports (
    report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID REFERENCES collection_schedules(schedule_id),
    collector_id UUID REFERENCES collectors(collector_id),
    client_id UUID REFERENCES clients(client_id),
    waste_type VARCHAR(20) NOT NULL,
    bin_type VARCHAR(20) NOT NULL,
    bin_quantity INTEGER DEFAULT 1,
    collection_date DATE NOT NULL,
    collection_time TIMESTAMP NOT NULL,
    gps_location GEOGRAPHY(POINT, 4326) NOT NULL,
    gps_latitude DECIMAL(10,8) NOT NULL,
    gps_longitude DECIMAL(11,8) NOT NULL,
    waste_weight_kg DECIMAL(8,2) NOT NULL,
    distance_to_disposal_km DECIMAL(8,2),
    client_confirmation BOOLEAN DEFAULT FALSE,
    client_confirmation_date TIMESTAMP,
    photo_urls TEXT[], -- Array of photo URLs
    notes TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP, -- NULL if submitted offline, filled when synced
    is_offline_submission BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_reports_schedule ON collection_reports(schedule_id);
CREATE INDEX idx_reports_collector ON collection_reports(collector_id);
CREATE INDEX idx_reports_client ON collection_reports(client_id);
CREATE INDEX idx_reports_date ON collection_reports(collection_date);
CREATE INDEX idx_reports_synced ON collection_reports(synced_at) WHERE is_offline_submission = TRUE;

-- =============================================
-- PRICING CONFIGURATION
-- =============================================

CREATE TABLE pricing_config (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    waste_type VARCHAR(20) NOT NULL,
    bin_type VARCHAR(20) NOT NULL,
    base_fee DECIMAL(10,2) NOT NULL,
    rate_per_kg DECIMAL(10,2) NOT NULL,
    rate_per_km DECIMAL(10,2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES users(user_id),
    UNIQUE(waste_type, bin_type, effective_from)
);

CREATE INDEX idx_pricing_active ON pricing_config(is_active, effective_from);

-- Insert default pricing
INSERT INTO pricing_config (waste_type, bin_type, base_fee, rate_per_kg, rate_per_km, effective_from) VALUES
('domestic', 'regular_240l', 10.00, 0.50, 0.20, CURRENT_DATE),
('domestic', 'dumpster_1100l', 40.00, 0.50, 0.20, CURRENT_DATE),
('domestic', 'waste_bag', 5.00, 0.50, 0.15, CURRENT_DATE),
('plastics', 'regular_240l', 8.00, 0.30, 0.20, CURRENT_DATE),
('plastics', 'dumpster_1100l', 32.00, 0.30, 0.20, CURRENT_DATE),
('plastics', 'waste_bag', 4.00, 0.30, 0.15, CURRENT_DATE),
('papers', 'regular_240l', 8.00, 0.25, 0.20, CURRENT_DATE),
('papers', 'dumpster_1100l', 32.00, 0.25, 0.20, CURRENT_DATE),
('papers', 'waste_bag', 4.00, 0.25, 0.15, CURRENT_DATE);

-- =============================================
-- BILLS
-- =============================================

CREATE TABLE bills (
    bill_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID REFERENCES clients(client_id),
    report_id UUID REFERENCES collection_reports(report_id),
    billing_period_start DATE,
    billing_period_end DATE,
    base_charge DECIMAL(10,2),
    weight_charge DECIMAL(10,2),
    distance_charge DECIMAL(10,2),
    waste_type_charge DECIMAL(10,2),
    bin_type_charge DECIMAL(10,2),
    quantity_multiplier INTEGER DEFAULT 1,
    total_amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bills_client ON bills(client_id);
CREATE INDEX idx_bills_status ON bills(status);
CREATE INDEX idx_bills_due_date ON bills(due_date);

-- =============================================
-- PAYMENTS
-- =============================================

CREATE TABLE payments (
    payment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bill_id UUID REFERENCES bills(bill_id),
    client_id UUID REFERENCES clients(client_id),
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(20) CHECK (payment_method IN ('momo_mtn', 'momo_vodafone', 'momo_airteltigo', 'cash', 'bank_transfer')),
    momo_phone_number VARCHAR(20),
    momo_transaction_id VARCHAR(255),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'successful', 'failed', 'cancelled')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    receipt_number VARCHAR(50) UNIQUE,
    failure_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_payments_bill ON payments(bill_id);
CREATE INDEX idx_payments_client ON payments(client_id);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_transaction ON payments(momo_transaction_id);

-- =============================================
-- ROUTES (for optimization)
-- =============================================

CREATE TABLE routes (
    route_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_name VARCHAR(255),
    collector_id UUID REFERENCES collectors(collector_id),
    route_date DATE NOT NULL,
    optimized_order TEXT, -- JSON array of schedule_ids in order
    total_distance_km DECIMAL(8,2),
    estimated_duration_minutes INTEGER,
    status VARCHAR(20) DEFAULT 'planned' CHECK (status IN ('planned', 'active', 'completed')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_routes_collector ON routes(collector_id);
CREATE INDEX idx_routes_date ON routes(route_date);

-- =============================================
-- NOTIFICATIONS
-- =============================================

CREATE TABLE notifications (
    notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50), -- 'collection_reminder', 'payment_due', 'payment_success', etc.
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- =============================================
-- AUDIT LOG
-- =============================================

CREATE TABLE audit_log (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(user_id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created ON audit_log(created_at);

-- =============================================
-- VIEWS FOR REPORTING
-- =============================================

-- Active clients view
CREATE VIEW v_active_clients AS
SELECT 
    c.client_id,
    u.full_name,
    u.phone_number,
    c.residential_area,
    c.gps_latitude,
    c.gps_longitude,
    c.default_waste_type,
    c.default_bin_type,
    c.number_of_bins
FROM clients c
JOIN users u ON c.user_id = u.user_id
WHERE u.is_active = TRUE;

-- Collection statistics view
CREATE VIEW v_collection_stats AS
SELECT 
    cr.collector_id,
    u.full_name AS collector_name,
    DATE_TRUNC('month', cr.collection_date) AS month,
    COUNT(*) AS total_collections,
    SUM(cr.waste_weight_kg) AS total_waste_kg,
    AVG(cr.waste_weight_kg) AS avg_waste_kg,
    SUM(CASE WHEN cr.client_confirmation THEN 1 ELSE 0 END) AS confirmed_collections
FROM collection_reports cr
JOIN collectors col ON cr.collector_id = col.collector_id
JOIN users u ON col.user_id = u.user_id
GROUP BY cr.collector_id, u.full_name, DATE_TRUNC('month', cr.collection_date);

-- Revenue statistics view
CREATE VIEW v_revenue_stats AS
SELECT 
    DATE_TRUNC('month', b.created_at) AS month,
    COUNT(*) AS total_bills,
    SUM(b.total_amount) AS total_billed,
    SUM(CASE WHEN b.status = 'paid' THEN b.total_amount ELSE 0 END) AS total_paid,
    SUM(CASE WHEN b.status = 'pending' THEN b.total_amount ELSE 0 END) AS total_pending,
    SUM(CASE WHEN b.status = 'overdue' THEN b.total_amount ELSE 0 END) AS total_overdue
FROM bills b
GROUP BY DATE_TRUNC('month', b.created_at);

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to calculate distance between two points
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL, lon1 DECIMAL,
    lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    distance DECIMAL;
BEGIN
    distance := ST_Distance(
        ST_SetSRID(ST_MakePoint(lon1, lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(lon2, lat2), 4326)::geography
    ) / 1000; -- Convert meters to kilometers
    RETURN distance;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collectors_updated_at BEFORE UPDATE ON collectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_schedules_updated_at BEFORE UPDATE ON collection_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bills_updated_at BEFORE UPDATE ON bills
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- INITIAL ADMIN USER
-- =============================================

-- Password: Admin@123 (hashed with bcrypt)
-- This should be changed on first login
INSERT INTO users (ghana_card_number, full_name, phone_number, password_hash, role, email)
VALUES (
    'GHA-000000000-0',
    'System Administrator',
    '+233200000000',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', -- Admin@123
    'admin',
    'admin@wasteghanapp.com'
);

-- =============================================
-- DATABASE SETUP COMPLETE
-- =============================================
