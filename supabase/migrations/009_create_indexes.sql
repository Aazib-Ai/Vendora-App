-- Migration 009: Create additional indexes for performance optimization
-- Creates composite and specialized indexes for common query patterns

-- Enable the pg_trgm extension for fuzzy text search (must come first)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Users table indexes
CREATE INDEX IF NOT EXISTS idx_users_role_active ON public.users(role, is_active);

-- Products table composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_products_seller_status ON public.products(seller_id, status);
CREATE INDEX IF NOT EXISTS idx_products_category_status_active ON public.products(category_id, status, is_active);
CREATE INDEX IF NOT EXISTS idx_products_rating ON public.products(average_rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);

-- Orders table composite indexes
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON public.orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON public.orders(status, created_at DESC);

-- Order items for seller queries
CREATE INDEX IF NOT EXISTS idx_order_items_seller_created ON public.order_items(seller_id, created_at DESC);

-- Cart items for user queries
CREATE INDEX IF NOT EXISTS idx_cart_items_user_created ON public.cart_items(user_id, created_at DESC);

-- Wishlist items for user queries
CREATE INDEX IF NOT EXISTS idx_wishlist_items_user_created ON public.wishlist_items(user_id, created_at DESC);

-- Reviews for product page
CREATE INDEX IF NOT EXISTS idx_reviews_product_created ON public.reviews(product_id, created_at DESC);

-- Full-text search on products (for search functionality)
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON public.products USING gin(name gin_trgm_ops);
CREATE INDEX IF  NOT EXISTS idx_products_description_trgm ON public.products USING gin(description gin_trgm_ops);

-- Comments for documentation
COMMENT ON INDEX idx_products_name_trgm IS 'Trigram index for fuzzy text search on product names';
COMMENT ON INDEX idx_products_description_trgm IS 'Trigram index for fuzzy text search on product descriptions';
