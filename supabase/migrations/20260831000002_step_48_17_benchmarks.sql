-- STEP-48.17: Benchmark schema
-- geom is JSONB because PostGIS is not enabled in this project. The app treats it as dynamic.

CREATE TABLE IF NOT EXISTS public.benchmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    bm_id TEXT NOT NULL,
    northing DOUBLE PRECISION NOT NULL,
    easting DOUBLE PRECISION NOT NULL,
    ortho_height DOUBLE PRECISION NOT NULL,
    code TEXT NOT NULL,
    orde TEXT NOT NULL,
    geom JSONB,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    crs_identifier TEXT NOT NULL DEFAULT 'UTM Zone 51S',
    ellips_height DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT benchmarks_site_bm_id_key UNIQUE (site_id, bm_id)
);

CREATE INDEX IF NOT EXISTS idx_benchmarks_site_id
    ON public.benchmarks(site_id);
CREATE INDEX IF NOT EXISTS idx_benchmarks_status
    ON public.benchmarks(status);
CREATE INDEX IF NOT EXISTS idx_benchmarks_created_at
    ON public.benchmarks(created_at);

CREATE TRIGGER update_benchmarks_updated_at
BEFORE UPDATE ON public.benchmarks
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

ALTER TABLE public.benchmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY supervisor_benchmarks_all ON public.benchmarks
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

CREATE POLICY foreman_benchmarks_select ON public.benchmarks
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_benchmarks_insert ON public.benchmarks
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_benchmarks_update ON public.benchmarks
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY crew_benchmarks_select ON public.benchmarks
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');
