-- Migration 005: Create addresses table
-- Creates table for storing user shipping addresses with GPS coordinates

-- Create addresses table
CREATE TABLE IF NOT EXISTS public.addresses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    address_text TEXT NOT NULL,
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Function to ensure only one default address per user
CREATE OR REPLACE FUNCTION ensure_single_default_address()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_default = true THEN
        -- Set all other addresses for this user to non-default
        UPDATE public.addresses
        SET is_default = false
        WHERE user_id = NEW.user_id AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default address enforcement
CREATE TRIGGER ensure_single_default_address_trigger
    BEFORE INSERT OR UPDATE ON public.addresses
    FOR EACH ROW EXECUTE FUNCTION ensure_single_default_address();

-- Create trigger for updated_at
CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON public.addresses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON public.addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_addresses_is_default ON public.addresses(user_id, is_default);

-- Add foreign key constraint to orders table (deferred from migration 004)
ALTER TABLE public.orders
ADD CONSTRAINT fk_orders_address_id
FOREIGN KEY (address_id) REFERENCES public.addresses(id) ON DELETE RESTRICT;

-- Comments for documentation
COMMENT ON TABLE public.addresses IS 'User shipping addresses with GPS coordinates for delivery tracking';
COMMENT ON COLUMN public.addresses.latitude IS 'GPS latitude coordinate (decimal degrees)';
COMMENT ON COLUMN public.addresses.longitude IS 'GPS longitude coordinate (decimal degrees)';
COMMENT ON COLUMN public.addresses.is_default IS 'Default address for checkout - only one per user allowed';
