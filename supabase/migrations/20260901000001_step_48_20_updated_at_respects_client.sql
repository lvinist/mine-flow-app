-- STEP-48.20 re-run (2026-09-01, user-approved): make the audit trigger
-- respect client-supplied timestamps.
--
-- The previous definition set NEW.updated_at = NOW() on EVERY write, which
-- structurally broke the app's last-write-wins sync (48.26 R-6 class): the
-- server stamped rows with its own write-processing time, which is always
-- later than the client's edit time of a follow-up edit made while the
-- previous write was in flight — so every second edit lost LWW and the
-- saved change silently reverted (attendance `sick` → `present`,
-- daily-log `submitted` regressions).
--
-- New semantics:
--   * INSERT without updated_at  → column DEFAULT NOW() fills it (unchanged).
--   * Write WITH updated_at      → client value is kept (LWW versioning).
--   * UPDATE without updated_at  → keeps the row's previous stamp (no
--     anonymous refresh); server-side corrections that matter must supply
--     an explicit updated_at.
-- Replacing the function fixes all tables using this trigger in one place.
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.updated_at IS NULL THEN
        NEW.updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
