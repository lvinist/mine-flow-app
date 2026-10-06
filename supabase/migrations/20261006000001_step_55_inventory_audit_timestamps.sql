-- STEP-55 owner decisions (2026-10-06): separate client event time from server
-- audit time. Preserve historical created_at values and label them honestly.
-- Inventory-item created_at intentionally remains client-authored and unchanged.
-- Preparation/local testing only; remote deployment requires separate approval.

ALTER TABLE public.inventory_transactions
    ADD COLUMN occurred_at timestamptz,
    ADD COLUMN created_at_source text NOT NULL DEFAULT 'legacy_client'
        CHECK (created_at_source IN ('legacy_client', 'server'));

-- Existing timestamps cannot be retroactively called server observations.
UPDATE public.inventory_transactions SET occurred_at = created_at;
ALTER TABLE public.inventory_transactions
    ALTER COLUMN occurred_at SET NOT NULL,
    ALTER COLUMN created_at_source SET DEFAULT 'server';

COMMENT ON COLUMN public.inventory_transactions.occurred_at IS
'Client-reported event time, retained across offline replay; not trusted server audit time.';
COMMENT ON COLUMN public.inventory_transactions.created_at IS
'Server-authored insert time for source=server; preserved original client timestamp for source=legacy_client.';
COMMENT ON COLUMN public.inventory_transactions.created_at_source IS
'Provenance of created_at. legacy_client rows predate the audit-time migration; all subsequent inserts are server.';

-- A column default alone can be overridden by a caller. Enforce both the time
-- and its provenance for every new row, including a direct INSERT under RLS.
CREATE FUNCTION public.stamp_inventory_transaction_audit_time()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
    NEW.created_at := statement_timestamp();
    NEW.created_at_source := 'server';
    RETURN NEW;
END;
$$;

CREATE TRIGGER stamp_inventory_transaction_audit_time
BEFORE INSERT ON public.inventory_transactions
FOR EACH ROW EXECUTE FUNCTION public.stamp_inventory_transaction_audit_time();

-- Keep the existing RPC signature so queued offline clients can drain safely.
-- p_created_at now names event time only; item LWW ordering remains unchanged.
CREATE OR REPLACE FUNCTION public.adjust_inventory(
    p_item_id uuid,
    p_delta numeric,
    p_reason text,
    p_actor_id uuid,
    p_idempotency_key text,
    p_created_at timestamptz
) RETURNS void
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
    v_new_quantity numeric(10,2);
BEGIN
    IF p_idempotency_key IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.inventory_transactions WHERE idempotency_key = p_idempotency_key
    ) THEN
        RETURN;
    END IF;

    UPDATE public.inventory_items
    SET quantity = quantity + p_delta,
        updated_at = GREATEST(updated_at, p_created_at)
    WHERE id = p_item_id
    RETURNING quantity INTO v_new_quantity;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item not found';
    END IF;

    INSERT INTO public.inventory_transactions (
        item_id, delta, reason, actor_id, idempotency_key, occurred_at
    ) VALUES (
        p_item_id, p_delta, p_reason, p_actor_id, p_idempotency_key, p_created_at
    );
END;
$$;
