-- STEP-48.21 (re-run): add the missing `notes` column the tracking forms write.
--
-- Root cause found by the re-run's first notes-bearing journey save:
-- `cut_fill_model.dart` / `land_clearing_model.dart` / `inventory_item_model.dart`
-- all serialize `notes` (the UI labels it "Catatan" / "Catatan Terrain"), but no
-- migration ever added the column to any of the three tables. `daily_logs` and
-- `geospatial_files` have it; these three never did — the committed TS contract
-- (`supabase/types/database.ts`, generated from the real DB) never contained it.
-- Every save carrying notes failed with
-- `PGRST204 Could not find the 'notes' column of '<table>' in the schema cache`,
-- and PostgREST rejects the whole statement, so the row never persisted (silently:
-- the app queues it, retries 3x, and moves on). This is the same schema-gap class
-- as BH-005 (`item_name`) / BH-006 (`status`) that 48.19 remediated; 48.19's audit
-- swept only its named keys, so `notes` survived at a second, unswept site.
--
-- Additive-only: nullable TEXT, no default, no RLS/policy or data change. The
-- tables already have per-role policies that govern whole-row access, so a new
-- nullable column needs no policy edit. Rollback is three `DROP COLUMN`s.

ALTER TABLE public.cut_fill_records
  ADD COLUMN IF NOT EXISTS notes TEXT;

ALTER TABLE public.land_clearing_records
  ADD COLUMN IF NOT EXISTS notes TEXT;

ALTER TABLE public.inventory_items
  ADD COLUMN IF NOT EXISTS notes TEXT;
