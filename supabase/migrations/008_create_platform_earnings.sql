-- Migration 008: Create platform_earnings table
-- Creates table for tracking platform commission earnings

-- Create platform_earnings table
CREATE TABLE IF NOT EXISTS public.platform_earnings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL UNIQUE REFERENCES public.orders(id) ON DELETE RESTRICT,
    seller_id UUID NOT NULL REFERENCES public.sellers(id) ON DELETE RESTRICT,
    commission_amount DECIMAL(15, 2) NOT NULL CHECK (commission_amount >= 0),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Function to automatically calculate and record commission when order is delivered
CREATE OR REPLACE FUNCTION record_platform_commission()
RETURNS TRIGGER AS $$
DECLARE
    comm_amount DECIMAL(15, 2);
    seller_id_var UUID;
BEGIN
    -- Only record commission when order status changes to 'delivered'
    IF (NEW.status = 'delivered' AND OLD.status != 'delivered') THEN
        comm_amount := NEW.platform_commission;
        
        -- Get seller_id from first order item (all items in an order belong to same seller)
        SELECT seller_id INTO seller_id_var
        FROM public.order_items
        WHERE order_id = NEW.id
        LIMIT 1;
        
        -- Insert commission record
        INSERT INTO public.platform_earnings (order_id, seller_id, commission_amount)
        VALUES (NEW.id, seller_id_var, comm_amount)
        ON CONFLICT (order_id) DO NOTHING; -- Avoid duplicates if triggered multiple times
        
        -- Update seller wallet balance (credit seller with 90% of total)
        UPDATE public.sellers
        SET wallet_balance = wallet_balance + (NEW.total - comm_amount),
            total_sales = total_sales + NEW.total
        WHERE id = seller_id_var;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic commission recording
CREATE TRIGGER record_platform_commission_trigger
    AFTER UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION record_platform_commission();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_platform_earnings_order_id ON public.platform_earnings(order_id);
CREATE INDEX IF NOT EXISTS idx_platform_earnings_seller_id ON public.platform_earnings(seller_id);
CREATE INDEX IF NOT EXISTS idx_platform_earnings_created_at ON public.platform_earnings(created_at DESC);

-- Comments for documentation
COMMENT ON TABLE public.platform_earnings IS 'Platform commission earnings (10% of each delivered order)';
COMMENT ON COLUMN public.platform_earnings.commission_amount IS 'Platform commission (10% of order total)';
