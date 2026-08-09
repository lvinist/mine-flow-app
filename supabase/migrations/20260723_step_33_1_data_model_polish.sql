-- ============================================================================
-- STEP-33.1: Data Model & Repository Polish
-- Date: 2026-07-23
-- Description: 
--   Cut/Fill: Replace cut_volume/fill_volume with bcm_volume/lcm_volume,
--             add material_type column.
--   Land Clearing: Replace area_cleared_ha with plan_area/actual_area,
--                  rename vegetation_type to method.
-- ============================================================================

-- 1. CUT/FILL RECORDS
-- Add new columns
ALTER TABLE public.cut_fill_records
  ADD COLUMN IF NOT EXISTS bcm_volume double precision NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS lcm_volume double precision NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS material_type text;

-- Migrate existing data: copy cut_volume -> bcm_volume, fill_volume -> lcm_volume
UPDATE public.cut_fill_records
SET bcm_volume = COALESCE(cut_volume, 0.0),
    lcm_volume = COALESCE(fill_volume, 0.0)
WHERE bcm_volume = 0.0 AND lcm_volume = 0.0;

-- Drop old columns (after verifying data migration)
ALTER TABLE public.cut_fill_records
  DROP COLUMN IF EXISTS cut_volume,
  DROP COLUMN IF EXISTS fill_volume;

-- 2. LAND CLEARING RECORDS
-- Add new columns
ALTER TABLE public.land_clearing_records
  ADD COLUMN IF NOT EXISTS plan_area double precision NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS actual_area double precision NOT NULL DEFAULT 0.0,
  ADD COLUMN IF NOT EXISTS method text;

-- Migrate existing data: copy area_cleared_ha -> actual_area (convert to m²),
-- and vegetation_type -> method
UPDATE public.land_clearing_records
SET actual_area = COALESCE(area_cleared_ha * 10000.0, 0.0),
    method = vegetation_type
WHERE actual_area = 0.0;

-- Drop old columns
ALTER TABLE public.land_clearing_records
  DROP COLUMN IF EXISTS area_cleared_ha,
  DROP COLUMN IF EXISTS vegetation_type;

-- 3. Update RLS policies remain unchanged (same table names)
-- No policy changes needed for this migration.

-- 4. Indexes for new columns
CREATE INDEX IF NOT EXISTS idx_cut_fill_bcm_lcm
  ON public.cut_fill_records (bcm_volume, lcm_volume);

CREATE INDEX IF NOT EXISTS idx_land_clearing_plan_actual
  ON public.land_clearing_records (plan_area, actual_area);