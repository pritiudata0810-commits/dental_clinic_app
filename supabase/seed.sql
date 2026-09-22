-- ============================================================
-- SEED.SQL
-- Initial Seed Data for SmileCare Dental Clinic OS
-- ============================================================

-- 1. DOCTORS SEED
insert into public.doctors (id, name, specialization, qualification, status, current_patient_name, next_available_time, room_number, phone, avatar_initials, today_appointments_count, completed_today_count)
values
  ('DOC-01', 'Dr. Rahul Sharma', 'Chief Dentist & Implantologist', 'BDS, MDS (Prosthodontics)', 'available', null, '10:30 AM', 'Operatory 1', '+91 98201 11223', 'RS', 8, 3),
  ('DOC-02', 'Dr. Priya Mehta', 'Orthodontist & Pedodontist', 'BDS, MDS (Orthodontics)', 'inConsultation', 'Aarav Sharma', '11:15 AM', 'Operatory 2', '+91 98202 22334', 'PM', 10, 4),
  ('DOC-03', 'Dr. Amit Shah', 'Endodontist (Root Canal Specialist)', 'BDS, MDS (Conservative Dentistry)', 'busy', 'Neha Kapoor', '11:45 AM', 'Operatory 3', '+91 98203 33445', 'AS', 6, 2)
on conflict (id) do update set
  name = excluded.name,
  specialization = excluded.specialization,
  status = excluded.status;

-- 2. PATIENTS SEED
insert into public.patients (id, name, phone, email, date_of_birth, gender, address, emergency_contact, assigned_doctor_id, assigned_doctor_name, last_visit, next_appointment, total_visits, balance_due, blood_group, allergies, notes, registration_date)
values
  ('P-1001', 'Aarav Sharma', '+91 98765 43210', 'aarav.sharma@gmail.com', '14 May 1994', 'Male', 'B-402, Green Glen Heights, Bellandur, Bengaluru', 'Sunita Sharma (Mother) +91 98765 43219', 'DOC-02', 'Dr. Priya Mehta', '05 Sep 2026', 'Today, 10:00 AM', 4, 1500.00, 'B+', array['Penicillin'], 'Patient experiences mild dental anxiety. Prefers topical anesthetic spray first.', '2025-03-12 00:00:00+00'),
  ('P-1002', 'Neha Kapoor', '+91 98112 34567', 'neha.kapoor@outlook.com', '22 Aug 1988', 'Female', 'Villa 14, Palm Meadows, Whitefield, Bengaluru', 'Rajesh Kapoor (Spouse) +91 98112 34568', 'DOC-03', 'Dr. Amit Shah', '12 Sep 2026', 'Today, 10:30 AM', 6, 0.00, 'O+', array[]::text[], 'Undergoing step-2 root canal treatment on lower right molar (#46).', '2024-11-20 00:00:00+00'),
  ('P-1003', 'Rohan Singh', '+91 97234 56789', 'rohan.singh@gmail.com', '03 Dec 1991', 'Male', 'Flat 102, Silver Spring, HSR Layout, Bengaluru', 'Pooja Singh (Wife) +91 97234 56780', 'DOC-01', 'Dr. Rahul Sharma', '18 Aug 2026', 'Today, 11:00 AM', 2, 800.00, 'A+', array['Latex sensitivity'], 'Complained of food lodgement between upper left molars. Composite filling suggested.', '2026-01-15 00:00:00+00'),
  ('P-1004', 'Ananya Patel', '+91 96345 67890', 'ananya.patel@yahoo.com', '19 Oct 1999', 'Female', 'House 88, 12th Main, Indiranagar, Bengaluru', 'Meera Patel (Mother) +91 96345 67899', 'DOC-02', 'Dr. Priya Mehta', '25 Jul 2026', 'Today, 11:30 AM', 5, 0.00, 'AB+', array[]::text[], 'Routine aligners tracking checkup. Wearing tray #14.', '2025-08-05 00:00:00+00'),
  ('P-1005', 'Vikram Malhotra', '+91 95456 78901', 'vikram.m@techcorp.in', '07 Feb 1978', 'Male', 'Penthouse 4, Prestige Palms, Koramangala, Bengaluru', 'Simran Malhotra (Spouse) +91 95456 78900', 'DOC-01', 'Dr. Rahul Sharma', '01 Sep 2026', 'Today, 02:00 PM', 8, 4200.00, 'O-', array['Sulfa drugs'], 'Full mouth rehabilitation stage. Ceramic crown trial scheduled.', '2024-06-18 00:00:00+00'),
  ('P-1006', 'Pooja Hegde', '+91 94567 89012', 'pooja.hegde@rediffmail.com', '30 Jun 1996', 'Female', '34, 4th Cross, Malleshwaram, Bengaluru', 'Vinay Hegde (Brother) +91 94567 89010', 'DOC-02', 'Dr. Priya Mehta', '15 Aug 2026', 'Today, 02:30 PM', 3, 0.00, 'B+', array[]::text[], 'Teeth whitening follow-up. Shade A1 achieved.', '2025-10-02 00:00:00+00'),
  ('P-1007', 'Kavita Sundaram', '+91 93678 90123', 'kavita.s@gmail.com', '11 Sep 1983', 'Female', 'A-201, Sobha City, Thanisandra Main Rd, Bengaluru', 'S. Sundaram (Father) +91 93678 90129', 'DOC-01', 'Dr. Rahul Sharma', '28 Aug 2026', 'Today, 03:30 PM', 1, 0.00, 'A-', array[]::text[], 'First visit for tooth sensitivity evaluation.', '2024-02-10 00:00:00+00'),
  ('P-1008', 'Sunita Rao', '+91 91234 56781', 'sunita.rao@gmail.com', '08 Mar 1965', 'Female', 'Plot 45, JP Nagar 3rd Phase, Bengaluru', 'Girish Rao (Son) +91 91234 56789', 'DOC-03', 'Dr. Amit Shah', '20 Aug 2026', 'Tomorrow, 11:30 AM', 4, 3500.00, 'O+', array['NSAIDs / Ibuprofen'], 'Diabetic patient. Check blood sugar report before surgical extractions.', '2025-01-09 00:00:00+00')
on conflict (id) do update set
  name = excluded.name,
  phone = excluded.phone,
  balance_due = excluded.balance_due;

-- 3. APPOINTMENTS SEED
insert into public.appointments (id, patient_id, patient_name, patient_phone, doctor_id, doctor_name, date_time, time_string, appointment_type, duration_minutes, status, token_number, room_number, notes, wait_minutes)
values
  ('APT-001', 'P-1001', 'Aarav Sharma', '+91 98765 43210', 'DOC-02', 'Dr. Priya Mehta', now(), '10:00 AM', 'Routine Checkup', 30, 'inProgress', 'TK-01', 'Operatory 2', 'Routine orthodontic bracket adjustment', 12),
  ('APT-002', 'P-1002', 'Neha Kapoor', '+91 98112 34567', 'DOC-03', 'Dr. Amit Shah', now() + interval '30 minutes', '10:30 AM', 'Root Canal Consultation', 45, 'waiting', 'TK-02', 'Operatory 3', 'RCT Step 2 obturation for tooth #46', 18),
  ('APT-003', 'P-1003', 'Rohan Singh', '+91 97234 56789', 'DOC-01', 'Dr. Rahul Sharma', now() + interval '60 minutes', '11:00 AM', 'Dental Filling', 30, 'checkedIn', 'TK-03', 'Operatory 1', 'Composite restoration upper left premolar', 8),
  ('APT-004', 'P-1004', 'Ananya Patel', '+91 96345 67890', 'DOC-02', 'Dr. Priya Mehta', now() + interval '90 minutes', '11:30 AM', 'Orthodontic Review', 20, 'arrived', 'TK-04', 'Operatory 2', 'Aligner tracking check tray #14', 5),
  ('APT-005', 'P-1005', 'Vikram Malhotra', '+91 95456 78901', 'DOC-01', 'Dr. Rahul Sharma', now() + interval '4 hours', '02:00 PM', 'Crown & Bridge Trial', 45, 'confirmed', 'TK-05', 'Operatory 1', 'Zirconia crown delivery #16 and #17', 0),
  ('APT-006', 'P-1006', 'Pooja Hegde', '+91 94567 89012', 'DOC-02', 'Dr. Priya Mehta', now() + interval '4 hours 30 minutes', '02:30 PM', 'Follow-up', 20, 'scheduled', 'TK-06', 'Operatory 2', 'Bleaching shade verification', 0),
  ('APT-007', 'P-1007', 'Kavita Sundaram', '+91 93678 90123', 'DOC-01', 'Dr. Rahul Sharma', now() + interval '5 hours 30 minutes', '03:30 PM', 'General Consultation', 30, 'scheduled', 'TK-07', 'Operatory 1', 'Tooth sensitivity evaluation', 0)
on conflict (id) do update set
  status = excluded.status,
  time_string = excluded.time_string;

-- 4. CALL REMINDERS SEED
insert into public.call_reminders (id, patient_id, patient_name, phone_number, appointment_date, appointment_time, doctor_name, status, last_attempt, next_attempt, appointment_type, notes)
values
  ('REM-001', 'P-1005', 'Vikram Malhotra', '+91 95456 78901', 'Today, 20 Sep 2026', '02:00 PM', 'Dr. Rahul Sharma', 'pending', 'Not called', 'Today before 12:00 PM', 'Crown Trial', 'Confirm arrival with previous lab impressions'),
  ('REM-002', 'P-1006', 'Pooja Hegde', '+91 94567 89012', 'Today, 20 Sep 2026', '02:30 PM', 'Dr. Priya Mehta', 'confirmed', 'Today 09:10 AM - Answered', 'None', 'Teeth Whitening', 'Confirmed arrival by patient'),
  ('REM-003', 'P-1007', 'Kavita Sundaram', '+91 93678 90123', 'Today, 20 Sep 2026', '03:30 PM', 'Dr. Rahul Sharma', 'missed', 'Today 09:25 AM - No Answer', 'Retry at 11:30 AM', 'New Consultation', 'Need to verify if attending with previous dental X-rays'),
  ('REM-004', 'P-1008', 'Sunita Rao', '+91 91234 56781', 'Tomorrow, 21 Sep 2026', '11:30 AM', 'Dr. Amit Shah', 'retryRequired', 'Yesterday 05:00 PM - Switched Off', 'Today before 01:00 PM', 'Root Canal Step 3', 'High priority - diabetic history review')
on conflict (id) do update set
  status = excluded.status,
  last_attempt = excluded.last_attempt;

-- 5. INVOICES & INVOICE ITEMS SEED
insert into public.invoices (id, invoice_number, patient_id, patient_name, patient_phone, doctor_id, doctor_name, date, subtotal, discount, tax, total_amount, paid_amount, balance_amount, status, payment_method, transaction_ref, notes)
values
  ('INV-001', 'INV-2026-0101', 'P-1001', 'Aarav Sharma', '+91 98765 43210', 'DOC-02', 'Dr. Priya Mehta', now() - interval '2 days', 3500.00, 500.00, 0.00, 3000.00, 1500.00, 1500.00, 'partial', 'UPI', 'UPI/20260918/98765', 'Part payment received via PhonePe'),
  ('INV-002', 'INV-2026-0102', 'P-1002', 'Neha Kapoor', '+91 98112 34567', 'DOC-03', 'Dr. Amit Shah', now() - interval '1 day', 4500.00, 0.00, 0.00, 4500.00, 4500.00, 0.00, 'paid', 'Card', 'POS/HDFC/4421', 'Root canal step 1 and temporary filling'),
  ('INV-003', 'INV-2026-0103', 'P-1003', 'Rohan Singh', '+91 97234 56789', 'DOC-01', 'Dr. Rahul Sharma', now() - interval '3 days', 1800.00, 0.00, 0.00, 1800.00, 1000.00, 800.00, 'partial', 'Cash', null, 'Scaling and polishing complete')
on conflict (id) do update set
  status = excluded.status,
  paid_amount = excluded.paid_amount;

insert into public.invoice_items (invoice_id, description, quantity, unit_price, amount)
values
  ('INV-001', 'Orthodontic Consultation & Wire Adjustment', 1, 3500.00, 3500.00),
  ('INV-002', 'Root Canal Treatment (Molar - Step 1)', 1, 4500.00, 4500.00),
  ('INV-003', 'Full Mouth Ultrasonic Scaling', 1, 1800.00, 1800.00);

-- 6. NOTIFICATIONS SEED
insert into public.notifications (id, title, message, timestamp, is_read, type)
values
  ('NOTIF-001', 'Patient Arrived at Reception', 'Ananya Patel (Token TK-04) has arrived at the reception waiting area.', now() - interval '10 minutes', false, 'checkIn'),
  ('NOTIF-002', 'New Online Booking', 'Vikram Malhotra scheduled Crown & Bridge Trial for 02:00 PM with Dr. Rahul Sharma.', now() - interval '45 minutes', false, 'appointment'),
  ('NOTIF-003', 'Doctor Operatory Ready', 'Dr. Rahul Sharma is available in Operatory 1 for consultation.', now() - interval '1 hour', true, 'doctorAvailable')
on conflict (id) do update set
  is_read = excluded.is_read;
