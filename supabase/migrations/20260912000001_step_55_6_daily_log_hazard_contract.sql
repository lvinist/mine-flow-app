-- STEP-55.6: Daily Log structured hazard contract + approval authorization.
--
-- Master spec §4.5 item 7 (`FC-54.6-002`): the Daily Log must persist a
-- structured hazard assessment with an explicit "Tidak ada bahaya" state,
-- severity, notes and corrective action — or it must not ship UI that claims
-- that persistence. The two policy dimensions with no prior doc authority
-- were resolved by the accountable user on 2026-09-12:
--   * severity scale = 4 levels (low / medium / high / critical);
--   * a foreman must answer the hazard question before submitting
--     (`not_assessed` is never a valid submitted state).
--
-- Shape (one aggregate assessment per log, mirroring the Dart entity
-- `HazardAssessment` in lib/features/daily_log/domain/entities):
--   hazard_state    NOT NULL, one of 'not_assessed' | 'none' | 'present'
--   hazard_severity NULL, one of 'low' | 'medium' | 'high' | 'critical',
--                   non-null only when hazard_state = 'present'
--   hazard_notes    NULL trimmed text, meaningful only when present
--   hazard_action   NULL trimmed text (corrective action), same rule
--
-- Additive-only for the columns: NOT NULL state carries a default so existing
-- rows and pre-upgrade clients read back as 'not_assessed' (the domain
-- default). No data backfill is required. Rollback is four DROP COLUMNs plus
-- the two policy/trigger restores noted inline.
--
-- The migration also adds the approval state machine (spec §4.5 items 4/11):
-- exactly `submitted -> approved`, supervisor-only, `approved_by` pinned to
-- the authenticated user, and approved rows immutable. Client-side hiding is
-- backed here so a forged request cannot approve or mutate a log.

-- ---------------------------------------------------------------------------
-- 1. Hazard columns
-- ---------------------------------------------------------------------------

ALTER TABLE public.daily_logs
  ADD COLUMN IF NOT EXISTS hazard_state TEXT NOT NULL DEFAULT 'not_assessed',
  ADD COLUMN IF NOT EXISTS hazard_severity TEXT,
  ADD COLUMN IF NOT EXISTS hazard_notes TEXT,
  ADD COLUMN IF NOT EXISTS hazard_action TEXT;

-- Allowed enumerations (mirror HazardState / HazardSeverity).
ALTER TABLE public.daily_logs
  DROP CONSTRAINT IF EXISTS daily_logs_hazard_state_check;
ALTER TABLE public.daily_logs
  ADD CONSTRAINT daily_logs_hazard_state_check
  CHECK (hazard_state IN ('not_assessed', 'none', 'present'));

ALTER TABLE public.daily_logs
  DROP CONSTRAINT IF EXISTS daily_logs_hazard_severity_check;
ALTER TABLE public.daily_logs
  ADD CONSTRAINT daily_logs_hazard_severity_check
  CHECK (
    hazard_severity IS NULL
    OR hazard_severity IN ('low', 'medium', 'high', 'critical')
  );

-- Coherence: severity is required iff a hazard is present; notes/action exist
-- only when a hazard is present. This is the server twin of
-- `HazardAssessment.isValid` + `normalized()`, so a client that skips the
-- normalizer still cannot persist an incoherent assessment.
ALTER TABLE public.daily_logs
  DROP CONSTRAINT IF EXISTS daily_logs_hazard_coherence_check;
ALTER TABLE public.daily_logs
  ADD CONSTRAINT daily_logs_hazard_coherence_check
  CHECK (
    (hazard_state = 'present' AND hazard_severity IS NOT NULL)
    OR (
      hazard_state IN ('none', 'not_assessed')
      AND hazard_severity IS NULL
      AND (hazard_notes IS NULL OR btrim(hazard_notes) = '')
      AND (hazard_action IS NULL OR btrim(hazard_action) = '')
    )
  );

-- ---------------------------------------------------------------------------
-- 2. Approval state machine (BEFORE UPDATE trigger)
-- ---------------------------------------------------------------------------
--
-- RLS policies alone cannot see OLD vs NEW, so the legal transitions and the
-- approver attribution are enforced by a trigger. Legal transitions:
--   draft     -> draft | submitted   (foreman edits / submit)
--   submitted -> submitted | approved (supervisor inspect / approve)
--   approved  -> approved             (immutable; only metadata may change)
-- Anything else raises, so an illegal jump or a re-approval fails loudly.

CREATE OR REPLACE FUNCTION public.enforce_daily_log_transition()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor_role public.user_role;
BEGIN
  actor_role := public.current_user_role();

  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF OLD.status = 'draft' AND NEW.status = 'submitted' THEN
      -- Foreman submit: allowed for the row owner (RLS already scopes the
      -- foreman update policy to own draft rows).
      NULL;
    ELSIF OLD.status = 'submitted' AND NEW.status = 'approved' THEN
      IF actor_role <> 'supervisor' THEN
        RAISE EXCEPTION
          'Only a supervisor may approve a daily log (actor role: %)',
          actor_role;
      END IF;
      IF NEW.approved_by IS DISTINCT FROM auth.uid() THEN
        RAISE EXCEPTION
          'approved_by must be the authenticated supervisor';
      END IF;
    ELSE
      RAISE EXCEPTION
        'Illegal daily log status transition % -> %',
        OLD.status, NEW.status;
    END IF;
  END IF;

  -- Approved rows are immutable in this workflow: status and attribution are
  -- frozen. (A no-op re-approval attempt therefore also fails above.)
  IF OLD.status = 'approved' THEN
    IF NEW.status IS DISTINCT FROM 'approved'
       OR NEW.approved_by IS DISTINCT FROM OLD.approved_by THEN
      RAISE EXCEPTION 'Approved daily logs are immutable';
    END IF;
  END IF;

  -- `approved_by` is meaningful only for approved rows: a draft/submitted
  -- write may never carry an approver, so a forged client cannot pin
  -- attribution before the supervisor actually approves.
  IF NEW.status <> 'approved' AND NEW.approved_by IS NOT NULL THEN
    RAISE EXCEPTION 'approved_by may only be set when status = approved';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_daily_log_transition ON public.daily_logs;
CREATE TRIGGER enforce_daily_log_transition
BEFORE UPDATE ON public.daily_logs
FOR EACH ROW EXECUTE FUNCTION public.enforce_daily_log_transition();

-- ---------------------------------------------------------------------------
-- 3. Foreman isolation + approval gating (policy tightening)
-- ---------------------------------------------------------------------------
--
-- The STEP-55.6 review workflow requires a foreman to see and edit only their
-- own logs (spec §4.5 items 1/11) and never to reach the approved state. The
-- pre-existing foreman policies were role-only; they are replaced with
-- own-scope + draft-only variants. The supervisor policies are left as-is
-- because the trigger above now constrains their transitions too.

DROP POLICY IF EXISTS foreman_daily_logs_select ON public.daily_logs;
CREATE POLICY foreman_daily_logs_select ON public.daily_logs
  FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND public.current_user_role() = 'foreman'
    AND foreman_id = auth.uid()
  );

-- Insert keeps the role + ownership scope. `submitted` is permitted so the
-- client's local-first upsert (INSERT ... ON CONFLICT DO UPDATE) of an
-- already-submitted row is not rejected by the INSERT WITH CHECK arm.
DROP POLICY IF EXISTS foreman_daily_logs_insert ON public.daily_logs;
CREATE POLICY foreman_daily_logs_insert ON public.daily_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    public.current_user_role() = 'foreman'
    AND foreman_id = auth.uid()
    AND status IN ('draft', 'submitted')
  );

-- Update is limited to own rows that are still drafts; the row may only move
-- to draft or submitted. A foreman can therefore never edit a submitted or
-- approved log, and never set `approved`.
DROP POLICY IF EXISTS foreman_daily_logs_update ON public.daily_logs;
CREATE POLICY foreman_daily_logs_update ON public.daily_logs
  FOR UPDATE TO authenticated
  USING (
    public.current_user_role() = 'foreman'
    AND foreman_id = auth.uid()
    AND status = 'draft'
  )
  WITH CHECK (
    public.current_user_role() = 'foreman'
    AND foreman_id = auth.uid()
    AND status IN ('draft', 'submitted')
  );
