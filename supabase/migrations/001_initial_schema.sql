-- ============================================================
-- 001_INITIAL_SCHEMA.SQL
-- Dental Clinic Management System Schema
-- ============================================================

-- Enable pgcrypto for gen_random_uuid if not already enabled
create extension if not exists "pgcrypto";

-- 1. PROFILES (extends auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  role text not null check (role in ('doctor', 'receptionist', 'admin')),
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Index on profiles role and email
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_email on public.profiles(email);

-- 2. DOCTORS (Operatories and Doctor Roster)
create table if not exists public.doctors (
  id text primary key, -- e.g. 'DOC-01'
  user_id uuid references public.profiles(id) on delete set null,
  name text not null,
  specialization text not null,
  qualification text not null,
  status text not null default 'available' check (status in ('available', 'inConsultation', 'busy', 'onBreak', 'unavailable')),
  current_patient_name text,
  next_available_time text not null default '10:00 AM',
  room_number text not null,
  phone text not null,
  avatar_initials text not null,
  today_appointments_count int not null default 0,
  completed_today_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 3. PATIENTS
create table if not exists public.patients (
  id text primary key, -- e.g. 'P-1001'
  name text not null,
  phone text not null,
  email text not null default '',
  date_of_birth text not null default '',
  gender text not null default 'Other',
  address text not null default '',
  emergency_contact text not null default '',
  assigned_doctor_id text references public.doctors(id) on delete set null,
  assigned_doctor_name text not null default '',
  last_visit text not null default 'First Visit',
  next_appointment text,
  total_visits int not null default 1,
  balance_due numeric(10, 2) not null default 0.00,
  blood_group text not null default 'O+',
  allergies text[] not null default '{}',
  notes text not null default '',
  registration_date timestamptz not null default now(),
  cr_number text not null default '',
  age text not null default '',
  father_or_guardian text not null default '',
  medical_alerts text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_patients_phone on public.patients(phone);
create index if not exists idx_patients_name on public.patients(name);

-- 4. APPOINTMENTS (Schedule, Tokens, Waiting Room)
create table if not exists public.appointments (
  id text primary key, -- e.g. 'APT-001'
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  patient_phone text not null,
  doctor_id text not null references public.doctors(id) on delete cascade,
  doctor_name text not null,
  date_time timestamptz not null,
  time_string text not null,
  appointment_type text not null,
  duration_minutes int not null default 30,
  status text not null default 'scheduled' check (status in (
    'scheduled', 'confirmed', 'arrived', 'checkedIn', 'waiting', 'inProgress', 'completed', 'cancelled', 'noShow'
  )),
  token_number text not null,
  room_number text,
  notes text not null default '',
  check_in_time timestamptz,
  wait_minutes int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_appointments_date_time on public.appointments(date_time);
create index if not exists idx_appointments_doctor_id on public.appointments(doctor_id);
create index if not exists idx_appointments_patient_id on public.appointments(patient_id);
create index if not exists idx_appointments_status on public.appointments(status);

-- 5. CLINICAL CONSULTATIONS (Visit Notes & Treatment Record)
create table if not exists public.clinical_consultations (
  id uuid primary key default gen_random_uuid(),
  appointment_id text references public.appointments(id) on delete set null,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  doctor_id text not null references public.doctors(id) on delete cascade,
  doctor_name text not null,
  reason_for_visit text not null,
  examination_findings text not null default '',
  diagnosis text not null default '',
  clinical_notes text not null default '',
  procedure_code text not null default '',
  operative_notes text not null default '',
  total_fee numeric(10, 2) not null default 0.00,
  created_at timestamptz not null default now()
);

create index if not exists idx_consultations_patient on public.clinical_consultations(patient_id);
create index if not exists idx_consultations_doctor on public.clinical_consultations(doctor_id);

-- 6. CLINICAL PRESCRIPTIONS (Rx Entries)
create table if not exists public.clinical_prescriptions (
  id uuid primary key default gen_random_uuid(),
  consultation_id uuid not null references public.clinical_consultations(id) on delete cascade,
  patient_id text not null references public.patients(id) on delete cascade,
  medicine_name text not null,
  dosage text not null,
  frequency text not null,
  timing text not null default 'After Food',
  duration text not null default '5 days',
  instructions text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists idx_prescriptions_consultation on public.clinical_prescriptions(consultation_id);

-- 7. INVOICES
create table if not exists public.invoices (
  id text primary key, -- e.g. 'INV-2026-0042'
  invoice_number text not null unique,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  patient_phone text not null,
  doctor_id text not null references public.doctors(id) on delete cascade,
  doctor_name text not null,
  date timestamptz not null default now(),
  subtotal numeric(10, 2) not null default 0.00,
  discount numeric(10, 2) default 0.00,
  tax numeric(10, 2) default 0.00,
  total_amount numeric(10, 2) not null default 0.00,
  paid_amount numeric(10, 2) not null default 0.00,
  balance_amount numeric(10, 2) not null default 0.00,
  status text not null default 'pending' check (status in ('paid', 'pending', 'partial', 'refunded')),
  payment_method text not null default 'Cash',
  transaction_ref text,
  notes text not null default '',
  receipt_number text not null default '',
  received_by text not null default 'Mr. Ajay Dhanger',
  payment_status_text text not null default 'Settled',
  payment_date timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_invoices_patient on public.invoices(patient_id);
create index if not exists idx_invoices_status on public.invoices(status);

-- 8. INVOICE ITEMS
create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id text not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity int not null default 1,
  unit_price numeric(10, 2) not null default 0.00,
  amount numeric(10, 2) not null default 0.00
);

create index if not exists idx_invoice_items_invoice on public.invoice_items(invoice_id);

-- 9. CALL REMINDERS (Dedicated Outbound Communication Workstation)
create table if not exists public.call_reminders (
  id text primary key,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  phone_number text not null,
  appointment_date text not null,
  appointment_time text not null,
  doctor_name text not null,
  status text not null default 'pending' check (status in (
    'pending', 'called', 'answered', 'missed', 'retryRequired', 'confirmed', 'cancelled'
  )),
  last_attempt text not null default 'Not called',
  next_attempt text not null default 'Today before 12:00 PM',
  appointment_type text not null default 'Consultation',
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_call_reminders_status on public.call_reminders(status);

-- 10. CALL RECORDS & MESSAGE RECORDS
create table if not exists public.call_records (
  id text primary key,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  phone_number text not null,
  timestamp timestamptz not null default now(),
  duration_seconds int not null default 0,
  direction text not null check (direction in ('incoming', 'outgoing', 'missed')),
  status text not null check (status in ('answered', 'missed', 'busy', 'declined')),
  note text
);

create table if not exists public.message_records (
  id text primary key,
  patient_id text not null references public.patients(id) on delete cascade,
  patient_name text not null,
  phone_number text not null,
  channel text not null check (channel in ('sms', 'whatsapp')),
  message text not null,
  template_category text not null default 'Custom',
  timestamp timestamptz not null default now(),
  status text not null default 'sent' check (status in ('sent', 'delivered', 'failed', 'read'))
);

-- 11. NOTIFICATIONS
create table if not exists public.notifications (
  id text primary key,
  title text not null,
  message text not null,
  timestamp timestamptz not null default now(),
  is_read boolean not null default false,
  type text not null check (type in ('appointment', 'checkIn', 'doctorAvailable', 'paymentPending', 'reminder'))
);

create index if not exists idx_notifications_is_read on public.notifications(is_read);
