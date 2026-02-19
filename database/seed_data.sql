-- =============================================
-- SEED DATA FOR TESTING
-- Waste Management System
-- =============================================

-- Sample Clients (Password for all: Test@123)
INSERT INTO users (ghana_card_number, full_name, phone_number, password_hash, role, email) VALUES
('GHA-123456789-1', 'Kwame Mensah', '+233241234567', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'client', 'kwame@test.com'),
('GHA-123456789-2', 'Ama Osei', '+233541234568', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'client', 'ama@test.com'),
('GHA-123456789-3', 'Kofi Antwi', '+233201234569', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'client', 'kofi@test.com'),
('GHA-123456789-4', 'Akua Boateng', '+233271234570', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'client', 'akua@test.com'),
('GHA-123456789-5', 'Yaw Frimpong', '+233551234571', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'client', 'yaw@test.com');

-- Sample Collectors (Password: Collector@123)
INSERT INTO users (ghana_card_number, full_name, phone_number, password_hash, role) VALUES
('GHA-234567890-1', 'John Collector', '+233241111111', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'collector'),
('GHA-234567890-2', 'Mary Collector', '+233541111112', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'collector'),
('GHA-234567890-3', 'Peter Collector', '+233201111113', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5eW8h7C7YLNni', 'collector');

-- Link clients to client profiles (around Kumasi area)
INSERT INTO clients (user_id, premises_type, gps_latitude, gps_longitude, gps_location, residential_area, preferred_collection_days, number_of_bins, default_waste_type, default_bin_type)
SELECT 
    user_id,
    'owned',
    6.6885 + (RANDOM() * 0.02 - 0.01), -- Random lat around Kumasi
    -1.6244 + (RANDOM() * 0.02 - 0.01), -- Random lng around Kumasi
    ST_SetSRID(ST_MakePoint(-1.6244 + (RANDOM() * 0.02 - 0.01), 6.6885 + (RANDOM() * 0.02 - 0.01)), 4326),
    CASE 
        WHEN ghana_card_number = 'GHA-123456789-1' THEN 'Adum'
        WHEN ghana_card_number = 'GHA-123456789-2' THEN 'Asokwa'
        WHEN ghana_card_number = 'GHA-123456789-3' THEN 'Bantama'
        WHEN ghana_card_number = 'GHA-123456789-4' THEN 'Adum'
        ELSE 'Asokwa'
    END,
    'Monday,Thursday',
    2,
    'domestic',
    'regular_240l'
FROM users 
WHERE role = 'client';

-- Link collectors to collector profiles
INSERT INTO collectors (user_id, assigned_vehicle_number, assigned_areas)
SELECT 
    user_id,
    CASE 
        WHEN ghana_card_number = 'GHA-234567890-1' THEN 'WM-001'
        WHEN ghana_card_number = 'GHA-234567890-2' THEN 'WM-002'
        ELSE 'WM-003'
    END,
    CASE 
        WHEN ghana_card_number = 'GHA-234567890-1' THEN '["Adum", "Bantama"]'
        WHEN ghana_card_number = 'GHA-234567890-2' THEN '["Asokwa", "Tafo"]'
        ELSE '["Adum", "Asokwa"]'
    END
FROM users 
WHERE role = 'collector';

-- Sample pickup requests
INSERT INTO pickup_requests (client_id, waste_type, bin_type, quantity, pickup_type, requested_date, status)
SELECT 
    client_id,
    'domestic',
    'regular_240l',
    2,
    'one_time',
    CURRENT_DATE + 3,
    'pending'
FROM clients
LIMIT 2;

-- Sample collection schedules for this week
INSERT INTO collection_schedules (client_id, collector_id, waste_type, bin_type, bin_quantity, scheduled_date, scheduled_time, status)
SELECT 
    c.client_id,
    col.collector_id,
    'domestic',
    'regular_240l',
    2,
    CURRENT_DATE + INTERVAL '1 day',
    '08:00:00',
    'pending'
FROM clients c
CROSS JOIN collectors col
WHERE col.assigned_vehicle_number = 'WM-001'
LIMIT 3;

-- Seed complete message
DO $$
BEGIN
    RAISE NOTICE 'Seed data inserted successfully!';
    RAISE NOTICE 'Default admin login: +233200000000 / Admin@123';
    RAISE NOTICE 'Sample client login: +233241234567 / Test@123';
    RAISE NOTICE 'Sample collector login: +233241111111 / Collector@123';
END $$;
