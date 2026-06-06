-- LabIN Supabase schema initialization
-- Run this file in the Supabase SQL Editor.

begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null,
  nim_nip text not null unique,
  role text not null default 'mahasiswa',
  ktm_url text,
  no_whatsapp text,
  biometric_enabled boolean not null default false,
  realtime_notifications_enabled boolean not null default true,
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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint inventories_total_stok_check check (total_stok >= 0),
  constraint inventories_stok_tersedia_check check (stok_tersedia >= 0),
  constraint inventories_stok_tersedia_lte_total_check check (stok_tersedia <= total_stok),
  constraint inventories_kondisi_check check (kondisi in ('bagus', 'rusak'))
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on update cascade on delete restrict,
  lab_id uuid not null references public.laboratories(id) on update cascade on delete restrict,
  status text not null default 'pending',
  tanggal_pinjam timestamptz not null,
  tanggal_kembali timestamptz not null,
  reservation_no text not null unique default ('PMJ-' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 5))),
  qr_token text not null unique default encode(gen_random_bytes(32), 'hex'),
  signature_url text,
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

alter table public.profiles
add column if not exists no_whatsapp text,
add column if not exists biometric_enabled boolean not null default false,
add column if not exists realtime_notifications_enabled boolean not null default true;

alter table public.bookings
add column if not exists reservation_no text;

update public.bookings
set reservation_no = 'PMJ-' || upper(substr(encode(gen_random_bytes(4), 'hex'), 1, 5))
where reservation_no is null;

alter table public.bookings
alter column reservation_no set not null;

create unique index if not exists bookings_reservation_no_unique_idx on public.bookings(reservation_no);

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
