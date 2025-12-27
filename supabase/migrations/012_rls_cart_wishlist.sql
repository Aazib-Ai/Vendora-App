-- Migration 012: Row Level Security policies for cart and wishlist tables
-- Implements user-specific cart and wishlist access

-- Enable RLS
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

----------------------------------------------
-- CART_ITEMS TABLE RLS POLICIES
----------------------------------------------

-- Users can read their own cart items
CREATE POLICY "Users read own cart"
ON public.cart_items FOR SELECT
USING (user_id = auth.uid());

-- Users can add items to their own cart
CREATE POLICY "Users add to own cart"
ON public.cart_items FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can update their own cart items (quantity)
CREATE POLICY "Users update own cart"
ON public.cart_items FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete items from their own cart
CREATE POLICY "Users delete from own cart"
ON public.cart_items FOR DELETE
USING (user_id = auth.uid());

----------------------------------------------
-- WISHLIST_ITEMS TABLE RLS POLICIES
----------------------------------------------

-- Users can read their own wishlist
CREATE POLICY "Users read own wishlist"
ON public.wishlist_items FOR SELECT
USING (user_id = auth.uid());

-- Users can add items to their own wishlist
CREATE POLICY "Users add to own wishlist"
ON public.wishlist_items FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can delete items from their own wishlist
CREATE POLICY "Users delete from own wishlist"
ON public.wishlist_items FOR DELETE
USING (user_id = auth.uid());

-- Comments for documentation
COMMENT ON POLICY "Users read own cart" ON public.cart_items IS 'Users can only access their own cart items';
COMMENT ON POLICY "Users read own wishlist" ON public.wishlist_items IS 'Users can only access their own wishlist items';
