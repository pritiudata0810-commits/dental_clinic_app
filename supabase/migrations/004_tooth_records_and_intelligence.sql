-- ============================================================
-- 004_TOOTH_RECORDS_AND_INTELLIGENCE.SQL
-- Phase 1: Digital Tooth Timeline & Clinical History Schema
-- ============================================================

-- 1. PATIENT TOOTH RECORDS (Digital Tooth Timeline History)
create table if not exists public.patient_tooth_records (
  id text primary key, -- e.g. 'TR-2026-0001' or uuid
  patient_id text not null references public.patients(id) on delete cascade,
  tooth_number int not null check (
    (tooth_number between 11 and 18) or
    (tooth_number between 21 and 28) or
    (tooth_number between 31 and 38) or
    (tooth_number between 41 and 48)
  ),
  status text not null default 'healthy' check (status in (
    'healthy', 'caries', 'filling', 'crown', 'rootCanal', 'extraction',
    'missing', 'implant', 'bridge', 'denture', 'fracture', 'underTreatment',
    'requiresFollowUp'
  )),
  procedure text not null default '',
  clinical_finding text not null default '',
  notes text not null default '',
  dentist_id text references public.doctors(id) on delete set null,
  dentist_name text not null default '',
  treatment_date timestamptz not null default now(),
  follow_up_date timestamptz,
  completion_status text not null default 'completed' check (completion_status in (
    'planned', 'inProgress', 'completed', 'requiresFollowUp'
  )),
  prescription_id uuid references public.clinical_prescriptions(id) on delete set null,
  attachment_urls text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Indexes for high-performance patient timeline lookups
create index if not exists idx_tooth_records_patient on public.patient_tooth_records(patient_id);
create index if not exists idx_tooth_records_tooth on public.patient_tooth_records(tooth_number);
create index if not exists idx_tooth_records_patient_tooth on public.patient_tooth_records(patient_id, tooth_number);
create index if not exists idx_tooth_records_date on public.patient_tooth_records(treatment_date desc);
create index if not exists idx_tooth_records_status on public.patient_tooth_records(status);

-- Enable Row Level Security (RLS)
alter table public.patient_tooth_records enable row level security;

-- RLS Policies
create policy "Authenticated staff can view tooth records"
  on public.patient_tooth_records for select
  using (auth.role() = 'authenticated');

create policy "Authenticated staff can insert tooth records"
  on public.patient_tooth_records for insert
  with check (auth.role() = 'authenticated');

create policy "Authenticated staff can update tooth records"
  on public.patient_tooth_records for update
  using (auth.role() = 'authenticated');

create policy "Authenticated staff can delete tooth records"
  on public.patient_tooth_records for delete
  using (auth.role() = 'authenticated');

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
