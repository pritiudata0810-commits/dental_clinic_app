-- ============================================================
-- 003_ADD_EXTENDED_COLUMNS.SQL
-- Migration to support extended patient demographic details
-- and printable receipt metadata.
-- ============================================================

-- 1. EXTEND PATIENTS TABLE
alter table if exists public.patients
  add column if not exists cr_number text default '',
  add column if not exists age text default '',
  add column if not exists father_or_guardian text default '',
  add column if not exists medical_alerts text[] default '{}';

-- 2. EXTEND INVOICES TABLE
alter table if exists public.invoices
  add column if not exists receipt_number text default '',
  add column if not exists received_by text default 'Mr. Ajay Dhanger',
  add column if not exists payment_status_text text default 'Settled',
  add column if not exists payment_date timestamptz;

-- Refresh PostgREST schema cache
notify pgrst, 'reload schema';
