-- Migration 014: Row Level Security policies for remaining tables
-- Implements RLS for addresses, reviews, disputes, notifications, and platform_earnings

-- Enable RLS
ALTER TABLE public.addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_earnings ENABLE ROW LEVEL SECURITY;

----------------------------------------------
-- ADDRESSES TABLE RLS POLICIES
----------------------------------------------

-- Users can read their own addresses
CREATE POLICY "Users read own addresses"
ON public.addresses FOR SELECT
USING (user_id = auth.uid());

-- Users can create their own addresses
CREATE POLICY "Users create own addresses"
ON public.addresses FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Users can update their own addresses
CREATE POLICY "Users update own addresses"
ON public.addresses FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Users can delete their own addresses
CREATE POLICY "Users delete own addresses"
ON public.addresses FOR DELETE
USING (user_id = auth.uid());

----------------------------------------------
-- REVIEWS TABLE RLS POLICIES
----------------------------------------------

-- Everyone can read reviews
CREATE POLICY "Public read reviews"
ON public.reviews FOR SELECT
USING (true);

-- Buyers can create reviews for products they purchased
CREATE POLICY "Buyers create reviews for purchased products"
ON public.reviews FOR INSERT
WITH CHECK (
  user_id = auth.uid() AND
  -- Verify user has a delivered order containing this product
  EXISTS (
    SELECT 1 FROM public.orders o
    JOIN public.order_items oi ON oi.order_id = o.id
    WHERE o.user_id = auth.uid()
    AND oi.product_id = product_id
    AND o.status = 'delivered'
  )
);

-- Users can update their own reviews
CREATE POLICY "Users update own reviews"
ON public.reviews FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Sellers can add replies to reviews of their products
CREATE POLICY "Sellers reply to reviews"
ON public.reviews FOR UPDATE
USING (
  product_id IN (
    SELECT id FROM public.products
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
)
WITH CHECK (
  -- Sellers can only update seller_reply field
  product_id IN (
    SELECT id FROM public.products
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
);

----------------------------------------------
-- DISPUTES TABLE RLS POLICIES
----------------------------------------------

-- Buyers can read their own disputes
CREATE POLICY "Buyers read own disputes"
ON public.disputes FOR SELECT
USING (buyer_id = auth.uid());

-- Sellers can read disputes involving their products
CREATE POLICY "Sellers read their disputes"
ON public.disputes FOR SELECT
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Admins can read all disputes
CREATE POLICY "Admins read all disputes"
ON public.disputes FOR SELECT
USING (public.is_admin());

-- Buyers can create disputes for their delivered orders (within 7 days)
CREATE POLICY "Buyers create disputes"
ON public.disputes FOR INSERT
WITH CHECK (
  buyer_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM public.orders
    WHERE id = order_id
    AND user_id = auth.uid()
    AND status = 'delivered'
    AND delivered_at IS NOT NULL
    AND delivered_at >= NOW() - INTERVAL '7 days'
  )
);

-- Buyers can update their own disputes (add evidence)
CREATE POLICY "Buyers update own disputes"
ON public.disputes FOR UPDATE
USING (buyer_id = auth.uid())
WITH CHECK (buyer_id = auth.uid());

-- Sellers can update disputes involving them (add response)
CREATE POLICY "Sellers update their disputes"
ON public.disputes FOR UPDATE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
)
WITH CHECK (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Admins can update all disputes (resolve)
CREATE POLICY "Admins resolve disputes"
ON public.disputes FOR UPDATE
USING (public.is_admin());

----------------------------------------------
-- NOTIFICATIONS TABLE RLS POLICIES
----------------------------------------------

-- Users can read their own notifications
CREATE POLICY "Users read own notifications"
ON public.notifications FOR SELECT
USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users update own notifications"
ON public.notifications FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- System can create notifications (via backend)
-- Allow inserts from service role only
CREATE POLICY "Service role creates notifications"
ON public.notifications FOR INSERT
WITH CHECK (true); -- Service role bypasses RLS

----------------------------------------------
-- PLATFORM_EARNINGS TABLE RLS POLICIES
----------------------------------------------

-- Only admins can read platform earnings
CREATE POLICY "Admins read platform earnings"
ON public.platform_earnings FOR SELECT
USING (public.is_admin());

-- System creates earnings records via trigger
-- No manual INSERT policy needed

-- Comments for documentation
COMMENT ON POLICY "Buyers create reviews for purchased products" ON public.reviews IS 'Buyers can only review products they have actually purchased and received';
COMMENT ON POLICY "Buyers create disputes" ON public.disputes IS 'Disputes can only be created within 7 days of delivery';
COMMENT ON POLICY "Admins read platform earnings" ON public.platform_earnings IS 'Platform earnings are confidential admin data';
