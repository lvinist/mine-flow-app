-- Data Bucket Enhancements: additional columns, constraints, and indexes for geospatial_files
-- Version: 20260718000003
-- Scope: Extend the existing geospatial_files table with fields required by the Data Bucket feature

-- Add new columns for enhanced metadata tracking
ALTER TABLE public.geospatial_files
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS drive_link TEXT,
  ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT,
  ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 7),
  ADD COLUMN IF NOT EXISTS longitude DECIMAL(10, 7),
  ADD COLUMN IF NOT EXISTS notes TEXT;

-- Add CHECK constraint on file_type (existing rows will pass through)
ALTER TABLE public.geospatial_files
  DROP CONSTRAINT IF EXISTS geospatial_files_file_type_check;

ALTER TABLE public.geospatial_files
  ADD CONSTRAINT geospatial_files_file_type_check
  CHECK (file_type IN ('.shp', '.tiff', '.tif', '.dxf', '.dwg', '.csv', '.kml', '.kmz', '.gpx', '.pdf', 'other'));

-- Add indexes for search/filter (IF NOT EXISTS is not supported for indexes, so we use DO blocks)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geospatial_files_site') THEN
    CREATE INDEX idx_geospatial_files_site ON geospatial_files(site_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geospatial_files_zone') THEN
    CREATE INDEX idx_geospatial_files_zone ON geospatial_files(zone_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geospatial_files_type') THEN
    CREATE INDEX idx_geospatial_files_type ON geospatial_files(file_type);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geospatial_files_acquisition') THEN
    CREATE INDEX idx_geospatial_files_acquisition ON geospatial_files(acquisition_date);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_geospatial_files_created') THEN
    CREATE INDEX idx_geospatial_files_created ON geospatial_files(created_at);
  END IF;
END $$;

-- Enable RLS (already enabled in migration 02, but safe to re-run)
ALTER TABLE public.geospatial_files ENABLE ROW LEVEL SECURITY;

-- RLS policies for geospatial_files (idempotent: drop existing then recreate)
-- Supervisors: Full access (already exists as supervisor_geospatial_all in migration 02)
-- Foremen & Crew: Read access (already exists as foremen_crew_geospatial_select in migration 02)
-- Foremen: Insert (already exists as foreman_geospatial_insert in migration 02)
-- Note: policies from migration 02 already cover these cases;
-- this block ensures they exist if this migration runs standalone.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'supervisor_geospatial_all'
  ) THEN
    CREATE POLICY "Supervisors full access" ON geospatial_files
      FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'supervisor' AND deleted_at IS NULL)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'foremen_crew_geospatial_select'
  ) THEN
    CREATE POLICY "Foremen crew geospatial select" ON geospatial_files
      FOR SELECT USING (
        deleted_at IS NULL AND EXISTS (
          SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('foreman', 'crew') AND deleted_at IS NULL
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'foreman_geospatial_insert'
  ) THEN
    CREATE POLICY "Foreman geospatial insert" ON geospatial_files
      FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'foreman' AND deleted_at IS NULL)
      );
  END IF;
END $$;