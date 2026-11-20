-- OUTPOST 0.8 · Supabase schema
-- Run this entire file in Supabase Dashboard → SQL Editor.
-- Private-by-default: users can only read/write their own profile, albums and photos.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Outpost Explorer' check (char_length(display_name) between 1 and 24),
  locale text not null default 'en' check (locale in ('ru','en','zh','fr','de','pt')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.albums (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 40),
  created_at timestamptz not null default now()
);
create index if not exists albums_owner_created_idx on public.albums(owner_id, created_at desc);

create table if not exists public.photos (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  album_id uuid references public.albums(id) on delete set null,
  title text not null default 'OUTPOST photo' check (char_length(title) between 1 and 80),
  storage_path text not null unique,
  content_type text not null default 'image/jpeg' check (content_type in ('image/jpeg','image/png','image/webp')),
  byte_size bigint not null default 0 check (byte_size between 0 and 10485760),
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  constraint photos_storage_path_owner check (split_part(storage_path, '/', 1) = owner_id::text)
);
create index if not exists photos_owner_created_idx on public.photos(owner_id, created_at desc);
create index if not exists photos_owner_album_idx on public.photos(owner_id, album_id);

alter table public.profiles enable row level security;
alter table public.albums enable row level security;
alter table public.photos enable row level security;

drop policy if exists "profile select own" on public.profiles;
create policy "profile select own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profile insert own" on public.profiles;
create policy "profile insert own" on public.profiles for insert to authenticated with check (id = auth.uid());
drop policy if exists "profile update own" on public.profiles;
create policy "profile update own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "albums own all" on public.albums;
create policy "albums own all" on public.albums for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

drop policy if exists "photos own select" on public.photos;
create policy "photos own select" on public.photos for select to authenticated using (owner_id = auth.uid());
drop policy if exists "photos own insert" on public.photos;
create policy "photos own insert" on public.photos for insert to authenticated with check (
  owner_id = auth.uid() and (album_id is null or exists(select 1 from public.albums a where a.id = album_id and a.owner_id = auth.uid()))
);
drop policy if exists "photos own update" on public.photos;
create policy "photos own update" on public.photos for update to authenticated using (owner_id = auth.uid()) with check (
  owner_id = auth.uid() and (album_id is null or exists(select 1 from public.albums a where a.id = album_id and a.owner_id = auth.uid()))
);
drop policy if exists "photos own delete" on public.photos;
create policy "photos own delete" on public.photos for delete to authenticated using (owner_id = auth.uid());

-- Create a private bucket. Files are stored as {auth.uid()}/{uuid}.jpg
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('outpost-photos', 'outpost-photos', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = 10485760, allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "outpost storage read own" on storage.objects;
create policy "outpost storage read own" on storage.objects for select to authenticated using (
  bucket_id = 'outpost-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "outpost storage upload own" on storage.objects;
create policy "outpost storage upload own" on storage.objects for insert to authenticated with check (
  bucket_id = 'outpost-photos' and (storage.foldername(name))[1] = auth.uid()::text
);
drop policy if exists "outpost storage update own" on storage.objects;
create policy "outpost storage update own" on storage.objects for update to authenticated using (
  bucket_id = 'outpost-photos' and (storage.foldername(name))[1] = auth.uid()::text
) with check (bucket_id = 'outpost-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "outpost storage delete own" on storage.objects;
create policy "outpost storage delete own" on storage.objects for delete to authenticated using (
  bucket_id = 'outpost-photos' and (storage.foldername(name))[1] = auth.uid()::text
);

-- Optional profile bootstrap trigger for new Auth users.
create or replace function public.outpost_create_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(nullif(left(new.raw_user_meta_data->>'display_name', 24), ''), 'Outpost Explorer'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists outpost_auth_user_created on auth.users;
create trigger outpost_auth_user_created
after insert on auth.users
for each row execute procedure public.outpost_create_profile();
