-- ============================================================
-- 002_RLS_POLICIES.SQL
-- Row Level Security (RLS) Policies for Clinic Operations
-- ============================================================

-- Helper function to fetch the current user's clinic role
create or replace function public.user_role()
returns text as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()),
    'anonymous'
  );
$$ language sql security definer;

-- Enable RLS across all tables
alter table public.profiles enable row level security;
alter table public.doctors enable row level security;
alter table public.patients enable row level security;
alter table public.appointments enable row level security;
alter table public.clinical_consultations enable row level security;
alter table public.clinical_prescriptions enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.call_reminders enable row level security;
alter table public.call_records enable row level security;
alter table public.message_records enable row level security;
alter table public.notifications enable row level security;

-- ------------------------------------------------------------
-- PROFILES POLICIES
-- ------------------------------------------------------------
create policy "Authenticated users can read clinic profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid());

create policy "Users can insert their own profile"
  on public.profiles for insert
  to authenticated
  with check (id = auth.uid());

-- ------------------------------------------------------------
-- DOCTORS POLICIES
-- ------------------------------------------------------------
create policy "Authenticated staff can view doctors"
  on public.doctors for select
  to authenticated
  using (true);

create policy "Doctors and admins can update doctor status"
  on public.doctors for update
  to authenticated
  using (public.user_role() in ('doctor', 'admin', 'receptionist'));

create policy "Admins can insert or delete doctors"
  on public.doctors for all
  to authenticated
  using (public.user_role() in ('admin', 'doctor'));

-- ------------------------------------------------------------
-- PATIENTS POLICIES
-- ------------------------------------------------------------
create policy "Authenticated clinic staff can view patients"
  on public.patients for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Clinic staff can insert patients"
  on public.patients for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Clinic staff can update patients"
  on public.patients for update
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- ------------------------------------------------------------
-- APPOINTMENTS POLICIES
-- ------------------------------------------------------------
create policy "Authenticated clinic staff can view appointments"
  on public.appointments for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Clinic staff can create appointments"
  on public.appointments for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Clinic staff can update appointments"
  on public.appointments for update
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

-- ------------------------------------------------------------
-- CLINICAL CONSULTATIONS & PRESCRIPTIONS POLICIES
-- ------------------------------------------------------------
create policy "Clinic staff can view consultations"
  on public.clinical_consultations for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Doctors can insert clinical consultations"
  on public.clinical_consultations for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'admin'));

create policy "Doctors can update clinical consultations"
  on public.clinical_consultations for update
  to authenticated
  using (public.user_role() in ('doctor', 'admin'));

create policy "Clinic staff can view prescriptions"
  on public.clinical_prescriptions for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Doctors can create clinical prescriptions"
  on public.clinical_prescriptions for insert
  to authenticated
  with check (public.user_role() in ('doctor', 'admin'));

-- ------------------------------------------------------------
-- INVOICES & INVOICE ITEMS POLICIES
-- ------------------------------------------------------------
create policy "Staff can view invoices"
  on public.invoices for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Receptionists and admins can manage invoices"
  on public.invoices for all
  to authenticated
  using (public.user_role() in ('receptionist', 'admin'))
  with check (public.user_role() in ('receptionist', 'admin'));

create policy "Staff can view invoice items"
  on public.invoice_items for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Receptionists and admins can manage invoice items"
  on public.invoice_items for all
  to authenticated
  using (public.user_role() in ('receptionist', 'admin'))
  with check (public.user_role() in ('receptionist', 'admin'));

-- ------------------------------------------------------------
-- CALL REMINDERS, CALL & MESSAGE RECORDS POLICIES
-- ------------------------------------------------------------
create policy "Staff can view call reminders"
  on public.call_reminders for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Receptionists and admins can manage call reminders"
  on public.call_reminders for all
  to authenticated
  using (public.user_role() in ('receptionist', 'admin'))
  with check (public.user_role() in ('receptionist', 'admin'));

create policy "Staff can view call records"
  on public.call_records for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Staff can insert call records"
  on public.call_records for insert
  to authenticated
  with check (public.user_role() in ('receptionist', 'admin', 'doctor'));

create policy "Staff can view message records"
  on public.message_records for select
  to authenticated
  using (public.user_role() in ('doctor', 'receptionist', 'admin'));

create policy "Staff can insert message records"
  on public.message_records for insert
  to authenticated
  with check (public.user_role() in ('receptionist', 'admin', 'doctor'));

-- ------------------------------------------------------------
-- NOTIFICATIONS POLICIES
-- ------------------------------------------------------------
create policy "Staff can view notifications"
  on public.notifications for select
  to authenticated
  using (true);

create policy "Staff can update notifications"
  on public.notifications for update
  to authenticated
  using (true);

create policy "Staff can insert notifications"
  on public.notifications for insert
  to authenticated
  with check (true);
