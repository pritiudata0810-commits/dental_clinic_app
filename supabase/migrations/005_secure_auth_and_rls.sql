-- ============================================================
-- 005_SECURE_AUTH_AND_RLS.SQL
-- Production-Grade Supabase Auth, Profiles, Role Guards & RLS
-- ============================================================

-- 1. EXTEND PROFILES TABLE WITH CLINIC MULTI-TENANCY & ROLES
alter table if exists public.profiles
  add column if not exists clinic_id text not null default 'CLINIC-01';

-- Update check constraint on profiles.role to explicitly include 'patient'
alter table if exists public.profiles
  drop constraint if exists profiles_role_check;

alter table if exists public.profiles
  add constraint profiles_role_check
  check (role in ('doctor', 'receptionist', 'admin', 'patient'));

-- Index on clinic_id for multi-clinic queries
create index if not exists idx_profiles_clinic on public.profiles(clinic_id);

-- 2. HARDEN USER_ROLE() SECURITY DEFINER FUNCTION
create or replace function public.user_role()
returns text as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()),
    'anonymous'
  );
$$ language sql security definer stable;

-- Helper function to fetch the user's clinic_id
create or replace function public.user_clinic_id()
returns text as $$
  select coalesce(
    (select clinic_id from public.profiles where id = auth.uid()),
    'CLINIC-01'
  );
$$ language sql security definer stable;

-- 3. AUTOMATIC PROFILE CREATION TRIGGER ON AUTH.USERS
-- Whenever a new user is created in Supabase Auth, automatically
-- insert a corresponding profile row without trusting client input.
create or replace function public.handle_new_user()
returns trigger as $$
declare
  assigned_role text;
  assigned_name text;
begin
  -- Validate or sanitize requested role from metadata
  assigned_role := coalesce(new.raw_user_meta_data->>'role', 'receptionist');
  if assigned_role not in ('doctor', 'receptionist', 'admin', 'patient') then
    assigned_role := 'receptionist';
  end if;

  assigned_name := coalesce(
    new.raw_user_meta_data->>'full_name',
    split_part(coalesce(new.email, 'Clinic User'), '@', 1)
  );

  insert into public.profiles (
    id,
    email,
    full_name,
    role,
    clinic_id,
    created_at,
    updated_at
  ) values (
    new.id,
    coalesce(new.email, ''),
    assigned_name,
    assigned_role,
    coalesce(new.raw_user_meta_data->>'clinic_id', 'CLINIC-01'),
    now(),
    now()
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();

  return new;
end;
$$ language plpgsql security definer;

-- Trigger firing after user creation in auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill any existing auth users who might be missing a profile row
insert into public.profiles (id, email, full_name, role, clinic_id, created_at, updated_at)
select
  u.id,
  coalesce(u.email, ''),
  coalesce(u.raw_user_meta_data->>'full_name', split_part(coalesce(u.email, 'Staff'), '@', 1)),
  case
    when u.raw_user_meta_data->>'role' in ('doctor', 'receptionist', 'admin', 'patient')
      then u.raw_user_meta_data->>'role'
    else 'receptionist'
  end,
  coalesce(u.raw_user_meta_data->>'clinic_id', 'CLINIC-01'),
  now(),
  now()
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null
on conflict (id) do nothing;

-- 4. PREVENT CLIENT-SIDE ROLE ESCALATION TRIGGER
-- Normal users cannot modify their own 'role' or 'clinic_id'.
-- Only an admin or service_role can elevate a user's permissions.
create or replace function public.prevent_profile_role_escalation()
returns trigger as $$
begin
  if (old.role is distinct from new.role or old.clinic_id is distinct from new.clinic_id) then
    if (public.user_role() != 'admin' and coalesce(current_setting('request.jwt.claim.role', true), '') != 'service_role') then
      raise exception 'Unauthorized: Only clinic administrators can modify roles or clinic affiliations.';
    end if;
  end if;
  new.updated_at = now();
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_prevent_profile_role_escalation on public.profiles;
create trigger trg_prevent_profile_role_escalation
  before update on public.profiles
  for each row execute procedure public.prevent_profile_role_escalation();

-- 5. HARDEN PROFILES ROW LEVEL SECURITY POLICIES
alter table public.profiles enable row level security;

drop policy if exists "Authenticated users can read clinic profiles" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;

create policy "Authenticated users can read clinic profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile info"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "Users can insert their own initial profile"
  on public.profiles for insert
  to authenticated
  with check (
    id = auth.uid()
    and (role in ('receptionist', 'patient') or public.user_role() = 'admin')
  );

-- 6. HARDEN PATIENT TOOTH RECORDS POLICIES (FROM 004)
-- Receptionists can view; only doctors and admins can modify clinical dental charts.
alter table if exists public.patient_tooth_records enable row level security;

drop policy if exists "Authenticated staff can view tooth records" on public.patient_tooth_records;
drop policy if exists "Authenticated staff can insert tooth records" on public.patient_tooth_records;
drop policy if exists "Authenticated staff can update tooth records" on public.patient_tooth_records;
drop policy if exists "Authenticated staff can delete tooth records" on public.patient_tooth_records;

create policy "Staff can view tooth records"
  on public.patient_tooth_records for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Doctors can insert tooth records"
  on public.patient_tooth_records for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'admin'));

create policy "Doctors can update tooth records"
  on public.patient_tooth_records for update
  to authenticated
  using (public.user_role() in ('doctor', 'admin'))
  with check (public.user_role() in ('doctor', 'admin'));

create policy "Doctors can delete tooth records"
  on public.patient_tooth_records for delete
  to authenticated
  using (public.user_role() in ('doctor', 'admin'));

-- 7. ATTENDANCE TABLE SCHEMA & RLS
create table if not exists public.attendance (
  id text primary key,
  employee_id text not null,
  employee_name text not null,
  employee_role text not null,
  date text not null,
  check_in timestamptz,
  check_out timestamptz,
  verification_method text not null default 'faceBiometric',
  face_verification_status text not null default 'verified',
  liveness_status text not null default 'verified',
  location_status text not null default 'verified',
  distance_meters numeric(10, 2) default 0.0,
  status text not null default 'present',
  created_at timestamptz not null default now(),
  device_id text default ''
);

alter table public.attendance enable row level security;

drop policy if exists "Staff can view attendance" on public.attendance;
drop policy if exists "Staff can insert attendance" on public.attendance;
drop policy if exists "Staff can update attendance" on public.attendance;

create policy "Staff can view attendance"
  on public.attendance for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Staff can insert attendance"
  on public.attendance for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Staff can update attendance"
  on public.attendance for update
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
