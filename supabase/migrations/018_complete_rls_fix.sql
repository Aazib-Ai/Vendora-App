-- Migration 018: Complete RLS fix for order_items infinite recursion
-- This is a comprehensive fix that removes ALL circular dependencies
-- Run this migration to completely fix the infinite recursion error

-- ============================================
-- STEP 1: DROP ALL PROBLEMATIC POLICIES
-- ============================================

-- Drop ALL existing order_items SELECT policies (to start fresh)
DROP POLICY IF EXISTS "Order items follow order visibility" ON public.order_items;
DROP POLICY IF EXISTS "Buyers read own order items" ON public.order_items;
DROP POLICY IF EXISTS "Sellers read own order items" ON public.order_items;
DROP POLICY IF EXISTS "Buyers read own order items v2" ON public.order_items;
DROP POLICY IF EXISTS "Sellers read own order items v2" ON public.order_items;
DROP POLICY IF EXISTS "Admins manage order items" ON public.order_items;
DROP POLICY IF EXISTS "Buyers create order items" ON public.order_items;

-- Drop ALL existing orders SELECT/UPDATE policies that reference order_items
DROP POLICY IF EXISTS "Sellers read orders with their products" ON public.orders;
DROP POLICY IF EXISTS "Sellers update orders with their products" ON public.orders;
DROP POLICY IF EXISTS "Sellers read orders with their products v2" ON public.orders;
DROP POLICY IF EXISTS "Sellers update orders with their products v2" ON public.orders;
DROP POLICY IF EXISTS "Buyers read own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers update own orders" ON public.orders;
DROP POLICY IF EXISTS "Buyers create orders" ON public.orders;
DROP POLICY IF EXISTS "Admins read all orders" ON public.orders;
DROP POLICY IF EXISTS "Admins update orders" ON public.orders;

-- ============================================
-- STEP 2: RECREATE ORDERS POLICIES (NO CIRCULAR REFS)
-- ============================================

-- Buyers can read their own orders (direct check, no circular dependency)
CREATE POLICY "orders_buyer_select"
ON public.orders FOR SELECT
USING (user_id = auth.uid());

-- Buyers can create orders
CREATE POLICY "orders_buyer_insert"
ON public.orders FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Buyers can update their own orders (e.g., cancel)
CREATE POLICY "orders_buyer_update"
ON public.orders FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admins can read all orders
CREATE POLICY "orders_admin_select"
ON public.orders FOR SELECT
USING (public.is_admin());

-- Admins can update any order
CREATE POLICY "orders_admin_update"
ON public.orders FOR UPDATE
USING (public.is_admin());

-- For sellers: We create a materialized view approach using a function
-- This avoids the circular dependency by using a security definer function

-- Create a helper function that sellers can use to get their seller_id
CREATE OR REPLACE FUNCTION public.get_current_seller_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.sellers WHERE user_id = auth.uid() LIMIT 1
$$;

-- Create a helper function to get order IDs for a seller (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_seller_order_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT DISTINCT order_id 
  FROM public.order_items 
  WHERE seller_id = (SELECT id FROM public.sellers WHERE user_id = auth.uid() LIMIT 1)
$$;

-- Sellers can read orders that contain their items (using function, no circular ref)
CREATE POLICY "orders_seller_select"
ON public.orders FOR SELECT
USING (id IN (SELECT public.get_seller_order_ids()));

-- Sellers can update orders that contain their items
CREATE POLICY "orders_seller_update"
ON public.orders FOR UPDATE
USING (id IN (SELECT public.get_seller_order_ids()));

-- ============================================
-- STEP 3: RECREATE ORDER_ITEMS POLICIES (NO CIRCULAR REFS)
-- ============================================

-- Buyers can read order items from their own orders
-- This goes: orders.user_id -> order_items (ONE direction only)
CREATE POLICY "order_items_buyer_select"
ON public.order_items FOR SELECT
USING (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- Sellers can read order items they sold (direct seller_id check)
-- This does NOT reference orders table at all
CREATE POLICY "order_items_seller_select"
ON public.order_items FOR SELECT
USING (
  seller_id = public.get_current_seller_id()
);

-- Buyers can create order items for their orders
CREATE POLICY "order_items_buyer_insert"
ON public.order_items FOR INSERT
WITH CHECK (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- Admins can do anything with order items
CREATE POLICY "order_items_admin_all"
ON public.order_items FOR ALL
USING (public.is_admin());

-- ============================================
-- STEP 4: GRANT EXECUTE ON FUNCTIONS
-- ============================================
GRANT EXECUTE ON FUNCTION public.get_current_seller_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_seller_order_ids() TO authenticated;

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================
COMMENT ON FUNCTION public.get_current_seller_id() IS 'Returns the seller_id for the current authenticated user (SECURITY DEFINER to bypass RLS)';
COMMENT ON FUNCTION public.get_seller_order_ids() IS 'Returns order IDs for orders containing items sold by the current seller (SECURITY DEFINER to bypass RLS)';
COMMENT ON POLICY "orders_seller_select" ON public.orders IS 'Sellers can view orders containing items they sold - uses function to avoid circular dep';
COMMENT ON POLICY "order_items_seller_select" ON public.order_items IS 'Sellers can view items they sold - direct check, no circular dependency';
