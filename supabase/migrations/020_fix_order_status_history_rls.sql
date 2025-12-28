-- Migration 020: Fix RLS for order_status_history to allow inserts
-- Addresses the "new row violates row-level security policy" error during checkout

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Status history follows order visibility" ON public.order_status_history;
DROP POLICY IF EXISTS "order_status_history_select" ON public.order_status_history;
DROP POLICY IF EXISTS "order_status_history_insert_buyer" ON public.order_status_history;
DROP POLICY IF EXISTS "order_status_history_insert_seller" ON public.order_status_history;
DROP POLICY IF EXISTS "order_status_history_insert_admin" ON public.order_status_history;

-- 1. SELECT Policy
-- Users can see history if they can see the order
CREATE POLICY "order_status_history_select"
ON public.order_status_history FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
  )
);

-- 2. INSERT Policies

-- Buyers can insert history (e.g. during order creation)
CREATE POLICY "order_status_history_insert_buyer"
ON public.order_status_history FOR INSERT
WITH CHECK (
   -- Allow if user owns the order
   EXISTS (
      SELECT 1 FROM public.orders
      WHERE orders.id = order_status_history.order_id
      AND orders.user_id = auth.uid()
   )
);

-- Sellers can insert history (e.g. when updating status)
CREATE POLICY "order_status_history_insert_seller"
ON public.order_status_history FOR INSERT
WITH CHECK (
   -- Allow if seller has items in this order
   EXISTS (
      SELECT 1 FROM public.order_items
      WHERE order_items.order_id = order_status_history.order_id
      AND order_items.seller_id = (SELECT id FROM public.sellers WHERE user_id = auth.uid() LIMIT 1)
   )
);

-- Admins can insert history
CREATE POLICY "order_status_history_insert_admin"
ON public.order_status_history FOR INSERT
WITH CHECK (public.is_admin());

-- Comments
COMMENT ON POLICY "order_status_history_select" ON public.order_status_history IS 'Users can view status history for orders they have access to';
COMMENT ON POLICY "order_status_history_insert_buyer" ON public.order_status_history IS 'Buyers can add status history (processing/cancelled) for their orders';
COMMENT ON POLICY "order_status_history_insert_seller" ON public.order_status_history IS 'Sellers can add status history (shipped/delivered) for orders containing their items';
