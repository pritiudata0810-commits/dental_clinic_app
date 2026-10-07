-- ============================================================
-- 006_REAL_CALLING_SYSTEM.SQL
-- Real Telephony Integration, Call Records & RLS Security
-- ============================================================

-- 1. EXTEND CALL RECORDS TABLE FOR REAL TELEPHONY & AUDITING
-- Add multi-clinic, staff audit, and call-type columns if they don't exist
alter table if exists public.call_records
  add column if not exists staff_user_id uuid references auth.users(id) on delete set null,
  add column if not exists staff_name text default '',
  add column if not exists clinic_id text not null default 'CLINIC-01',
  add column if not exists call_type text not null default 'voice',
  add column if not exists error_message text,
  add column if not exists created_at timestamptz not null default now();

-- Update status check constraint to include real telephony statuses
alter table if exists public.call_records
  drop constraint if exists call_records_status_check;

alter table if exists public.call_records
  add constraint call_records_status_check
  check (status in (
    'dialer_opened',
    'initiated',
    'completed',
    'answered',
    'missed',
    'busy',
    'declined',
    'failed',
    'cancelled'
  ));

-- Update direction check constraint
alter table if exists public.call_records
  drop constraint if exists call_records_direction_check;

alter table if exists public.call_records
  add constraint call_records_direction_check
  check (direction in ('incoming', 'outgoing', 'missed'));

-- Indexes for performant patient and staff history queries
create index if not exists idx_call_records_patient on public.call_records(patient_id);
create index if not exists idx_call_records_clinic on public.call_records(clinic_id);
create index if not exists idx_call_records_staff on public.call_records(staff_user_id);
create index if not exists idx_call_records_created on public.call_records(created_at desc);

-- 2. SECURE ROW-LEVEL SECURITY (RLS) FOR CALL RECORDS
alter table public.call_records enable row level security;

drop policy if exists "Staff can view call records" on public.call_records;
drop policy if exists "Staff can insert call records" on public.call_records;
drop policy if exists "Staff can update call records" on public.call_records;

-- Only authenticated staff (doctor, receptionist, admin) can view call records
create policy "Staff can view call records"
  on public.call_records for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Only authenticated staff can insert call records for their authorized clinic
create policy "Staff can insert call records"
  on public.call_records for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- Only staff can update existing call records (e.g. adding follow-up notes)
create policy "Staff can update call records"
  on public.call_records for update
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- 3. EXTEND CALL REMINDERS RLS
alter table public.call_reminders enable row level security;

drop policy if exists "Staff can view call reminders" on public.call_reminders;
drop policy if exists "Receptionists and admins can manage call reminders" on public.call_reminders;

create policy "Staff can view call reminders"
  on public.call_reminders for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Receptionists and admins can manage call reminders"
  on public.call_reminders for all
  to authenticated
  using (public.user_role() in ('receptionist', 'admin'))
  with check (public.user_role() in ('receptionist', 'admin'));

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
