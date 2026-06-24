insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "avatars_public_select" on storage.objects;
create policy "avatars_public_select"
on storage.objects
for select
to public
using (bucket_id = 'avatars');

drop policy if exists "avatars_authenticated_insert_own_folder" on storage.objects;
create policy "avatars_authenticated_insert_own_folder"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_authenticated_update_own_folder" on storage.objects;
create policy "avatars_authenticated_update_own_folder"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatars_authenticated_delete_own_folder" on storage.objects;
create policy "avatars_authenticated_delete_own_folder"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

alter table public.feedback enable row level security;

drop policy if exists "feedback_public_select" on public.feedback;
create policy "feedback_public_select"
on public.feedback
for select
to authenticated
using (true);

drop policy if exists "feedback_insert_own_review" on public.feedback;
create policy "feedback_insert_own_review"
on public.feedback
for insert
to authenticated
with check (user_id = auth.uid());
