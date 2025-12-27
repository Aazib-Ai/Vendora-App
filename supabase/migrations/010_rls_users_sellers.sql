-- Migration 010: Row Level Security policies for users and sellers tables
-- Implements role-based access control (buyer, seller, admin)

-- Enable RLS on users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Enable RLS on sellers table
ALTER TABLE public.sellers ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user's role
CREATE OR REPLACE FUNCTION public.user_role()
RETURNS TEXT AS $$
  SELECT COALESCE((
    SELECT role
    FROM public.users
    WHERE id = auth.uid()
  ), 'anonymous')::TEXT;
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

----------------------------------------------
-- USERS TABLE RLS POLICIES
----------------------------------------------

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
ON public.users FOR SELECT
USING (auth.uid() = id);

-- Admins can read all users
CREATE POLICY "Admins can read all users"
ON public.users FOR SELECT
USING (public.is_admin());

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
ON public.users FOR UPDATE
USING (auth.uid() = id);

-- New users can insert their own profile (during signup)
CREATE POLICY "Users can insert own profile"
ON public.users FOR INSERT
WITH CHECK (auth.uid() = id);

----------------------------------------------
-- SELLERS TABLE RLS POLICIES
----------------------------------------------

-- Sellers can read their own seller profile
CREATE POLICY "Sellers can read own profile"
ON public.sellers FOR SELECT
USING (user_id = auth.uid());

-- Admins can read all seller profiles
CREATE POLICY "Admins can read all sellers"
ON public.sellers FOR SELECT
USING (public.is_admin());

-- Sellers can update their own profile (except status)
CREATE POLICY "Sellers can update own profile"
ON public.sellers FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (
  user_id = auth.uid() AND
  -- Sellers cannot change their own status
  status = (SELECT status FROM public.sellers WHERE user_id = auth.uid())
);

-- Admins can update any seller profile (including status)
CREATE POLICY "Admins can update sellers"
ON public.sellers FOR UPDATE
USING (public.is_admin());

-- New sellers can insert their profile (during signup)
CREATE POLICY "Sellers can insert own profile"
ON public.sellers FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Admins can insert seller profiles
CREATE POLICY "Admins can insert sellers"
ON public.sellers FOR INSERT
WITH CHECK (public.is_admin());

-- Comments  for documentation
COMMENT ON POLICY "Users can read own profile" ON public.users IS 'Users can view their own profile data';
COMMENT ON POLICY "Admins can read all users" ON public.users IS 'Admins have full visibility of all user profiles';
COMMENT ON POLICY "Sellers can update own profile" ON public.sellers IS 'Sellers can update their profile but cannot change their own status (unverified/active/rejected) - only admins can change status';
