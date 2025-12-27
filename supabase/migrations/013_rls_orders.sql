-- Migration 013: Row Level Security policies for orders and related tables
-- Implements buyer, seller, and admin access to orders

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

----------------------------------------------
-- ORDERS TABLE RLS POLICIES
----------------------------------------------

-- Buyers can read their own orders
CREATE POLICY "Buyers read own orders"
ON public.orders FOR SELECT
USING (user_id = auth.uid());

-- Sellers can read orders containing their products
CREATE POLICY "Sellers read orders with their products"
ON public.orders FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.order_items
    WHERE order_items.order_id = orders.id
    AND order_items.seller_id IN (
      SELECT id FROM public.sellers WHERE user_id = auth.uid()
    )
  )
);

-- Admins can read all orders
CREATE POLICY "Admins read all orders"
ON public.orders FOR SELECT
USING (public.is_admin());

-- Buyers can create orders
CREATE POLICY "Buyers create orders"
ON public.orders FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Buyers can update their own orders (e.g., cancel)
CREATE POLICY "Buyers update own orders"
ON public.orders FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Sellers can update orders containing their products (e.g., add tracking)
CREATE POLICY "Sellers update orders with their products"
ON public.orders FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.order_items
    WHERE order_items.order_id = orders.id
    AND order_items.seller_id IN (
      SELECT id FROM public.sellers WHERE user_id = auth.uid()
    )
  )
);

-- Admins can update any order
CREATE POLICY "Admins update orders"
ON public.orders FOR UPDATE
USING (public.is_admin());

----------------------------------------------
-- ORDER_ITEMS TABLE RLS POLICIES
----------------------------------------------

-- Follow parent order visibility for SELECT
CREATE POLICY "Order items follow order visibility"
ON public.order_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_items.order_id
  )
);

-- Buyers can insert order items for their orders
CREATE POLICY "Buyers create order items"
ON public.order_items FOR INSERT
WITH CHECK (
  order_id IN (SELECT id FROM public.orders WHERE user_id = auth.uid())
);

-- Admins can manage all order items
CREATE POLICY "Admins manage order items"
ON public.order_items FOR ALL
USING (public.is_admin());

----------------------------------------------
-- ORDER_STATUS_HISTORY TABLE RLS POLICIES
----------------------------------------------

-- Follow parent order visibility (read-only for non-admins)
CREATE POLICY "Status history follows order visibility"
ON public.order_status_history FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE orders.id = order_status_history.order_id
  )
);

-- Only system can insert status history (via trigger)
-- No manual INSERT policy needed

-- Comments for documentation
COMMENT ON POLICY "Buyers read own orders" ON public.orders IS 'Buyers can view their purchase history';
COMMENT ON POLICY "Sellers read orders with their products" ON public.orders IS 'Sellers can view orders containing items they sold';
COMMENT ON POLICY "Status history follows order visibility" ON public.order_status_history IS 'Status history is automatically logged by triggers, read-only for users';
