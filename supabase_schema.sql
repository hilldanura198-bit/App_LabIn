-- LabIN Supabase schema initialization
-- Run this file in the Supabase SQL Editor.

begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nama text not null,
  nim_nip text not null unique,
  program_studi text,
  role text not null default 'mahasiswa',
  ktm_url text,
  avatar_url text,
  whatsapp_number text,
  biometric_enabled boolean not null default false,
  realtime_notifications_enabled boolean not null default true,
  notification_sound_enabled boolean not null default true,
  app_language text not null default 'id',
  location_enabled boolean not null default true,
  device_security_enabled boolean not null default true,
  compliance_score integer not null default 100,
  denda_terakumulasi integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_role_check check (role in ('mahasiswa', 'aslab', 'kalab')),
  constraint profiles_compliance_score_check check (compliance_score between 0 and 100),
  constraint profiles_denda_terakumulasi_check check (denda_terakumulasi >= 0)
);

create table if not exists public.laboratories (
  id uuid primary key default gen_random_uuid(),
  nama_lab text not null,
  lokasi text not null,
  image_url text,
  status_operasional text not null default 'aktif',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint laboratories_status_operasional_check check (status_operasional in ('aktif', 'tutup'))
);

create table if not exists public.inventories (
  id uuid primary key default gen_random_uuid(),
  lab_id uuid not null references public.laboratories(id) on update cascade on delete restrict,
  nama_alat text not null,
  total_stok integer not null default 0,
  stok_tersedia integer not null default 0,
  kondisi text not null default 'bagus',
  manual_url text,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inventories_total_stok_check check (total_stok >= 0),
  constraint inventories_stok_tersedia_check check (stok_tersedia >= 0),
  constraint inventories_stok_tersedia_lte_total_check check (stok_tersedia <= total_stok),
  constraint inventories_kondisi_check check (kondisi in ('bagus', 'rusak'))
);

alter table public.laboratories
  add column if not exists image_url text;

alter table public.inventories
  add column if not exists image_url text;

alter table public.profiles
  add column if not exists app_language text not null default 'id',
  add column if not exists location_enabled boolean not null default true,
  add column if not exists device_security_enabled boolean not null default true;

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on update cascade on delete restrict,
  lab_id uuid not null references public.laboratories(id) on update cascade on delete restrict,
  status text not null default 'pending',
  tanggal_pinjam timestamptz not null,
  tanggal_kembali timestamptz not null,
  desk_no text,
  reservation_no text not null unique default ('PMJ-' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 5))),
  qr_token text not null unique default encode(gen_random_bytes(32), 'hex'),
  signature_url text,
  aslab_note text,
  kalab_note text,
  rejection_reason text,
  rating_review jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookings_status_check check (
    status in (
      'pending',
      'approved_aslab',
      'approved_kalab',
      'active',
      'returned',
      'late',
      'rejected'
    )
  ),
  constraint bookings_tanggal_kembali_check check (tanggal_kembali > tanggal_pinjam)
);

create table if not exists public.booking_items (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on update cascade on delete cascade,
  inventory_id uuid not null references public.inventories(id) on update cascade on delete restrict,
  jumlah integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_items_jumlah_check check (jumlah > 0),
  constraint booking_items_booking_inventory_unique unique (booking_id, inventory_id)
);

create table if not exists public.maintenance_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on update cascade on delete restrict,
  inventory_id uuid not null references public.inventories(id) on update cascade on delete restrict,
  deskripsi text not null,
  foto_url text,
  status_perbaikan text not null default 'diterima',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint maintenance_reports_status_perbaikan_check check (
    status_perbaikan in ('diterima', 'diproses', 'selesai', 'ditolak')
  )
);

create table if not exists public.satisfaction_surveys (
  id uuid primary key default gen_random_uuid(),
  periode text not null,
  kategori text not null,
  skor integer not null,
  created_at timestamptz not null default now(),
  constraint satisfaction_surveys_skor_check check (skor between 0 and 100)
);

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on update cascade on delete cascade,
  rating integer not null,
  message text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_rating_check check (rating between 1 and 5)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on update cascade on delete cascade,
  title text not null,
  message text not null,
  kind text not null default 'general',
  target_type text not null default 'booking',
  target_id text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists inventories_lab_id_idx on public.inventories(lab_id);
create index if not exists bookings_user_id_idx on public.bookings(user_id);
create index if not exists bookings_lab_id_idx on public.bookings(lab_id);
create index if not exists bookings_status_idx on public.bookings(status);
create index if not exists bookings_reservation_no_idx on public.bookings(reservation_no);
create index if not exists bookings_tanggal_pinjam_idx on public.bookings(tanggal_pinjam);
create index if not exists booking_items_booking_id_idx on public.booking_items(booking_id);
create index if not exists booking_items_inventory_id_idx on public.booking_items(inventory_id);
create index if not exists maintenance_reports_user_id_idx on public.maintenance_reports(user_id);
create index if not exists maintenance_reports_inventory_id_idx on public.maintenance_reports(inventory_id);
create index if not exists maintenance_reports_status_perbaikan_idx on public.maintenance_reports(status_perbaikan);
create index if not exists satisfaction_surveys_periode_idx on public.satisfaction_surveys(periode);
create index if not exists feedback_user_id_idx on public.feedback(user_id);
create index if not exists feedback_created_at_idx on public.feedback(created_at);
create index if not exists notifications_user_id_idx on public.notifications(user_id);
create index if not exists notifications_created_at_idx on public.notifications(created_at);
create index if not exists notifications_is_read_idx on public.notifications(is_read);

alter table public.profiles
add column if not exists email text,
add column if not exists whatsapp_number text,
add column if not exists program_studi text,
add column if not exists avatar_url text,
add column if not exists biometric_enabled boolean not null default false,
add column if not exists realtime_notifications_enabled boolean not null default true,
add column if not exists notification_sound_enabled boolean not null default true;

update public.profiles
set role = 'kalab'
where role not in ('mahasiswa', 'aslab', 'kalab');

alter table public.profiles
drop constraint if exists profiles_role_check;

alter table public.profiles
add constraint profiles_role_check check (role in ('mahasiswa', 'aslab', 'kalab'));

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'no_whatsapp'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'whatsapp_number'
  ) then
    alter table public.profiles rename column no_whatsapp to whatsapp_number;
  end if;
end;
$$;

alter table public.bookings
add column if not exists reservation_no text;

alter table public.bookings
add column if not exists desk_no text;

alter table public.bookings
add column if not exists aslab_note text,
add column if not exists kalab_note text,
add column if not exists rejection_reason text;

alter table public.bookings
add column if not exists borrower_name text,
add column if not exists whatsapp_number text,
add column if not exists faculty_code text,
add column if not exists request_date date,
add column if not exists purpose text,
add column if not exists start_time text,
add column if not exists end_time text,
add column if not exists items_snapshot jsonb not null default '[]'::jsonb,
add column if not exists other_items text,
add column if not exists lab_name_snapshot text;

alter table public.bookings
add column if not exists rating_review jsonb;

update public.bookings
set reservation_no = 'PMJ-' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 5))
where reservation_no is null;

alter table public.bookings
alter column reservation_no set not null;

create unique index if not exists bookings_reservation_no_unique_idx on public.bookings(reservation_no);

alter table public.bookings enable row level security;
alter table public.booking_items enable row level security;

drop policy if exists bookings_select_owner_or_staff on public.bookings;
create policy bookings_select_owner_or_staff on public.bookings
for select
using (
  auth.uid() = user_id
  or exists (
    select 1
    from public.profiles staff
    where staff.id = auth.uid()
      and staff.role in ('aslab', 'kalab')
  )
);

drop policy if exists booking_items_select_owner_or_staff on public.booking_items;
create policy booking_items_select_owner_or_staff on public.booking_items
for select
using (
  exists (
    select 1
    from public.bookings booking
    where booking.id = booking_items.booking_id
      and (
        booking.user_id = auth.uid()
        or exists (
          select 1
          from public.profiles staff
          where staff.id = auth.uid()
            and staff.role in ('aslab', 'kalab')
        )
      )
  )
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_laboratories_updated_at on public.laboratories;
create trigger set_laboratories_updated_at
before update on public.laboratories
for each row execute function public.set_updated_at();

drop trigger if exists set_inventories_updated_at on public.inventories;
create trigger set_inventories_updated_at
before update on public.inventories
for each row execute function public.set_updated_at();

drop trigger if exists set_bookings_updated_at on public.bookings;
create trigger set_bookings_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();

drop trigger if exists set_booking_items_updated_at on public.booking_items;
create trigger set_booking_items_updated_at
before update on public.booking_items
for each row execute function public.set_updated_at();

drop trigger if exists set_maintenance_reports_updated_at on public.maintenance_reports;
create trigger set_maintenance_reports_updated_at
before update on public.maintenance_reports
for each row execute function public.set_updated_at();

drop trigger if exists set_feedback_updated_at on public.feedback;
create trigger set_feedback_updated_at
before update on public.feedback
for each row execute function public.set_updated_at();

drop trigger if exists set_notifications_updated_at on public.notifications;
create trigger set_notifications_updated_at
before update on public.notifications
for each row execute function public.set_updated_at();

alter table public.bookings replica identity full;
alter table public.inventories replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication
    where pubname = 'supabase_realtime'
  ) then
    create publication supabase_realtime;
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'bookings'
  ) then
    alter publication supabase_realtime add table public.bookings;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'inventories'
  ) then
    alter publication supabase_realtime add table public.inventories;
  end if;
end;
$$;

commit;
