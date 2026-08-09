-- ============================================================================
-- STEP-34.1: Drop latitude/longitude columns from geospatial_files
-- Date: 2026-07-23
-- Description:
--   Remove unused latitude and longitude fields from the GeospatialFile
--   entity, as these coordinates are no longer needed in the Data Bucket.
-- ============================================================================

ALTER TABLE public.geospatial_files
  DROP COLUMN IF EXISTS latitude,
  DROP COLUMN IF EXISTS longitude;

-- Drop indexes on these columns if they exist
DROP INDEX IF EXISTS idx_geospatial_files_latitude;
DROP INDEX IF EXISTS idx_geospatial_files_longitude;