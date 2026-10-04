-- RISK-0025: executable permissions regression; synthetic fixtures roll back.
-- Run with psql -X -v ON_ERROR_STOP=1 -f this_file against a LOCAL test database.
-- The caller must be the local test database owner; never run against live data.
BEGIN;
INSERT INTO auth.users (id) VALUES
 ('55550000-0000-4000-8000-000000000001'),
 ('55550000-0000-4000-8000-000000000002'),
 ('55550000-0000-4000-8000-000000000003');
INSERT INTO public.users (id,email,name,role) VALUES
 ('55550000-0000-4000-8000-000000000001','step55-crew@example.invalid','Fixture crew','crew'),
 ('55550000-0000-4000-8000-000000000002','step55-foreman@example.invalid','Fixture foreman','foreman'),
 ('55550000-0000-4000-8000-000000000003','step55-supervisor@example.invalid','Fixture supervisor','supervisor');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claim.sub','55550000-0000-4000-8000-000000000001',true);

-- This is the original exploit. On the vulnerable schema UPDATE succeeds and
-- the explicit assertion fails; SQLSTATE 42501 is the only accepted rejection.
DO $$
BEGIN
  BEGIN
    UPDATE public.users SET role='supervisor' WHERE id=auth.uid();
    RAISE EXCEPTION 'REGRESSION: crew can self-promote to supervisor';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'PASS: crew self-promotion rejected';
  END;
END;
$$;

-- Exercise the complete owner-approved allow-list for both ordinary roles.
DO $$
DECLARE
  actor uuid;
  assignment text;
  changed integer;
  denied integer := 0;
BEGIN
  FOREACH actor IN ARRAY ARRAY[
    '55550000-0000-4000-8000-000000000001'::uuid,
    '55550000-0000-4000-8000-000000000002'::uuid
  ] LOOP
    PERFORM set_config('request.jwt.claim.sub',actor::text,true);
    UPDATE public.users SET name='Updated fixture', phone='00000000',
      emergency_contact_name='Fixture contact', emergency_contact_phone='11111111'
      WHERE id=actor;
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 1 OR NOT EXISTS (
      SELECT 1 FROM public.users WHERE id=actor AND name='Updated fixture'
        AND phone='00000000' AND emergency_contact_name='Fixture contact'
        AND emergency_contact_phone='11111111'
    ) THEN RAISE EXCEPTION 'Allowed self-profile edit failed for %',actor; END IF;
    RAISE NOTICE 'PASS: allowed profile fields for %',actor;

    FOREACH assignment IN ARRAY ARRAY[
      'role=''supervisor''',
      'site_id=''55550000-0000-4000-8000-000000000099''::uuid',
      'is_active=false',
      'deleted_at=now()',
      'email=''unapproved@example.invalid''',
      'national_id=''synthetic-national-id''',
      'birthdate=''2000-01-01''::date',
      'gender=''synthetic''',
      'created_at=''2000-01-01''::timestamptz',
      'updated_at=''2000-01-01''::timestamptz'
    ] LOOP
      BEGIN
        EXECUTE format('UPDATE public.users SET %s WHERE id=$1',assignment) USING actor;
        RAISE EXCEPTION 'REGRESSION: protected field update accepted: %',assignment;
      EXCEPTION WHEN insufficient_privilege THEN
        denied := denied + 1;
      END;
    END LOOP;
    UPDATE public.users SET name='Unauthorized other account' WHERE id='55550000-0000-4000-8000-000000000003';
    GET DIAGNOSTICS changed = ROW_COUNT;
    IF changed <> 0 THEN RAISE EXCEPTION 'Ordinary user changed another account'; END IF;
    RAISE NOTICE 'PASS: another account remains protected for %',actor;
  END LOOP;
  IF denied <> 20 THEN RAISE EXCEPTION 'Expected 20 protected-field rejections, got %',denied; END IF;
  RAISE NOTICE 'PASS: 20 protected-field updates rejected';
END;
$$;

-- Preserve documented supervisor account-management rights.
SELECT set_config('request.jwt.claim.sub','55550000-0000-4000-8000-000000000003',true);
DO $$
BEGIN
  UPDATE public.users SET role='foreman',is_active=false,national_id='admin-managed-fixture'
    WHERE id='55550000-0000-4000-8000-000000000001';
  IF NOT EXISTS (SELECT 1 FROM public.users
    WHERE id='55550000-0000-4000-8000-000000000001' AND role='foreman'
      AND is_active=false AND national_id='admin-managed-fixture')
  THEN RAISE EXCEPTION 'Supervisor account management regressed'; END IF;
  RAISE NOTICE 'PASS: supervisor account management preserved';
END;
$$;

RESET ROLE;
SET LOCAL ROLE service_role;
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','service_role',true);
DO $$
BEGIN
  UPDATE public.users SET role='crew',is_active=true
    WHERE id='55550000-0000-4000-8000-000000000001';
  IF NOT EXISTS (SELECT 1 FROM public.users
    WHERE id='55550000-0000-4000-8000-000000000001' AND role='crew' AND is_active)
  THEN RAISE EXCEPTION 'Trusted server administration regressed'; END IF;
  RAISE NOTICE 'PASS: trusted server administration preserved';
END;
$$;
ROLLBACK;
