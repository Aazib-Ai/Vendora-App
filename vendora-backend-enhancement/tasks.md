# Implementation Plan

This implementation plan is organized into clear sections: Backend Setup, Frontend Core, and role-specific features (Buyer, Seller, Admin). Tasks are ordered to build incrementally with checkpoints for validation.

---

## Phase 1: Backend Infrastructure

- [x] 1. Supabase Project Setup
  - [x] 1.1 Create Supabase project and configure environment variables
    - Created `.env.example` file with SUPABASE_URL and SUPABASE_ANON_KEY template
    - Added `supabase_flutter` package to pubspec.yaml
    - Created `lib/core/config/supabase_config.dart` for configuration with retry logic
    - _Requirements: 1.1_
  - [x] 1.2 Create database schema with all tables
    - Executed SQL migrations for users, sellers, products, orders, cart_items, addresses, reviews, wishlist, notifications, disputes, platform_earnings tables
    - Set up foreign key relationships and indexes
    - _Requirements: 1.3_
  - [x] 1.3 Configure Row Level Security (RLS) policies
    - Created RLS policies for each table based on user role
    - Tested policies with different user contexts (see RLS_POLICIES.md)
    - _Requirements: 1.4_
  - [x] 1.4 Written property test for Supabase connection retry
    - **Property: Connection retry with exponential backoff**
    - **Validates: Requirements 1.2**

- [/] 2. Cloudflare R2 Integration
  - [ ] 2.1 Set up Cloudflare R2 bucket and credentials
    - Create R2 bucket for product images and profile pictures
    - Configure CORS settings for Flutter app
    - Store R2 credentials in Supabase Edge Function secrets
    - _Requirements: 3.1_
  - [x] 2.2 Create Supabase Edge Function for presigned URLs
    - Implement `generate-upload-url` Edge Function
    - Return presigned upload URL and public URL
    - _Requirements: 3.1, 3.2_
    - Note: Created in `supabase/functions/generate-upload-url/index.ts`
  - [x] 2.3 Implement ImageUploadService in Flutter
    - Create `lib/services/image_upload_service.dart`
    - Implement file validation (type, size)
    - Handle upload with progress tracking
    - _Requirements: 3.1, 3.2, 3.3, 3.6_
    - Note: Includes R2ImageUploadService and MockImageUploadService
  - [x] 2.4 Write property test for image validation
    - **Property 16: Image Upload Validation**
    - **Validates: Requirements 3.6**
    - Note: All 10 tests passed ✅

- [ ] 3. Checkpoint - Backend Infrastructure
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 2: Core Data Models & Serialization

- [x] 4. Data Models Implementation
  - [x] 4.1 Create base model classes with JSON serialization
    - Implement `UserEntity`, `Product`, `Order`, `Address` models
    - Add `toJson()` and `fromJson()` methods
    - Use ISO 8601 for all date fields
    - _Requirements: 11.1, 11.2, 11.4_
  - [x] 4.2 Write property test for model serialization round-trip
    - **Property 1: Model Serialization Round-Trip**
    - **Validates: Requirements 11.1, 11.2, 11.3**
  - [x] 4.3 Create ProductVariant and ProductImage models
    - Implement variant-specific SKU, price, stock
    - _Requirements: 23.1, 23.2_
  - [x] 4.4 Create Order-related models (OrderItem, OrderStatusHistory)
    - Implement order state machine logic
    - _Requirements: 7.1, 7.3, 7.4, 7.5, 7.6_
  - [x] 4.5 Write property test for order state machine
    - **Property 2: Order State Machine Transitions**
    - **Validates: Requirements 7.3, 7.4, 7.5, 7.6**
  - [x] 4.6 Create remaining models (Review, Wishlist, Notification, Dispute)
    - _Requirements: 19.5, 19.2, 14.1, 21.1_

- [x] 5. Repository Layer Implementation
  - [x] 5.1 Create AuthRepository with Supabase Auth
    - Implement signUp, signIn, signOut, resetPassword
    - Handle session persistence
    - _Requirements: 2.1, 2.3, 2.5, 2.6, 2.7_
  - [x] 5.2 Create ProductRepository
    - Implement CRUD operations with Supabase
    - Add pagination, search, and filtering
    - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_
  - [x] 5.3 Create OrderRepository
    - Implement order creation and status updates
    - Handle stock decrement on order placement
    - _Requirements: 7.1, 7.2, 16.4_
  - [x] 5.4 Write property test for stock decrement
    - **Property 3: Stock Decrement on Order Placement**
    - **Validates: Requirements 16.4, 23.6**
    - Note: All 8 tests passed ✅
  - [x] 5.5 Create CartRepository
    - Implement add, update, remove cart items
    - Calculate totals
    - _Requirements: 6.1, 6.2, 6.3, 6.4_
  - [x] 5.6 Write property test for cart total calculation
    - **Property 7: Cart Total Calculation**
    - **Validates: Requirements 6.2**
    - Note: All 10 tests passed ✅

- [ ] 6. Checkpoint - Data Layer
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 3: Authentication System

- [x] 7. Authentication Implementation
  - [x] 7.1 Create AuthProvider for state management
    - Manage auth state with Provider
    - Handle auto-login on app launch
    - _Requirements: 2.7_
  - [x] 7.2 Update Login Screen with Supabase Auth
    - Connect to AuthRepository
    - Add loading states and error handling
    - Navigate based on user role
    - _Requirements: 2.3, 2.4_
  - [x] 7.3 Update Signup Screen with role selection
    - Create buyer/seller accounts
    - Set seller status to 'unverified'
    - _Requirements: 2.1, 2.2, 2.8_
  - [x] 7.4 Write property test for seller pending status
    - **Property 15: New Seller Pending Status**
    - **Validates: Requirements 2.8, 18.1, 18.2**
    - Note: All 8 tests passed ✅
  - [x] 7.5 Update Forgot/Reset Password screens
    - Integrate with Supabase password reset
    - _Requirements: 2.5_
  - [x] 7.6 Implement logout functionality
    - Clear session and navigate to login
    - _Requirements: 2.6_

- [x] 8. Checkpoint - Authentication
  - All tests passed, authentication system complete

---

## Phase 4: Frontend Core Components

- [x] 9. Design System Implementation
  - [x] 9.1 Create AppColors and AppTypography classes
    - Implement color palette from design spec
    - Create typography scale
    - _Requirements: 10.1_
  - [x] 9.2 Create reusable UI components
    - SkeletonLoader for loading states
    - ErrorStateWidget with retry
    - AnimatedButton with haptic feedback
    - _Requirements: 10.1, 10.2, 10.7_
  - [x] 9.3 Create ProductCard component
    - Implement with badges, wishlist, quick-add
    - _Requirements: 10.4_
  - [x] 9.4 Create StatsCard component for dashboards
    - Show value, trend, icon
    - _Requirements: 15.1_
  - [x] 9.5 Implement page transitions and animations
    - SlidePageRoute for navigation
    - Add-to-cart flying animation
    - _Requirements: 10.3_

- [x] 10. Real-time Subscriptions
  - [x] 10.1 Create RealtimeManager service
    - Subscribe to order updates
    - Subscribe to product updates
    - Handle reconnection
    - _Requirements: 9.1, 9.2, 9.3_
  - [x] 10.2 Implement offline detection and caching
    - Use connectivity_plus for network status
    - Cache products locally with Hive
    - _Requirements: 9.4, 12.1, 12.2, 12.3_

- [ ] 11. Checkpoint - Frontend Core
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 5: Buyer Features

- [x] 12. Buyer Home Screen
  - [x] 12.1 Redesign Home Screen with new layout
    - Add hero banner carousel
    - Add category quick access
    - Add flash deals section with countdown
    - _Requirements: 5.1, 10.1_
  - [x] 12.2 Implement product fetching with pagination
    - Connect to ProductRepository
    - Add pull-to-refresh
    - Add infinite scroll
    - _Requirements: 5.1, 10.5_
  - [x] 12.3 Implement search functionality
    - Full-text search with Supabase
    - Debounced input
    - _Requirements: 5.2_
  - [x] 12.4 Implement category filtering
    - Filter products by category
    - _Requirements: 5.3_
  - [x] 12.5 Write property test for category filter
    - **Property 5: Category Filter Correctness**
    - **Validates: Requirements 5.3**
  - [x] 12.6 Implement sorting options
    - Sort by price, rating, newest
    - _Requirements: 5.4_
  - [x] 12.7 Write property test for sort order
    - **Property 6: Product Sort Order Correctness**
    - **Validates: Requirements 5.4**

- [ ] 13. Product Details Screen
  - [x] 13.1 Redesign Product Details with new layout
    - Image gallery with pinch-to-zoom
    - Variant selectors (size, color)
    - Trust badges
    - _Requirements: 5.5, 10.4, 23.3, 23.4_
  - [x] 13.2 Implement variant selection logic
    - Update price and stock on variant change
    - Disable out-of-stock variants
    - _Requirements: 23.4, 23.7_
  - [x] 13.3 Write property test for variant stock independence
    - **Property 18: Variant Stock Independence**
    - **Validates: Requirements 23.2, 23.6, 23.7**
  - [x] 13.4 Add WhatsApp contact button
    - Open WhatsApp with seller number
    - _Requirements: 20.3, 20.8_
  - [x] 13.5 Implement low stock and out of stock indicators
    - Show badges based on quantity
    - _Requirements: 16.1, 16.3_
  - [x] 13.6 Write property test for stock indicators
    - **Property 12: Low Stock Badge Display**
    - **Property 13: Out of Stock State**
    - **Validates: Requirements 16.1, 16.3**

- [x] 14. Shopping Cart
  - [x] 14.1 Redesign Cart Screen with new layout
    - Item cards with quantity controls
    - Order summary
    - Coupon code input
    - _Requirements: 6.4_
  - [x] 14.2 Connect cart to Supabase
    - Sync cart across devices
    - _Requirements: 6.1, 6.5_
  - [x] 14.3 Implement quantity update and remove
    - Update totals on change
    - _Requirements: 6.2, 6.3_

- [x] 15. Checkout & Orders
  - [x] 15.1 Redesign Checkout Screen
    - Address selection with map preview
    - Payment method selection
    - Order summary
    - _Requirements: 7.1, 22.8_
  - [x] 15.2 Implement Address Book
    - List, add, edit, delete addresses
    - Set default address
    - _Requirements: 22.1, 22.3, 22.4, 22.5, 22.6, 22.7_
  - [x] 15.3 Implement OpenStreetMap location picker
    - Drag pin to select location
    - Store lat/lng coordinates
    - _Requirements: 22.1, 22.2, 22.3_
  - [x] 15.4 Implement order placement
    - Create order in Supabase
    - Clear cart after order
    - Decrement stock
    - _Requirements: 7.1, 7.2, 16.4_
  - [x] 15.5 Create Order Tracking Screen
    - Visual timeline with status history
    - Tracking number display
    - _Requirements: 7.7, 7.10_

- [x] 16. Buyer Additional Features
  - [x] 16.1 Implement Wishlist functionality
    - Add/remove from wishlist
    - Wishlist screen
    - _Requirements: 19.2, 19.3_
  - [x] 16.2 Implement Reviews system
    - Submit review after purchase
    - View product reviews
    - _Requirements: 19.5, 19.6, 19.7_
  - [x] 16.3 Write property test for review purchase verification
    - **Property 10: Review Purchase Verification**
    - **Validates: Requirements 19.5, 19.6**
  - [x] 16.4 Implement Notifications screen
    - Fetch and display notifications
    - Mark as read
    - Navigate on tap
    - _Requirements: 14.2, 14.3, 14.4_

- [ ] 17. Checkpoint - Buyer Features
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 6: Seller Features

- [ ] 18. Seller Dashboard
  - [/] 18.1 Redesign Seller Dashboard with new layout
    - Today's overview stats
    - Action required alerts
    - Sales chart (7 days)
    - Top selling products
    - Recent orders
    - _Requirements: 15.1, 15.4_
  - [/] 18.2 Implement sales data fetching
    - Aggregate sales by day
    - Calculate trends
    - _Requirements: 15.1, 15.2_
  - [ ] 18.3 Implement pending approval state
    - Show "Pending Approval" for unverified sellers
    - Disable product creation
    - _Requirements: 18.2_

- [ ] 19. Seller Product Management
  - [ ] 19.1 Redesign Add/Edit Product screen
    - Multi-image upload with reorder
    - Variant management
    - Specifications key-value pairs
    - Discount settings
    - _Requirements: 4.1, 4.6, 23.1, 23.2, 20.5_
  - [ ] 19.2 Implement product image upload to R2
    - Upload multiple images
    - Set primary image
    - _Requirements: 3.1, 3.2_
  - [ ] 19.3 Implement product CRUD operations
    - Create with pending status
    - Edit existing products
    - Delete with image cleanup
    - _Requirements: 4.1, 4.2, 4.3, 3.5_
  - [ ] 19.4 Implement seller product list
    - Show only seller's products
    - Filter by status
    - _Requirements: 4.4_
  - [ ] 19.5 Write property test for seller product isolation
    - **Property 8: Seller Product Isolation**
    - **Validates: Requirements 4.4**
  - [ ] 19.6 Write property test for approved products only
    - **Property 9: Approved Products Only for Buyers**
    - **Validates: Requirements 5.1**

- [ ] 20. Seller Order Management
  - [ ] 20.1 Redesign Seller Orders screen
    - Status tabs (Pending, Processing, Shipped, Delivered)
    - Order cards with actions
    - _Requirements: 7.8_
  - [ ] 20.2 Implement order acceptance
    - Transition from Pending to Processing
    - Send notification to buyer
    - _Requirements: 7.3, 7.9_
  - [ ] 20.3 Implement shipping with tracking
    - Add tracking number
    - Transition to Shipped
    - _Requirements: 7.4_
  - [ ] 20.4 Implement order cancellation
    - Cancel only if Pending or Processing
    - _Requirements: 7.6_

- [ ] 21. Seller Analytics
  - [ ] 21.1 Create Analytics Screen with charts
    - Revenue summary with commission breakdown
    - Sales trend line chart
    - Category performance pie chart
    - Order metrics
    - _Requirements: 15.1, 15.2, 15.3, 15.4_
  - [ ] 21.2 Implement commission calculation display
    - Show gross, commission, net
    - _Requirements: 17.3_
  - [ ] 21.3 Write property test for commission calculation
    - **Property 4: Commission Calculation Accuracy**
    - **Validates: Requirements 17.1, 17.2**

- [ ] 22. Seller Inventory Management
  - [ ] 22.1 Implement inventory view
    - Sort by stock level
    - Low stock items first
    - _Requirements: 16.5_
  - [ ] 22.2 Implement stock quantity validation
    - Prevent negative values
    - _Requirements: 16.2_
  - [ ] 22.3 Write property test for quantity validation
    - **Property 14: Quantity Validation Non-Negative**
    - **Validates: Requirements 16.2**

- [ ] 23. Seller Additional Features
  - [ ] 23.1 Implement Store Profile management
    - Edit store name, description
    - Add WhatsApp number
    - _Requirements: 20.1, 20.2, 20.4_
  - [ ] 23.2 Implement review reply functionality
    - Reply to buyer reviews once
    - _Requirements: 20.7_
  - [ ] 23.3 Implement discount management
    - Set discount percentage and validity
    - _Requirements: 20.5, 20.6_

- [ ] 24. Checkpoint - Seller Features
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 7: Admin Features

- [ ] 25. Admin Dashboard
  - [ ] 25.1 Redesign Admin Dashboard with new layout
    - Platform overview stats (GMV, revenue, users, sellers, products)
    - Action required alerts
    - Revenue trend chart
    - Quick action buttons
    - _Requirements: 8.1_
  - [ ] 25.2 Implement real-time statistics
    - Fetch aggregated data from Supabase
    - Calculate platform earnings
    - _Requirements: 8.1, 8.10_

- [ ] 26. Seller KYC Verification
  - [ ] 26.1 Create KYC Verification Queue screen
    - List unverified sellers
    - Show seller details
    - _Requirements: 8.9, 18.3_
  - [ ] 26.2 Implement seller approval
    - Update status to Active
    - Send approval notification
    - _Requirements: 8.2, 18.4_
  - [ ] 26.3 Implement seller rejection
    - Update status to Rejected with reason
    - Send rejection notification
    - _Requirements: 8.3, 18.5_

- [ ] 27. Product Moderation
  - [ ] 27.1 Create Product Moderation screen
    - List pending products
    - Show product details
    - _Requirements: 8.4_
  - [ ] 27.2 Implement product approval
    - Update status to Approved
    - Make visible to buyers
    - _Requirements: 8.4_
  - [ ] 27.3 Implement product hiding/banning
    - Set isActive to false
    - Remove from search results
    - _Requirements: 8.7_

- [ ] 28. User Management
  - [ ] 28.1 Create User Management screen
    - List all users with filters
    - Show user details
    - _Requirements: 8.5_
  - [ ] 28.2 Implement user banning
    - Set isActive to false
    - Revoke session
    - _Requirements: 8.5_
  - [ ] 28.3 Implement seller banning
    - Set seller isActive to false
    - Hide all seller products
    - _Requirements: 8.6_

- [ ] 29. Dispute Resolution
  - [ ] 29.1 Create Dispute Center screen
    - List disputes by status
    - Show dispute details with evidence
    - _Requirements: 8.4, 21.4_
  - [ ] 29.2 Implement dispute resolution
    - Refund buyer or release to seller
    - Update dispute status
    - _Requirements: 21.5, 21.6_
  - [ ] 29.3 Write property test for dispute window
    - **Property 11: Dispute Window Validation**
    - **Validates: Requirements 21.1**

- [ ] 30. Admin Analytics
  - [ ] 30.1 Create Admin Analytics screen
    - GMV trend chart
    - User growth chart
    - Top categories
    - Top sellers
    - _Requirements: 8.8_
  - [ ] 30.2 Implement commission tracking
    - Platform earnings breakdown
    - Commission by seller
    - _Requirements: 17.4_

- [ ] 31. Checkpoint - Admin Features
  - Ensure all tests pass, ask the user if questions arise.

---

## Phase 8: Final Integration & Polish

- [ ] 32. Notifications System
  - [ ] 32.1 Implement notification creation on events
    - Order status changes
    - Product approval
    - Dispute updates
    - _Requirements: 7.9, 14.1_
  - [ ] 32.2 Implement push notifications (optional)
    - Configure Firebase Cloud Messaging
    - Send push on important events
    - _Requirements: 7.9_

- [ ] 33. Commission System
  - [ ] 33.1 Implement commission calculation on delivery
    - Calculate 10% platform commission
    - Credit seller wallet
    - Record platform earnings
    - _Requirements: 17.1, 17.2_

- [ ] 34. Final Testing & Validation
  - [ ] 34.1 Run all property-based tests
    - Ensure 100+ iterations per property
    - Fix any failing tests
  - [ ] 34.2 Run integration tests
    - Test complete user flows
    - Test edge cases
  - [ ] 34.3 Performance optimization
    - Optimize database queries
    - Implement image caching
    - _Requirements: 12.4_

- [ ] 35. Final Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

---

## Summary

| Phase | Focus Area | Tasks |
|-------|------------|-------|
| 1 | Backend Infrastructure | Supabase setup, R2 integration |
| 2 | Data Models | Models, serialization, repositories |
| 3 | Authentication | Login, signup, password reset |
| 4 | Frontend Core | Design system, components, real-time |
| 5 | Buyer Features | Home, product details, cart, checkout |
| 6 | Seller Features | Dashboard, products, orders, analytics |
| 7 | Admin Features | Dashboard, KYC, moderation, disputes |
| 8 | Final Integration | Notifications, commission, testing |
