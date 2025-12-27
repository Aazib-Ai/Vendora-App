-- Migration 007: Create notifications table
-- Creates table for in-app notifications

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('order', 'product', 'seller', 'system', 'dispute')),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Create index on JSONB data for faster queries
CREATE INDEX IF NOT EXISTS idx_notifications_data ON public.notifications USING gin(data);

-- Comments for documentation
COMMENT ON TABLE public.notifications IS 'In-app notifications for users about orders, products, and system updates';
COMMENT ON COLUMN public.notifications.type IS 'Notification category: order, product, seller, system, or dispute';
COMMENT ON COLUMN public.notifications.data IS 'Additional notification data (order_id, product_id, etc.) as JSON';
