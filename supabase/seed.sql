-- Seed Data for mine-flow Development and Testing
-- Version: 20260718
-- Site ID Default: f47ac10b-58cc-4372-a567-0e02b2c3d479

-- -----------------------------------------------------------------------------
-- SEED USERS (auth.users and public.users)
-- -----------------------------------------------------------------------------

-- Note: Static UUIDs for reproducible seed testing
INSERT INTO auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
VALUES 
    ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'seed_supervisor@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Alex Supervisor"}', NOW(), NOW(), 'authenticated', 'authenticated'),
    ('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000000', 'seed_foreman@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Frank Foreman"}', NOW(), NOW(), 'authenticated', 'authenticated'),
    ('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000000', 'seed_crew@mineflow.dev', '$2a$10$abcdefghijklmnopqrstuvwxyz0123456789ABCDEF', NOW(), '{"provider":"email","providers":["email"]}', '{"name":"Charlie Crew"}', NOW(), NOW(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.users (id, email, name, role, site_id, phone, is_active)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'seed_supervisor@mineflow.dev', 'Alex Supervisor', 'supervisor', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '+6281234567890', true),
    ('22222222-2222-2222-2222-222222222222', 'seed_foreman@mineflow.dev', 'Frank Foreman', 'foreman', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '+6281234567891', true),
    ('33333333-3333-3333-3333-333333333333', 'seed_crew@mineflow.dev', 'Charlie Crew', 'crew', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '+6281234567892', true)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED ZONES
-- -----------------------------------------------------------------------------

INSERT INTO public.zones (id, site_id, name, category, description)
VALUES
    ('a1111111-aaaa-1111-aaaa-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'PIT Rusia', 'Mining Pit', 'Primary active extraction pit zone'),
    ('b2222222-bbbb-2222-bbbb-222222222222', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'Soil Bank Sochi', 'Stockpile', 'Topsoil storage and disposal site')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED ATTENDANCE RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.attendance_records (id, site_id, user_id, date, status, remarks, logged_by)
VALUES
    ('c1111111-cccc-1111-cccc-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '33333333-3333-3333-3333-333333333333', CURRENT_DATE, 'present', 'On-time morning shift arrival', '22222222-2222-2222-2222-222222222222'),
    ('c2222222-cccc-2222-cccc-222222222222', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '33333333-3333-3333-3333-333333333333', CURRENT_DATE - INTERVAL '1 day', 'absent', 'Sick leave', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED EQUIPMENT CHECKS
-- -----------------------------------------------------------------------------

INSERT INTO public.equipment_checks (id, site_id, foreman_id, equipment_type, serial_number, check_type, is_operational, checklist_data, remarks)
VALUES
    ('d1111111-dddd-1111-dddd-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '22222222-2222-2222-2222-222222222222', 'gnss', 'GNSS-TRIMBLE-889', 'pre_work', true, '{"battery": "100%", "satellite_lock": true, "calibration": "passed"}'::jsonb, 'Equipment calibrated and ready')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED DAILY LOGS
-- -----------------------------------------------------------------------------

INSERT INTO public.daily_logs (id, site_id, foreman_id, log_date, zone_id, status, summary, weather, notes)
VALUES
    ('e1111111-eeee-1111-eeee-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', '22222222-2222-2222-2222-222222222222', CURRENT_DATE, 'a1111111-aaaa-1111-aaaa-111111111111', 'submitted', 'Morning excavation and bench clearing completed.', 'Sunny, 28°C', 'No safety incidents reported.')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED CUT / FILL RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.cut_fill_records (id, site_id, daily_log_id, zone_id, bcm_volume, lcm_volume, material_type, elevation_change, measured_by)
VALUES
    ('f1111111-ffff-1111-ffff-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 1250.50, 420.00, 'Topsoil', -1.25, '22222222-2222-2222-2222-222222222222'),
    ('f2222222-ffff-2222-ffff-222222222222', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 800.00, 200.00, 'Overburden', -0.75, '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- Additional cut/fill row with a distinct material_type (STEP-42.6 seed audit)
INSERT INTO public.cut_fill_records (id, site_id, daily_log_id, zone_id, bcm_volume, lcm_volume, material_type, elevation_change, measured_by)
VALUES
    ('f3333333-ffff-3333-ffff-333333333333', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'b2222222-bbbb-2222-bbbb-222222222222', 600.00, 450.00, 'Clay', -0.40, '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED LAND CLEARING RECORDS
-- -----------------------------------------------------------------------------

INSERT INTO public.land_clearing_records (id, site_id, daily_log_id, zone_id, plan_area, actual_area, method, cleared_by)
VALUES
    ('71111111-7777-1111-7777-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 25000.00, 24500.00, 'Mechanical', '22222222-2222-2222-2222-222222222222'),
    ('72222222-7777-2222-7777-222222222222', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'a1111111-aaaa-1111-aaaa-111111111111', 10000.00, 10000.00, 'Manual', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- Additional land clearing row covering zone B (STEP-42.6 seed audit)
INSERT INTO public.land_clearing_records (id, site_id, daily_log_id, zone_id, plan_area, actual_area, method, cleared_by)
VALUES
    ('73333333-7777-3333-7777-333333333333', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'e1111111-eeee-1111-eeee-111111111111', 'b2222222-bbbb-2222-bbbb-222222222222', 12000.00, 11500.00, 'Mechanical', '22222222-2222-2222-2222-222222222222')
ON CONFLICT (id) DO NOTHING;

-- NOTE (STEP-42.6 audit): No benchmark_records seed row is included because the
-- table does not exist in any migration under supabase/migrations/ (STEP-36's
-- table was never created). Add a benchmark seed row when that migration lands.
-- geospatial_files rows already omit latitude/longitude (dropped in STEP-34.1).

-- -----------------------------------------------------------------------------
-- SEED INVENTORY ITEMS
-- -----------------------------------------------------------------------------

INSERT INTO public.inventory_items (id, site_id, name, sku, category, quantity, unit, min_threshold)
VALUES
    ('81111111-8888-1111-8888-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'Diesel Fuel', 'DSL-001', 'Fuel', 5000.00, 'Liters', 1000.00),
    ('82222222-8888-2222-8888-222222222222', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'Boundary Stakes', 'STK-050', 'Consumables', 250.00, 'pcs', 50.00)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- SEED GEOSPATIAL FILES METADATA
-- -----------------------------------------------------------------------------

INSERT INTO public.geospatial_files (id, site_id, zone_id, file_name, file_type, drive_file_id, drive_web_view_link, uploaded_by, metadata)
VALUES
    ('91111111-9999-1111-9999-111111111111', 'f47ac10b-58cc-4372-a567-0e02b2c3d479', 'a1111111-aaaa-1111-aaaa-111111111111', 'PIT_Rusia_Topo_20260718.shp', '.shp', '1A2B3C4D5E6F7G8H9I0J', 'https://drive.google.com/file/d/1A2B3C4D5E6F7G8H9I0J/view', '11111111-1111-1111-1111-111111111111', '{"drone_model": "DJI Phantom 4 RTK", "crs": "EPSG:32748"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
