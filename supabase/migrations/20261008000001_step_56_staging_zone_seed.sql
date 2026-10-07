-- STEP-56 / RISK-0030: idempotent staging zone seed for the daily-log E2E round-trip.
-- Data-only (no DDL): guarantees one known zone row exists so journeys reference a
-- real FK target without needing foreman INSERT rights on zones (foremen have no
-- insert policy by design — RISK-0030 records the round-trip this unblocks).
-- Owner-approved 2026-10-08 (SEED approach A from the STEP-56 draft): pin a stable
-- UUID + name for the E2E test site. Re-runnable without duplicating rows.
-- Staging and future environments only; no production data touched by this file.

INSERT INTO public.zones (id, site_id, name, category, description)
VALUES (
    '6e60b2e2-0000-4000-8000-000000005656',
    'f47ac10b-58cc-4372-a567-0e02b2c3d479', -- defaultSiteId (lib/core/constants/app_constants.dart)
    'Pit Alpha',
    'extraction',
    'Seeded E2E zone (STEP-56): stable FK target for daily-log staging round-trip'
)
ON CONFLICT (id) DO NOTHING;
