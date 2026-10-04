-- STEP-55 / RISK-0025: preserve supervisor administration while constraining
-- ordinary self-service profile changes at the database boundary.
-- Owner-approved allow-list (2026-10-04): name, phone, emergency_contact_name,
-- emergency_contact_phone. Identity, role, site, lifecycle and audit fields are
-- not self-editable. RLS still determines which rows the caller may update.
-- Deployment is separately owner-gated; this migration is first tested locally.

CREATE OR REPLACE FUNCTION public.guard_user_self_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
    -- Trusted server/database administration and existing supervisor workflows
    -- retain their prior rights. SECURITY INVOKER is essential: CURRENT_USER
    -- must be the caller, not the migration owner. Never trust user_metadata.
    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
        WHERE rolname = CURRENT_USER AND (rolsuper OR rolbypassrls)
    ) OR public.current_user_role() = 'supervisor'::public.user_role THEN
        RETURN NEW;
    END IF;

    -- A JSONB allow-list fails closed when a future protected column is added.
    -- The guard runs alphabetically before update_users_updated_at, so the
    -- server may still stamp an allowed edit without permitting forged audit
    -- timestamps in the incoming row.
    IF OLD.id IS DISTINCT FROM auth.uid()
       OR (pg_catalog.to_jsonb(NEW) - ARRAY[
           'name', 'phone', 'emergency_contact_name', 'emergency_contact_phone'
       ]) IS DISTINCT FROM (pg_catalog.to_jsonb(OLD) - ARRAY[
           'name', 'phone', 'emergency_contact_name', 'emergency_contact_phone'
       ]) THEN
        RAISE EXCEPTION USING
            ERRCODE = '42501',
            MESSAGE = 'Self-service profile updates are limited to name and contact details';
    END IF;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.guard_user_self_update() IS
'RISK-0025: database-enforced self-profile field allow-list; supervisors and trusted server roles retain administration rights.';

CREATE TRIGGER guard_users_self_update
BEFORE UPDATE ON public.users
FOR EACH ROW EXECUTE FUNCTION public.guard_user_self_update();
