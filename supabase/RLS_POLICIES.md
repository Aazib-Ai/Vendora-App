# Row Level Security (RLS) Policies Documentation

## Overview

This document describes all Row Level Security policies implemented for the Vendora database. RLS policies enforce data access control at the database level, ensuring users can only access data they're authorized to see based on their role.

## Role Definitions

- **buyer**: End users who browse and purchase products
- **seller** Vendors who list and manage products
- **admin**: Platform administrators with full access
- **anonymous**: Unauth enticated users (limited read access)

## Role Matrix

| Table | Buyer Read | Buyer Write | Seller Read | Seller Write | Admin Read | Admin Write |
|-------|-----------|-------------|-------------|--------------|-----------|-------------|
| users | Own profile | Own profile | Own profile | Own profile | All | All |
| sellers | - | - | Own profile | Own except status | All | All (including status) |
| categories | All | - | All | Own categories | All | All |
| products | Approved only | - | Own products | Own except status | All | All (including status) |
| product_variants | Via parent | - | Own product | Own products | All | All |
| product_images | Via parent | - | Own products | Own products | All | All |
| cart_items | Own cart | Own cart | - | - | - | - |
| wishlist_items | Own wishlist | Own wishlist | - | - | - | - |
| orders | Own orders | Own orders | Orders with seller products | Orders with seller products | All | All |
| order_items | Via order | Own orders | Via order | - | All | All |
| order_status_history | Via order (read-only) | - | Via order (read-only) | - | All | Via trigger only |
| addresses | Own addresses | Own addresses | - | - | - | - |
| reviews | All | Own + purchased | All | Reply to own products | All | All |
| disputes | Own disputes | Own disputes | Seller disputes | Seller disputes | All | All (resolve) |
| notifications | Own | Mark as read | Own | Mark as read | - | System creates |
| platform_earnings | - | - | - | - | All | Via trigger only |

## Key Policies Explained

### Products Table
- **Buyers**: Can only see products with `status='approved'` AND `is_active=true`
- **Sellers**: Can see all their own products regardless of status, but cannot change product status (only admins can approve/reject)
- **Unverified sellers**: Cannot create new products until approved by admin

### Orders Table
- **Buyers**: Full access to their own orders
- **Sellers**: Can view and update (add tracking, change status) orders that contain their products
- **Admin**: Full access to all orders

### Reviews Table
- **Purchase Verification**: Buyers can only review products they have actually purchased (verified via `delivered` order)
- **Seller Replies**: Sellers can add replies to reviews of their own products

### Disputes Table
- **Time Window**: Disputes can only be created within 7 days of order delivery
- **Evidence**: Both buyers and sellers can add evidence (stored as JSONB arrays)
- **Resolution**: Only admins can add final resolution

### Commission & Earnings
- **Platform Earnings**: Only admins can view commission data
- **Automatic Calculation**: Commission is automatically recorded when order status changes to `delivered` (via trigger)

## Helper Functions

### `auth.user_role()`
Returns the role of the currently authenticated user ('buyer', 'seller', 'admin', or 'anonymous')

### `auth.is_admin()`
Returns true if the current user has admin role

## Security Notes

> [!CAUTION]
> - RLS policies are enforced at the database level - they cannot be bypassed by application code
> - The service role key bypasses RLS - protect it carefully and use only for system operations
> - Triggers run with SECURITY DEFINER and can write to tables regardless of RLS

> [!IMPORTANT]
> - Test RLS policies thoroughly with different user roles before deploying to production
> - Use the SQL Editor in Supabase dashboard with `set_config('request.jwt.claims', ...)` to simulate different user sessions

## Migration Files

- `010_rls_users_sellers.sql` - Users and sellers table policies
- `011_rls_products_categories.sql` - Product catalog policies
- `012_rls_cart_wishlist.sql` - Cart and wishlist policies
- `013_rls_orders.sql` - Order management policies
- `014_rls_other_tables.sql` - Addresses, reviews, disputes, notifications, platform earnings
