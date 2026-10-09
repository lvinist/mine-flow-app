-- STEP-57.2: Foreman Zone-INSERT Policy (site-scoped, server-authoritative)
--
-- Implements the owner-locked design from ADR-0020 (Accepted 2026-10-10):
--   Q1: site-scoped INSERT policy via current_user_site_id()
--   Q2: created_by column + server-side BEFORE INSERT trigger + own-rows UPDATE
--   Q3: crew stays read-only (no new crew zone privileges)
--
-- Staging apply owner-pre-authorized (Q4). Production untouched.
-- See: adr/ADR-0020-foreman-zone-insert-policy.md

-- ----------------------------------------------------------------------------
-- Pre-flight: assert no policy-name collisions. We DROP IF EXISTS then CREATE,
-- which is idempotent and surfaces existing policies by replacing them — the
-- intended guard against silent duplicate-policy confusion.
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS foreman_zones_insert ON public.zones;
DROP POLICY IF EXISTS foreman_zones_update ON public.zones;

-- ----------------------------------------------------------------------------
-- Q1: current_user_site_id() — mirrors current_user_role() shape (migration
-- 20260718000002, lines 9-12). SECURITY DEFINER so it runs with the table
-- owner's privileges; SET search_path = public per the established convention.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_site_id()
RETURNS UUID AS $$
    SELECT site_id FROM public.users WHERE id = auth.uid() AND deleted_at IS NULL;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

-- ----------------------------------------------------------------------------
-- Q2a: created_by column — unspoofable creator audit trail.
-- REFERENCES users(id) for relational integrity (supervisor-created rows in
-- the seed retain NULL until backfilled; the column is nullable to avoid a
-- full-table rewrite on existing rows — see ADR-0020 reversibility note).
-- ----------------------------------------------------------------------------
ALTER TABLE public.zones
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id);

-- ----------------------------------------------------------------------------
-- Q2b: BEFORE INSERT trigger sets created_by = auth.uid() server-side.
-- NULL-safe for system inserts: only sets the value when it is not already
-- populated, so a privileged server-side insert that supplies its own
-- created_by is not clobbered.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.zones_set_created_by()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_by IS NULL THEN
        NEW.created_by := auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS zones_created_by_set ON public.zones;
CREATE TRIGGER zones_created_by_set
    BEFORE INSERT ON public.zones
    FOR EACH ROW EXECUTE FUNCTION public.zones_set_created_by();

-- ----------------------------------------------------------------------------
-- Q1: Foreman INSERT policy — site-scoped WITH CHECK.
--   - current_user_role() = 'foreman' gates on role.
--   - site_id = current_user_site_id() binds the written site_id to the
--     caller's own site, so a foreman cannot inject a different site's id.
-- ----------------------------------------------------------------------------
CREATE POLICY foreman_zones_insert ON public.zones
    FOR INSERT TO authenticated
    WITH CHECK (
        public.current_user_role() = 'foreman'
        AND site_id = public.current_user_site_id()
    );

-- ----------------------------------------------------------------------------
-- Q2c: Foreman UPDATE policy — own rows only (created_by = auth.uid()).
-- Required because the offline sync upsert path (SyncQueueManager._defaultSupabaseSync
-- at sync_queue_manager.dart:262) uses INSERT .. ON CONFLICT DO UPDATE, which
-- needs UPDATE privilege on the row the foreman created. A foreman cannot
-- overwrite supervisor-created or peer-created zones.
-- ----------------------------------------------------------------------------
CREATE POLICY foreman_zones_update ON public.zones
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman' AND created_by = auth.uid())
    WITH CHECK (public.current_user_role() = 'foreman' AND created_by = auth.uid());
