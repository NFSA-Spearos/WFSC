-- ============================================================
-- WFSC — Storage policies for image uploads
-- ============================================================
-- Making a bucket "Public" in the dashboard only allows public
-- DOWNLOADS. Uploads via the anon key still need explicit policies
-- on storage.objects. This grants public read + anon write on the
-- two buckets the app uses: team-photos and catch-photos.
--
-- ⚠️  DEV-FRIENDLY: anyone with the anon key can upload/delete in
-- these buckets. Tighten before production if needed.
--
-- Run this in the Supabase SQL Editor.
-- ============================================================

-- TEAM PHOTOS ------------------------------------------------
create policy "team-photos public read"
  on storage.objects for select
  using (bucket_id = 'team-photos');

create policy "team-photos anon insert"
  on storage.objects for insert
  with check (bucket_id = 'team-photos');

create policy "team-photos anon update"
  on storage.objects for update
  using (bucket_id = 'team-photos')
  with check (bucket_id = 'team-photos');

create policy "team-photos anon delete"
  on storage.objects for delete
  using (bucket_id = 'team-photos');

-- CATCH PHOTOS -----------------------------------------------
create policy "catch-photos public read"
  on storage.objects for select
  using (bucket_id = 'catch-photos');

create policy "catch-photos anon insert"
  on storage.objects for insert
  with check (bucket_id = 'catch-photos');

create policy "catch-photos anon update"
  on storage.objects for update
  using (bucket_id = 'catch-photos')
  with check (bucket_id = 'catch-photos');

create policy "catch-photos anon delete"
  on storage.objects for delete
  using (bucket_id = 'catch-photos');
