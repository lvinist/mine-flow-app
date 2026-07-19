-- Core Database Schema Migration for mine-flow
-- Version: 20260718000001
-- Scope: 9 core entities, enums, triggers, multi-tenancy site_id, and timestamps

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- ENUMS
-- -----------------------------------------------------------------------------

CREATE TYPE public.user_role AS ENUM ('supervisor', 'foreman', 'crew');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent', 'sick', 'leave');
CREATE TYPE public.equipment_type AS ENUM ('gnss', 'total_station', 'drone');
CREATE TYPE public.log_status AS ENUM ('draft', 'submitted', 'approved');

-- -----------------------------------------------------------------------------
-- AUDIT TRAIL / TRIGGER FUNCTION
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 1. USERS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    role public.user_role NOT NULL DEFAULT 'crew',
    national_id TEXT,
    birthdate DATE,
    phone TEXT,
    gender TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 2. ZONES TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    name TEXT NOT NULL,
    category TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_zones_updated_at
BEFORE UPDATE ON public.zones
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 3. ATTENDANCE RECORDS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status public.attendance_status NOT NULL DEFAULT 'present',
    remarks TEXT,
    logged_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT unique_user_attendance_per_day UNIQUE (user_id, date)
);

CREATE TRIGGER update_attendance_records_updated_at
BEFORE UPDATE ON public.attendance_records
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 4. EQUIPMENT CHECKS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.equipment_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    foreman_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    equipment_type public.equipment_type NOT NULL,
    serial_number TEXT,
    check_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_type TEXT NOT NULL DEFAULT 'pre_work', -- 'pre_work' or 'post_work'
    is_operational BOOLEAN NOT NULL DEFAULT true,
    checklist_data JSONB NOT NULL DEFAULT '{}'::jsonb,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_equipment_checks_updated_at
BEFORE UPDATE ON public.equipment_checks
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 5. DAILY LOGS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.daily_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    foreman_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    zone_id UUID REFERENCES public.zones(id) ON DELETE SET NULL,
    status public.log_status NOT NULL DEFAULT 'draft',
    summary TEXT,
    weather TEXT,
    notes TEXT,
    approved_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_daily_logs_updated_at
BEFORE UPDATE ON public.daily_logs
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 6. CUT / FILL RECORDS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.cut_fill_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE,
    zone_id UUID NOT NULL REFERENCES public.zones(id) ON DELETE CASCADE,
    cut_volume NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    fill_volume NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    elevation_change NUMERIC(8,2),
    measured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    measured_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_cut_fill_records_updated_at
BEFORE UPDATE ON public.cut_fill_records
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 7. LAND CLEARING RECORDS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.land_clearing_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    daily_log_id UUID REFERENCES public.daily_logs(id) ON DELETE CASCADE,
    zone_id UUID NOT NULL REFERENCES public.zones(id) ON DELETE CASCADE,
    area_cleared_ha NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    vegetation_type TEXT,
    cleared_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    cleared_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_land_clearing_records_updated_at
BEFORE UPDATE ON public.land_clearing_records
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 8. INVENTORY ITEMS TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    name TEXT NOT NULL,
    sku TEXT,
    category TEXT,
    quantity NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    unit TEXT NOT NULL DEFAULT 'pcs',
    min_threshold NUMERIC(10,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_inventory_items_updated_at
BEFORE UPDATE ON public.inventory_items
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 9. GEOSPATIAL FILES METADATA TABLE
-- -----------------------------------------------------------------------------

CREATE TABLE public.geospatial_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    zone_id UUID REFERENCES public.zones(id) ON DELETE SET NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL, -- '.shp', '.tiff', etc.
    drive_file_id TEXT NOT NULL,
    drive_web_view_link TEXT,
    acquisition_date TIMESTAMPTZ,
    uploaded_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE TRIGGER update_geospatial_files_updated_at
BEFORE UPDATE ON public.geospatial_files
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
