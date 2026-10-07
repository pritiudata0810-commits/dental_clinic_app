-- ============================================================
-- 007_PRODUCTION_DATA_INTEGRITY.SQL
-- Phase 1, Step 1: Database Migration for Production Integrity
-- 1. Payments Ledger Table & RLS
-- 2. Appointment Double-Booking / Collision Prevention
-- 3. Secure handle_new_user() Trigger against Privilege Escalation
-- ============================================================

-- ------------------------------------------------------------
-- 1. PAYMENTS LEDGER TABLE
-- ------------------------------------------------------------
-- Immutable financial audit log of counter/received payments.
-- Links to public.invoices and public.patients.
create table if not exists public.payments (
  id text primary key, -- e.g. 'PAY-2026-0001' or uuid
  invoice_id text not null references public.invoices(id) on delete cascade,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  amount numeric(10, 2) not null check (amount > 0),
  payment_method text not null, -- 'Cash', 'UPI', 'POS Card', 'Net Banking'
  transaction_ref text default '',
  receipt_number text not null,
  received_by_user_id uuid references public.profiles(id) on delete set null,
  received_by_name text not null default 'Clinic Staff',
  clinic_id text not null default 'CLINIC-01',
  notes text default '',
  payment_date timestamptz not null default now(),
  created_at timestamptz not null default now()
);

-- Performance & audit indexes for payments
create index if not exists idx_payments_invoice on public.payments(invoice_id);
create index if not exists idx_payments_patient on public.payments(patient_id);
create index if not exists idx_payments_date on public.payments(payment_date desc);
create index if not exists idx_payments_clinic on public.payments(clinic_id);

-- Enable RLS on public.payments
alter table public.payments enable row level security;

-- Drop any prior policies if re-run
drop policy if exists "Staff can view payments" on public.payments;
drop policy if exists "Staff can insert payments" on public.payments;
drop policy if exists "Admins can update payments" on public.payments;

-- Authenticated clinical staff (doctor, receptionist, admin) can view payment records
create policy "Staff can view payments"
  on public.payments for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Authenticated clinical staff can insert payment records
create policy "Staff can insert payments"
  on public.payments for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Only admins can modify existing payment records for ledger auditing integrity
create policy "Admins can update payments"
  on public.payments for update
  to authenticated
  using (public.user_role() = 'admin');

-- Allow clinical staff (doctors, receptionists, admins) to create patient bills/invoices
drop policy if exists "Staff can insert invoices" on public.invoices;
create policy "Staff can insert invoices"
  on public.invoices for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Allow clinical staff to insert itemized procedure rows
drop policy if exists "Staff can insert invoice items" on public.invoice_items;
create policy "Staff can insert invoice items"
  on public.invoice_items for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- ------------------------------------------------------------
-- 2. APPOINTMENT COLLISION PREVENTION
-- ------------------------------------------------------------
-- Prevent two appointments for the same doctor at the same date_time
-- for active appointments (excluding cancelled and noShow).
-- Check for existing duplicates first without deleting any records.

do $$
declare
  dup_count int := 0;
  conflict_details text := '';
  dup_rec record;
begin
  -- Identify and aggregate any duplicate active appointments for the same doctor at the same slot
  for dup_rec in (
    select doctor_id, date_time, count(*) as slot_count, string_agg(id, ', ') as appointment_ids
    from public.appointments
    where status not in ('cancelled', 'noShow')
    group by doctor_id, date_time
    having count(*) > 1
  ) loop
    dup_count := dup_count + 1;
    conflict_details := conflict_details || format(
      E'\n - Doctor: %s at %s (%s collisions, IDs: %s)',
      dup_rec.doctor_id,
      dup_rec.date_time,
      dup_rec.slot_count,
      dup_rec.appointment_ids
    );
  end loop;

  -- If duplicates exist, abort the transaction immediately without modifying any records
  if dup_count > 0 then
    raise exception 'Migration 007 aborted: Found % conflicting appointment slot(s) with active duplicates:%',
      dup_count,
      conflict_details
      using hint = 'Please resolve these duplicate appointment slots manually before creating the unique index.';
  end if;

  raise notice 'Verification passed: Zero active duplicate appointments found in public.appointments.';
end $$;

-- Create partial unique index to permanently block future double-bookings for the same doctor at the same time
create unique index if not exists uq_appointments_doctor_active_time
  on public.appointments (doctor_id, date_time)
  where status not in ('cancelled', 'noShow');

-- ------------------------------------------------------------
-- 3. SECURE HANDLE_NEW_USER() TRIGGER
-- ------------------------------------------------------------
-- Prevent public signup users from assigning themselves 'doctor' or 'admin'.
-- Preserve existing doctor/receptionist/admin workflow without email-based heuristics.

create or replace function public.handle_new_user()
returns trigger as $$
declare
  assigned_role text;
  assigned_name text;
  requested_role text;
  is_admin boolean;
begin
  requested_role := lower(trim(coalesce(new.raw_user_meta_data->>'role', '')));
  
  -- Determine whether the executing session is an admin or service_role
  is_admin := (
    public.user_role() = 'admin' or
    coalesce(current_setting('request.jwt.claim.role', true), '') = 'service_role'
  );

  -- Privilege protection:
  -- Only an administrator or service_role can create/assign 'doctor' or 'admin' roles.
  -- Public self-signups attempting to request 'doctor' or 'admin' are downgraded to 'patient'.
  if requested_role in ('doctor', 'admin') then
    if is_admin then
      assigned_role := requested_role;
    else
      assigned_role := 'patient';
    end if;
  elsif requested_role in ('receptionist', 'patient') then
    assigned_role := requested_role;
  else
    assigned_role := 'patient';
  end if;

  assigned_name := coalesce(
    nullif(trim(new.raw_user_meta_data->>'full_name'), ''),
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

-- Ensure trigger is attached to auth.users
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
