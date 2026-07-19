-- Seed Data for mine-flow Development and Testing
-- Version: 20260718
-- Site ID Default: 00000000-0000-0000-0000-000000000001

-- -----------------------------------------------------------------------------
-- SEED USERS (auth.users and public.users)
-- -----------------------------------------------------------------------------

-- Note: Static UUIDs for reproducible seed testing
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
VALUES 
    ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'supervisor@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Alex Supervisor"}', NOW(), NOW(), 'authenticated', 'authenticated'),
    ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'foreman@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Frank Foreman"}', NOW(), NOW(), 'authenticated', 'authenticated'),
    ('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'crew@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Charlie Crew"}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email, name, role, site_id, phone, is_active)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'supervisor@mineflow.dev', 'Alex Supervisor', 'supervisor', '00000000-0000-0000-0000-000000000001', '+6281234567890', true),
    ('22222222-2222-2222-2222-222222222222', 'foreman@mineflow.dev', 'Frank Foreman', 'foreman', '00000000-0000-0000-0000-000000000001', '+6281234567891', true),
    ('33333333-3333-3333-3333-333333333333', 'crew@mineflow.dev', 'Charlie Crew', 'crew', '00000000-0000-0000-0000-000000000001', '+6281234567892', true)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED ZONES
-- -----------------------------------------------------------------------------

INSERT INTO public.zones (id, site_id, name, category, description)
VALUES
    ('a1111111-aaaa-1111-aaaa-111111111111', '00000000-0000-0000-0000-000000000001', 'PIT Rusia', 'Mining Pit', 'Primary active extraction pit zone'),
    ('b2222222-bbbb-2222-bbbb-222222222222', '00000000-0000-0000-0000-000000000001', 'Soil Bank Sochi', 'Stockpile', 'Topsoil storage and disposal site')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED ATTENDANCE RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.attendance_records (id, site_id, user_id, date, status, remarks, logged_by)
VALUES
    ('c1111111-cccc-1111-cccc-111111111111', '00000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', CURRENT_DATE, 'present', 'On-time morning shift arrival', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED EQUIPMENT CHECKS
-- -----------------------------------------------------------------------------

INSERT INTO public.equipment_checks (id, site_id, foreman_id, equipment_type, serial_number, check_type, is_operational, checklist_data, remarks)
VALUES
    ('d1111111-dddd-1111-dddd-111111111111', '00000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'gnss', 'GNSS-TRIMBLE-889', 'pre_work', true, '{"battery": "100%", "satellite_lock": true, "calibration": "passed"}'::jsonb, 'Equipment calibrated and ready')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED DAILY LOGS
-- -----------------------------------------------------------------------------

INSERT INTO public.daily_logs (id, site_id, foreman_id, log_date, zone_id, status, summary, weather, notes)
VALUES
    ('e1111111-eeee-1111-eeee-111111111111', '00000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', CURRENT_DATE, 'a1111111-aaaa-1111-aaaa-111111111111', 'submitted', 'Morning excavation and bench clearing completed.', 'Sunny, 28°C', 'No safety incidents reported.')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED CUT / FILL RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.cut_fill_records (id, site_id, daily_log_id, zone_id, cut_volume, fill_volume, elevation_change, measured_by)
VALUES
    ('f1111111-ffff-1111-ffff-111111111111', '00000000-0000-0000-0000-000000000001', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 1250.50, 420.00, -1.25, '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED LAND CLEARING RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.land_clearing_records (id, site_id, daily_log_id, zone_id, area_cleared_ha, vegetation_type, cleared_by)
VALUES
    ('g1111111-gggg-1111-gggg-111111111111', '00000000-0000-0000-0000-000000000001', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 2.45, 'Secondary Forest / Scrub', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED INVENTORY ITEMS
-- -----------------------------------------------------------------------------

INSERT INTO public.inventory_items (id, site_id, name, sku, category, quantity, unit, min_threshold)
VALUES
    ('h1111111-hhhh-1111-hhhh-111111111111', '00000000-0000-0000-0000-000000000001', 'Diesel Fuel', 'DSL-001', 'Fuel', 5000.00, 'Liters', 1000.00),
    ('h2222222-hhhh-2222-hhhh-222222222222', '00000000-0000-0000-0000-000000000001', 'Boundary Stakes', 'STK-050', 'Consumables', 250.00, 'pcs', 50.00)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED GEOSPATIAL FILES METADATA
-- -----------------------------------------------------------------------------

INSERT INTO public.geospatial_files (id, site_id, zone_id, file_name, file_type, drive_file_id, drive_web_view_link, uploaded_by, metadata)
VALUES
    ('i1111111-iiii-1111-iiii-111111111111', '00000000-0000-0000-0000-000000000001', 'a1111111-aaaa-1111-aaaa-111111111111', 'PIT_Rusia_Topo_20260718.shp', '.shp', '1A2B3C4D5E6F7G8H9I0J', 'https://drive.google.com/file/d/1A2B3C4D5E6F7G8H9I0J/view', '11111111-1111-1111-1111-111111111111', '{"drone_model": "DJI Phantom 4 RTK", "crs": "EPSG:32748"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
