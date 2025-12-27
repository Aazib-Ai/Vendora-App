-- Migration 011: Row Level Security policies for products, categories, and related tables
-- Implements role-based product visibility and management

-- Enable RLS on all product-related tables
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

----------------------------------------------
-- CATEGORIES TABLE RLS POLICIES
----------------------------------------------

-- Everyone can read categories
CREATE POLICY "Public read categories"
ON public.categories FOR SELECT
USING (true);

-- Sellers can create categories
CREATE POLICY "Sellers can create categories"
ON public.categories FOR INSERT
WITH CHECK (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Sellers can update their own categories
CREATE POLICY "Sellers can update own categories"
ON public.categories FOR UPDATE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Sellers can delete their own categories
CREATE POLICY "Sellers can delete own categories"
ON public.categories FOR DELETE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

----------------------------------------------
-- PRODUCTS TABLE RLS POLICIES
----------------------------------------------

-- Buyers see only approved and active products
CREATE POLICY "Buyers read approved products"
ON public.products FOR SELECT
USING (
  public.user_role() IN ('buyer', 'anonymous') AND
  status = 'approved' AND
  is_active = true
);

-- Sellers can read their own products (all statuses)
CREATE POLICY "Sellers read own products"
ON public.products FOR SELECT
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Admins can read all products
CREATE POLICY "Admins read all products"
ON public.products FOR SELECT
USING (public.is_admin());

-- Sellers can create products
CREATE POLICY "Sellers can create products"
ON public.products FOR INSERT
WITH CHECK (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid() AND status = 'active')
);

-- Sellers can update their own products (except status)
CREATE POLICY "Sellers can update own products"
ON public.products FOR UPDATE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
)
WITH CHECK (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid()) AND
  -- Sellers cannot change product status
  status = (SELECT status FROM public.products WHERE id = id)
);

-- Admins can update any product (including status)
CREATE POLICY "Admins can update products"
ON public.products FOR UPDATE
USING (public.is_admin());

-- Sellers can delete their own products
CREATE POLICY "Sellers can delete own products"
ON public.products FOR DELETE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

----------------------------------------------
-- PRODUCT_VARIANTS TABLE RLS POLICIES
----------------------------------------------

-- Follow parent product visibility
CREATE POLICY "Product variants follow product visibility"
ON public.product_variants FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.products
    WHERE products.id = product_variants.product_id
  )
);

-- Sellers can manage variants of their own products
CREATE POLICY "Sellers manage own product variants"
ON public.product_variants FOR ALL
USING (
  product_id IN (
    SELECT id FROM public.products
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
);

----------------------------------------------
-- PRODUCT_IMAGES TABLE RLS POLICIES
----------------------------------------------

-- Follow parent product visibility
CREATE POLICY "Product images follow product visibility"
ON public.product_images FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.products
    WHERE products.id = product_images.product_id
  )
);

-- Sellers can manage images of their own products
CREATE POLICY "Sellers manage own product images"
ON public.product_images FOR ALL
USING (
  product_id IN (
    SELECT id FROM public.products
    WHERE seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
);

-- Comments for documentation
COMMENT ON POLICY "Buyers read approved products" ON public.products IS 'Buyers and anonymous users can only see approved, active products';
COMMENT ON POLICY "Sellers can create products" ON public.products IS 'Only active (verified) sellers can create new products';
