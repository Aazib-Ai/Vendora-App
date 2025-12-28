-- Migration: Add 'suspended' status to sellers table
-- Allows admins to suspend active sellers without permanently rejecting them

-- Drop the existing constraint
ALTER TABLE public.sellers 
DROP CONSTRAINT IF EXISTS sellers_status_check;

-- Add the new constraint with 'suspended' status
ALTER TABLE public.sellers 
ADD CONSTRAINT sellers_status_check 
CHECK (status IN ('unverified', 'active', 'rejected', 'suspended'));

-- Update comment for documentation
COMMENT ON COLUMN public.sellers.status IS 'Seller verification and access status: unverified (pending approval), active (approved and can sell), rejected (application denied), suspended (temporarily disabled by admin)';
