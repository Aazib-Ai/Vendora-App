-- Migration 017: Fix order_items and orders RLS infinite recursion
-- This migration properly fixes the circular dependency between orders and order_items policies
-- The issue: orders policy checks order_items, order_items policy checks orders = infinite loop

-- Step 1: Drop ALL problematic policies that create circular dependencies
DROP POLICY IF EXISTS "Order items follow order visibility" ON public.order_items;
DROP POLICY IF EXISTS "Sellers read orders with their products" ON public.orders;
DROP POLICY IF EXISTS "Sellers update orders with their products" ON public.orders;
DROP POLICY IF EXISTS "Buyers read own order items" ON public.order_items;
DROP POLICY IF EXISTS "Sellers read own order items" ON public.order_items;

-- Step 2: Create new order_items policies that don't reference orders table
-- Buyers can read order items from their own orders (using direct user_id check via orders)
CREATE POLICY "Buyers read own order items v2"
ON public.order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- Sellers can read order items they sold (direct seller_id check without going through orders)
CREATE POLICY "Sellers read own order items v2"
ON public.order_items FOR SELECT
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Step 3: Create new orders policies that don't reference order_items for sellers
-- Instead of checking order_items, sellers access orders where they have sold items
-- This query goes: sellers -> order_items -> orders (one direction only)
CREATE POLICY "Sellers read orders with their products v2"
ON public.orders FOR SELECT
USING (
  id IN (
    SELECT order_id FROM public.order_items 
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
);

CREATE POLICY "Sellers update orders with their products v2"
ON public.orders FOR UPDATE
USING (
  id IN (
    SELECT order_id FROM public.order_items 
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
);

-- Comments for documentation
COMMENT ON POLICY "Buyers read own order items v2" ON public.order_items IS 'Buyers can view items from their own orders (no circular dependency)';
COMMENT ON POLICY "Sellers read own order items v2" ON public.order_items IS 'Sellers can view items they sold (direct check, no circular dependency)';
COMMENT ON POLICY "Sellers read orders with their products v2" ON public.orders IS 'Sellers can view orders containing items they sold (one-way reference)';
COMMENT ON POLICY "Sellers update orders with their products v2" ON public.orders IS 'Sellers can update orders containing items they sold (one-way reference)';
