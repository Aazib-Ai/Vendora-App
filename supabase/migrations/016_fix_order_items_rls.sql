-- Migration 016: Fix order_items RLS infinite recursion
-- Breaks the circular dependency between orders and order_items policies
-- The original policy checked orders table, while orders policy checked order_items

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Order items follow order visibility" ON public.order_items;

-- Create separate policies that check ownership directly without cross-referencing
-- This breaks the circular dependency

-- Allow buyers to read order items for orders they placed
CREATE POLICY "Buyers read own order items"
ON public.order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- Allow sellers to read order items they sold (direct seller_id check)
CREATE POLICY "Sellers read own order items"
ON public.order_items FOR SELECT
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Comments for documentation
COMMENT ON POLICY "Buyers read own order items" ON public.order_items IS 'Buyers can view items from their own orders';
COMMENT ON POLICY "Sellers read own order items" ON public.order_items IS 'Sellers can view items they sold';
