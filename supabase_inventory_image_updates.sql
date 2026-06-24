insert into storage.buckets (id, name, public)
values ('inventory-images', 'inventory-images', true)
on conflict (id) do update set public = true;

drop policy if exists "inventory_images_public_select" on storage.objects;
create policy "inventory_images_public_select"
on storage.objects
for select
to public
using (bucket_id = 'inventory-images');

-- Upload these files to Supabase Storage bucket:
-- inventory-images/items/webcam-conference.webp
-- inventory-images/items/tablet-survey.webp
-- inventory-images/items/sensor-ultrasonik-hc-sr04.webp
-- inventory-images/items/pc-workstation-rpl.webp
-- inventory-images/items/microphone-meeting.webp
-- inventory-images/items/switch-manageable-24-port.webp
-- inventory-images/items/tensimeter-digital.webp
-- inventory-images/items/scanner-dokumen.webp
--
-- Replace YOUR_PROJECT_ID with your Supabase project ref before running.

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/webcam-conference.webp'
where nama_alat = 'Webcam Conference';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/tablet-survey.webp'
where nama_alat = 'Tablet Survey';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/sensor-ultrasonik-hc-sr04.webp'
where nama_alat = 'Sensor Ultrasonik HC-SR04';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/pc-workstation-rpl.webp'
where nama_alat = 'PC Workstation RPL';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/microphone-meeting.webp'
where nama_alat = 'Microphone Meeting';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/switch-manageable-24-port.webp'
where nama_alat = 'Switch Manageable 24 Port';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/tensimeter-digital.webp'
where nama_alat = 'Tensimeter Digital';

update public.inventories
set image_url = 'https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/inventory-images/items/scanner-dokumen.webp'
where nama_alat = 'Scanner Dokumen';
