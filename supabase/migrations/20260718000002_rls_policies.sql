-- Row-Level Security (RLS) Policies Migration for mine-flow
-- Version: 20260718000002
-- Scope: RLS activation on all 9 tables and role-based policies (supervisor, foreman, crew)

-- -----------------------------------------------------------------------------
-- HELPER FUNCTIONS FOR RLS
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS public.user_role AS $$
    SELECT role FROM public.users WHERE id = auth.uid() AND deleted_at IS NULL;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

-- -----------------------------------------------------------------------------
-- ENABLE RLS ON ALL TABLES
-- -----------------------------------------------------------------------------

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cut_fill_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.land_clearing_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geospatial_files ENABLE ROW LEVEL SECURITY;

-- -----------------------------------------------------------------------------
-- 1. USERS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access to all user accounts
CREATE POLICY supervisor_users_all ON public.users
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen & Crew: Read access to active users (for crew list/dropdown selection)
CREATE POLICY users_read_active ON public.users
    FOR SELECT TO authenticated
    USING (
        deleted_at IS NULL AND (
            public.current_user_role() IN ('foreman', 'crew') OR
            id = auth.uid()
        )
    );

-- Users: Update own profile details (phone, emergency contact)
CREATE POLICY users_update_self ON public.users
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- -----------------------------------------------------------------------------
-- 2. ZONES POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_zones_all ON public.zones
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen & Crew: Read access to active zones
CREATE POLICY zones_read_active ON public.zones
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() IN ('foreman', 'crew'));

-- -----------------------------------------------------------------------------
-- 3. ATTENDANCE RECORDS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_attendance_all ON public.attendance_records
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Read, Insert, Update attendance records for site
CREATE POLICY foreman_attendance_select ON public.attendance_records
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_attendance_insert ON public.attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_attendance_update ON public.attendance_records
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read own attendance, Insert own attendance
CREATE POLICY crew_attendance_select ON public.attendance_records
    FOR SELECT TO authenticated
    USING (user_id = auth.uid() AND deleted_at IS NULL AND public.current_user_role() = 'crew');

CREATE POLICY crew_attendance_insert ON public.attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid() AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 4. EQUIPMENT CHECKS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_equipment_all ON public.equipment_checks
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Manage equipment checks
CREATE POLICY foreman_equipment_select ON public.equipment_checks
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_equipment_insert ON public.equipment_checks
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_equipment_update ON public.equipment_checks
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read equipment checks
CREATE POLICY crew_equipment_select ON public.equipment_checks
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 5. DAILY LOGS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_daily_logs_all ON public.daily_logs
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Read, insert, update daily logs
CREATE POLICY foreman_daily_logs_select ON public.daily_logs
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_daily_logs_insert ON public.daily_logs
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_daily_logs_update ON public.daily_logs
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read approved daily logs
CREATE POLICY crew_daily_logs_select ON public.daily_logs
    FOR SELECT TO authenticated
    USING (status = 'approved' AND deleted_at IS NULL AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 6. CUT / FILL RECORDS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_cut_fill_all ON public.cut_fill_records
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Manage cut/fill records
CREATE POLICY foreman_cut_fill_select ON public.cut_fill_records
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_cut_fill_insert ON public.cut_fill_records
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_cut_fill_update ON public.cut_fill_records
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read cut/fill records
CREATE POLICY crew_cut_fill_select ON public.cut_fill_records
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 7. LAND CLEARING RECORDS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_land_clearing_all ON public.land_clearing_records
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Manage land clearing records
CREATE POLICY foreman_land_clearing_select ON public.land_clearing_records
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_land_clearing_insert ON public.land_clearing_records
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_land_clearing_update ON public.land_clearing_records
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read land clearing records
CREATE POLICY crew_land_clearing_select ON public.land_clearing_records
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 8. INVENTORY ITEMS POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_inventory_all ON public.inventory_items
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen: Manage inventory items
CREATE POLICY foreman_inventory_select ON public.inventory_items
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'foreman');

CREATE POLICY foreman_inventory_insert ON public.inventory_items
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');

CREATE POLICY foreman_inventory_update ON public.inventory_items
    FOR UPDATE TO authenticated
    USING (public.current_user_role() = 'foreman')
    WITH CHECK (public.current_user_role() = 'foreman');

-- Crew: Read inventory items
CREATE POLICY crew_inventory_select ON public.inventory_items
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() = 'crew');

-- -----------------------------------------------------------------------------
-- 9. GEOSPATIAL FILES POLICIES
-- -----------------------------------------------------------------------------

-- Supervisors: Full access
CREATE POLICY supervisor_geospatial_all ON public.geospatial_files
    FOR ALL TO authenticated
    USING (public.current_user_role() = 'supervisor');

-- Foremen & Crew: Read geospatial metadata
CREATE POLICY foremen_crew_geospatial_select ON public.geospatial_files
    FOR SELECT TO authenticated
    USING (deleted_at IS NULL AND public.current_user_role() IN ('foreman', 'crew'));

-- Foremen: Upload/Insert geospatial metadata
CREATE POLICY foreman_geospatial_insert ON public.geospatial_files
    FOR INSERT TO authenticated
    WITH CHECK (public.current_user_role() = 'foreman');
