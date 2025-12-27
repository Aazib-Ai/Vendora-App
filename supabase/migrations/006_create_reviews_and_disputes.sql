--Migration 006: Create reviews and disputes tables
-- Creates tables for product reviews and order disputes

-- Create reviews table
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    seller_reply TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    -- Ensure user can only review a product once per order
    UNIQUE(user_id, product_id, order_id)
);

-- Create disputes table
CREATE TABLE IF NOT EXISTS public.disputes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
    buyer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
    seller_id UUID NOT NULL REFERENCES public.sellers(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'rejected')),
    reason TEXT NOT NULL,
    buyer_description TEXT NOT NULL,
    buyer_evidence JSONB DEFAULT '[]'::jsonb,
    seller_response TEXT,
    seller_evidence JSONB DEFAULT '[]'::jsonb,
    admin_resolution TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Function to update product average rating when review is added/updated/deleted
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
DECLARE
    product_id_var UUID;
    avg_rating DECIMAL(3,2);
    count_reviews INTEGER;
BEGIN
    -- Determine which product_id to update
    IF (TG_OP = 'DELETE') THEN
        product_id_var := OLD.product_id;
    ELSE
        product_id_var := NEW.product_id;
    END IF;
    
    -- Calculate new average and count
    SELECT 
        COALESCE(AVG(rating), 0)::DECIMAL(3,2),
        COUNT(*)::INTEGER
    INTO avg_rating, count_reviews
    FROM public.reviews
    WHERE product_id = product_id_var;
    
    -- Update product
    UPDATE public.products
    SET 
        average_rating = avg_rating,
        review_count = count_reviews
    WHERE id = product_id_var;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic rating updates
CREATE TRIGGER update_product_rating_trigger
    AFTER INSERT OR UPDATE OR DELETE ON public.reviews
    FOR EACH ROW EXECUTE FUNCTION update_product_rating();

-- Create trigger for updated_at
CREATE TRIGGER update_disputes_updated_at BEFORE UPDATE ON public.disputes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON public.reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_disputes_order_id ON public.disputes(order_id);
CREATE INDEX IF NOT EXISTS idx_disputes_buyer_id ON public.disputes(buyer_id);
CREATE INDEX IF NOT EXISTS idx_disputes_seller_id ON public.disputes(seller_id);
CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);

-- Comments for documentation
COMMENT ON TABLE public.reviews IS 'Product reviews from buyers who have purchased the product';
COMMENT ON TABLE public.disputes IS 'Order disputes with evidence from buyer and seller, resolved by admin';
COMMENT ON COLUMN public.reviews.rating IS 'Star rating from 1 to 5';
COMMENT ON COLUMN public.disputes.buyer_evidence IS 'Array of evidence URLs (images, documents) uploaded by buyer';
COMMENT ON COLUMN public.disputes.seller_evidence IS 'Array of evidence URLs (images, documents) uploaded by seller';
