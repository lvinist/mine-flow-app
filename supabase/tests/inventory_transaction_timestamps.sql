-- LOCAL-only regression, run inside a transaction after the synthetic legacy
-- fixture and (for GREEN) the timestamp migration. Caller rolls everything back.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT set_config('request.jwt.claim.sub','55550000-0000-4000-8000-000000000011',true);
SELECT public.adjust_inventory(
 '55550000-0000-4000-8000-000000000012',2,'timestamp fixture',
 '55550000-0000-4000-8000-000000000011','timestamp-new','2002-01-01T00:00:00Z');
DO $$
DECLARE actual timestamptz;
BEGIN
 SELECT created_at INTO actual FROM public.inventory_transactions WHERE idempotency_key='timestamp-new';
 IF actual IS NULL OR actual < transaction_timestamp() OR actual > clock_timestamp() THEN
   RAISE EXCEPTION 'REGRESSION: ledger audit timestamp trusts the client clock';
 END IF;
 RAISE NOTICE 'PASS: new ledger created_at is server-authored';
END;
$$;

DO $$
DECLARE before_quantity numeric; before_audit timestamptz; rows_before integer;
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.inventory_transactions
   WHERE idempotency_key='timestamp-legacy' AND created_at='2000-01-01T00:00:00Z'
     AND occurred_at=created_at AND created_at_source='legacy_client') THEN
   RAISE EXCEPTION 'Legacy timestamp was rewritten or falsely labelled server';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM public.inventory_transactions
   WHERE idempotency_key='timestamp-new' AND occurred_at='2002-01-01T00:00:00Z'
     AND created_at_source='server') THEN
   RAISE EXCEPTION 'Client event time or new audit provenance lost';
 END IF;
 SELECT quantity INTO before_quantity FROM public.inventory_items
   WHERE id='55550000-0000-4000-8000-000000000012';
 SELECT created_at INTO before_audit FROM public.inventory_transactions WHERE idempotency_key='timestamp-new';
 SELECT count(*) INTO rows_before FROM public.inventory_transactions;
 PERFORM public.adjust_inventory('55550000-0000-4000-8000-000000000012',2,'retry',
   '55550000-0000-4000-8000-000000000011','timestamp-new','2002-01-01T00:00:00Z');
 IF (SELECT quantity FROM public.inventory_items WHERE id='55550000-0000-4000-8000-000000000012') <> before_quantity
   OR (SELECT count(*) FROM public.inventory_transactions) <> rows_before
   OR (SELECT created_at FROM public.inventory_transactions WHERE idempotency_key='timestamp-new') <> before_audit THEN
   RAISE EXCEPTION 'Replay changed stock, ledger count or audit timestamp';
 END IF;
 BEGIN
   PERFORM public.adjust_inventory('55550000-0000-4000-8000-000000000012',2,'invalid event',
     '55550000-0000-4000-8000-000000000011','timestamp-null',NULL);
   RAISE EXCEPTION 'Null event time unexpectedly accepted';
 EXCEPTION WHEN not_null_violation THEN NULL;
 END;
 IF (SELECT quantity FROM public.inventory_items WHERE id='55550000-0000-4000-8000-000000000012') <> before_quantity
   OR EXISTS (SELECT 1 FROM public.inventory_transactions WHERE idempotency_key='timestamp-null') THEN
   RAISE EXCEPTION 'Failed transaction did not roll back quantity and ledger';
 END IF;
 IF (SELECT created_at FROM public.inventory_items WHERE id='55550000-0000-4000-8000-000000000012') <> '2001-01-01T00:00:00Z' THEN
   RAISE EXCEPTION 'Item creation time must remain client-authored and unchanged';
 END IF;
 RAISE NOTICE 'PASS: legacy provenance, event time, replay, rollback and item timestamp preserved';
END;
$$;

INSERT INTO public.inventory_transactions(item_id,delta,reason,actor_id,idempotency_key,
 occurred_at,created_at,created_at_source) VALUES
 ('55550000-0000-4000-8000-000000000012',1,'spoof attempt',
 '55550000-0000-4000-8000-000000000011','timestamp-spoof',
 '2003-01-01T00:00:00Z','1900-01-01T00:00:00Z','legacy_client');
DO $$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.inventory_transactions WHERE idempotency_key='timestamp-spoof'
   AND created_at >= transaction_timestamp() AND created_at <= clock_timestamp()
   AND created_at_source='server' AND occurred_at='2003-01-01T00:00:00Z') THEN
   RAISE EXCEPTION 'Direct insert can forge server audit time or legacy provenance';
 END IF;
 RAISE NOTICE 'PASS: direct INSERT cannot spoof audit timestamp or provenance';
END;
$$;
