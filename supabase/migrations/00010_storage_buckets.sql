-- 00010_storage_buckets.sql
-- Storage buckets for progress photos and avatars

-- ============================================================
-- Progress Photos Bucket (private)
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'progress-photos',
  'progress-photos',
  false,
  10485760,  -- 10 MB
  array['image/jpeg', 'image/png', 'image/webp']
);

-- Users can upload to their own folder: progress-photos/<user_id>/*
create policy "Users can upload own progress photos"
  on storage.objects for insert
  with check (
    bucket_id = 'progress-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can view their own progress photos
create policy "Users can view own progress photos"
  on storage.objects for select
  using (
    bucket_id = 'progress-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can delete their own progress photos
create policy "Users can delete own progress photos"
  on storage.objects for delete
  using (
    bucket_id = 'progress-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ============================================================
-- Avatars Bucket (public)
-- ============================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'avatars',
  'avatars',
  true,
  5242880,  -- 5 MB
  array['image/jpeg', 'image/png', 'image/webp']
);

-- Anyone can view avatars (public bucket)
create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

-- Users can upload their own avatar: avatars/<user_id>/*
create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Users can update their own avatar
create policy "Users can update own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
