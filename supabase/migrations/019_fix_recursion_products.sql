-- Migration 019: Fix infinite recursion in products table policy

-- Drop the problematic policy that causes infinite recursion
DROP POLICY IF EXISTS "Sellers can update own products" ON public.products;

-- Re-create the policy without the recursive status check
-- The status check is checking the table itself (SELECT status FROM products WHERE id=id) which causes recursion
CREATE POLICY "Sellers can update own products"
ON public.products FOR UPDATE
USING (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
)
WITH CHECK (
  seller_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
);

-- Create a function/trigger mechanism to prevent status changes by non-admins
-- This avoids the RLS recursion issue while maintaining security
CREATE OR REPLACE FUNCTION public.prevent_product_status_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if status is being changed
  IF (OLD.status IS DISTINCT FROM NEW.status) THEN
    -- Allow change only if user is admin
    -- We assume is_admin() function exists from previous migrations
    IF NOT public.is_admin() THEN
       RAISE EXCEPTION 'Sellers are not allowed to change product status';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS check_product_status_update ON public.products;
CREATE TRIGGER check_product_status_update
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION public.prevent_product_status_update();

-- Comment explaining the change
COMMENT ON TRIGGER check_product_status_update ON public.products IS 'Prevents sellers from changing product status without causing RLS recursion';
