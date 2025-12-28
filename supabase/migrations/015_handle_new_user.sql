-- Migration 015: Handle new user creation via trigger to avoid RLS issues
-- Automatically creates public.users and public.sellers entries when a new user signs up

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into public.users
  INSERT INTO public.users (id, email, name, phone, role, is_active)
  VALUES (
    new.id,
    new.email,
    new.raw_user_meta_data->>'name',
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'role',
    true -- Default to active
  );

  -- If the user is a seller, insert into public.sellers
  IF (new.raw_user_meta_data->>'role' = 'seller') THEN
    INSERT INTO public.sellers (user_id, business_name, business_category, status, total_sales, wallet_balance)
    VALUES (
      new.id,
      new.raw_user_meta_data->>'name', -- Use name as initial business name
      'Uncategorized', -- Default category since it's not collected at signup
      'unverified', -- Default status
      0,
      0
    );
  END IF;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function on user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
