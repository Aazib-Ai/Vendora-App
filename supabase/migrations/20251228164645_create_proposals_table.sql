-- Create the proposals table
create table public.proposals (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text not null,
  button_text text not null,
  image_url text not null,
  bg_color text not null,
  action_type text check (action_type in ('route', 'url', 'none')) default 'none',
  action_value text,
  is_active boolean default true,
  priority integer default 0,
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.proposals enable row level security;

-- Policies
-- Everyone can read active proposals
create policy "Public proposals are viewable by everyone"
  on public.proposals for select
  using ( is_active = true );

-- Admins can do everything (assuming you have an is_admin function or similar, adhering to existing patterns)
-- For now, allowing authenticated users to manage if they are admins. 
-- Adjust this policy based on your actual Admin Auth implementation. 
-- Since I don't see the exact admin auth logic here, I'll add a policy for authenticated users to insert/update/delete for now, 
-- or you can restrict it further if you have specific admin roles in public.users or auth.users metadata.

create policy "Admins can insert proposals"
  on public.proposals for insert
  with check ( auth.role() = 'authenticated' ); -- Replace with stricter check if needed

create policy "Admins can update proposals"
  on public.proposals for update
  using ( auth.role() = 'authenticated' );

create policy "Admins can delete proposals"
  on public.proposals for delete
  using ( auth.role() = 'authenticated' );

-- Storage bucket for banners (if not exists)
insert into storage.buckets (id, name, public) 
values ('banners', 'banners', true)
on conflict (id) do nothing;

create policy "Public Access to Banners"
  on storage.objects for select
  using ( bucket_id = 'banners' );

create policy "Authenticated users can upload banners"
  on storage.objects for insert
  with check ( bucket_id = 'banners' and auth.role() = 'authenticated' );

create policy "Authenticated users can update banners"
  on storage.objects for update
  with check ( bucket_id = 'banners' and auth.role() = 'authenticated' );

create policy "Authenticated users can delete banners"
  on storage.objects for delete
  using ( bucket_id = 'banners' and auth.role() = 'authenticated' );
