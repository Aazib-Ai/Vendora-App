-- Migration 021: Create decrement_product_stock function
-- Required for atomic stock updates during order creation

CREATE OR REPLACE FUNCTION public.decrement_product_stock(product_id uuid, quantity int)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.products
  SET stock_quantity = stock_quantity - quantity
  WHERE id = product_id
  AND stock_quantity >= quantity;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Insufficient stock for product %', product_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.decrement_product_stock(uuid, int) TO authenticated;

COMMENT ON FUNCTION public.decrement_product_stock IS 'Atomically decrements product stock. Raises exception if insufficient stock.';
