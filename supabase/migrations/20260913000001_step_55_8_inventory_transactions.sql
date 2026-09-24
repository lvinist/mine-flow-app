CREATE TABLE public.inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL DEFAULT '00000000-0000-0000-0000-000000000001',
    item_id UUID NOT NULL REFERENCES public.inventory_items(id) ON DELETE CASCADE,
    delta NUMERIC(10,2) NOT NULL,
    reason TEXT NOT NULL,
    actor_id UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    idempotency_key TEXT UNIQUE
);

ALTER TABLE public.inventory_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_inventory_transactions ON public.inventory_transactions
    FOR SELECT
    USING (
        auth.uid() = actor_id OR
        public.current_user_role() IN ('supervisor', 'foreman', 'crew')
    );

CREATE POLICY insert_inventory_transactions ON public.inventory_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = actor_id);

CREATE OR REPLACE FUNCTION public.adjust_inventory(
    p_item_id UUID,
    p_delta NUMERIC,
    p_reason TEXT,
    p_actor_id UUID,
    p_idempotency_key TEXT,
    p_created_at TIMESTAMPTZ
) RETURNS void AS $$
DECLARE
    v_new_quantity NUMERIC(10,2);
BEGIN
    -- Check for idempotency
    IF p_idempotency_key IS NOT NULL AND EXISTS (
        SELECT 1 FROM public.inventory_transactions WHERE idempotency_key = p_idempotency_key
    ) THEN
        RETURN;
    END IF;

    -- Update inventory item
    UPDATE public.inventory_items
    SET quantity = quantity + p_delta,
        updated_at = GREATEST(updated_at, p_created_at)
    WHERE id = p_item_id
    RETURNING quantity INTO v_new_quantity;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item not found';
    END IF;

    -- Insert transaction
    INSERT INTO public.inventory_transactions (
        item_id, delta, reason, actor_id, idempotency_key, created_at
    ) VALUES (
        p_item_id, p_delta, p_reason, p_actor_id, p_idempotency_key, p_created_at
    );
END;
$$ LANGUAGE plpgsql SECURITY INVOKER;
