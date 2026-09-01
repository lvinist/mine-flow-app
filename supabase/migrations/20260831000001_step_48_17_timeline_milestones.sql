-- STEP-48.17: Timeline milestones schema
-- The project does not enable PostGIS; geom is intentionally not used here.

CREATE TABLE IF NOT EXISTS public.timeline_milestones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    zone_id UUID REFERENCES public.zones(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'general',
    target_value DOUBLE PRECISION,
    actual_value DOUBLE PRECISION,
    target_date TIMESTAMPTZ,
    start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'planned',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_timeline_milestones_site_id
    ON public.timeline_milestones(site_id);
CREATE INDEX IF NOT EXISTS idx_timeline_milestones_zone_id
    ON public.timeline_milestones(zone_id);
CREATE INDEX IF NOT EXISTS idx_timeline_milestones_deleted_at
    ON public.timeline_milestones(deleted_at);
CREATE INDEX IF NOT EXISTS idx_timeline_milestones_target_date
    ON public.timeline_milestones(target_date);

CREATE TRIGGER update_timeline_milestones_updated_at
BEFORE UPDATE ON public.timeline_milestones
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.timeline_milestones ENABLE ROW LEVEL SECURITY;

CREATE POLICY supervisor_timeline_milestones_all ON public.timeline_milestones
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

CREATE POLICY foreman_timeline_milestones_select ON public.timeline_milestones
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_timeline_milestones_insert ON public.timeline_milestones
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_timeline_milestones_update ON public.timeline_milestones
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY crew_timeline_milestones_select ON public.timeline_milestones
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');
