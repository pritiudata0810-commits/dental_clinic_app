import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/billing.dart';
import '../models/payment_record.dart';
import '../models/communication.dart';
import '../models/notification_item.dart';
import '../models/call_reminder.dart';
import '../models/tooth_record.dart';
import '../mock_data/mock_clinic_data.dart';
import '../services/patient_service.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';
import '../services/billing_service.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../services/tooth_service.dart';
import '../services/supabase_service.dart';
import '../services/telephony/call_service.dart';
import '../services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicState extends ChangeNotifier {
  final PatientService _patientService = PatientService();
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final BillingService _billingService = BillingService();
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();
  final ToothService _toothService = ToothService();

  List<Doctor> _doctors = [];
  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<Invoice> _invoices = [];
  List<CallRecord> _callRecords = [];
  List<MessageRecord> _messageRecords = [];
  List<NotificationItem> _notifications = [];
  List<CallReminder> _callReminders = [];
  List<ToothRecord> _toothRecords = [];
  List<PaymentRecord> _paymentRecords = [];

  bool _isLoading = false;
  bool _isLoadingRemote = false;
  String? _remoteDataError;
  final Map<String, String> _domainErrors = {};
  String _searchQuery = '';
  String? _selectedDoctorFilter;

  // Active navigation index for receptionist sidebar
  int _currentNavIndex = 0;

  bool get isLoadingRemote => _isLoadingRemote;
  String? get remoteDataError => _remoteDataError;
  bool get hasRemoteError => _remoteDataError != null;

  Map<String, String> get domainErrors => Map.unmodifiable(_domainErrors);
  String? get appointmentsError => _getDomainError('Appointments');
  String? get patientsError => _getDomainError('Patients');
  String? get doctorsError => _getDomainError('Doctors');
  String? get billingError => _getDomainError('Invoices');
  String? get paymentsError => _getDomainError('Payments') ?? _getDomainError('Invoices');
  String? get toothRecordsError => _getDomainError('Tooth Records');
  String? get notificationsError => _getDomainError('Notifications');
  String? get remindersError => _getDomainError('Reminders');

  bool isDomainAvailable(String domain) => _getDomainError(domain) == null;

  String? _getDomainError(String domain) {
    if (_domainErrors.containsKey(domain)) {
      return _domainErrors[domain];
    }
    // If a global connection outage is set (not a multi-domain prefix list), treat as affecting all domains
    if (_remoteDataError != null &&
        !_remoteDataError!.startsWith('Failed to load live data from Supabase:')) {
      return _remoteDataError;
    }
    return null;
  }

  void clearRemoteError() {
    _remoteDataError = null;
    _domainErrors.clear();
    notifyListeners();
  }

  @visibleForTesting
  void setRemoteErrorForTesting(String? error) {
    _remoteDataError = error;
    _domainErrors.clear();
    if (error != null && error.startsWith('Failed to load live data from Supabase:')) {
      final domainsStr = error.replaceFirst('Failed to load live data from Supabase:', '').trim();
      final domains = domainsStr.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty);
      for (final d in domains) {
        _domainErrors[d] = 'Failed to load live data from Supabase: $d';
      }
    }
    notifyListeners();
  }

  @visibleForTesting
  void setDomainErrorForTesting(String domain, String? error) {
    if (error == null) {
      _domainErrors.remove(domain);
    } else {
      _domainErrors[domain] = error;
    }
    if (_domainErrors.isNotEmpty) {
      _remoteDataError = 'Failed to load live data from Supabase: ${_domainErrors.keys.join(', ')}';
    } else {
      _remoteDataError = null;
    }
    notifyListeners();
  }

  @visibleForTesting
  void setPatientsForTesting(List<Patient> patients) {
    _patients = List.from(patients);
    notifyListeners();
  }

  @visibleForTesting
  void setAppointmentsForTesting(List<Appointment> appointments) {
    _appointments = List.from(appointments);
    notifyListeners();
  }

  @visibleForTesting
  void setInvoicesForTesting(List<Invoice> invoices) {
    _invoices = List.from(invoices);
    notifyListeners();
  }

  @visibleForTesting
  void setCallRemindersForTesting(List<CallReminder> reminders) {
    _callReminders = List.from(reminders);
    notifyListeners();
  }

  @visibleForTesting
  void setPaymentRecordsForTesting(List<PaymentRecord> records) {
    _paymentRecords = List.from(records);
    notifyListeners();
  }

  @visibleForTesting
  void setToothRecordsForTesting(List<ToothRecord> records) {
    _toothRecords = List.from(records);
    notifyListeners();
  }

  // Constructor & Init
  ClinicState({bool forceMockForTesting = false}) {
    _loadInitialData(forceMockForTesting: forceMockForTesting);
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final client = SupabaseService.instance.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.userUpdated) {
          _fetchRemoteData();
        } else if (event == AuthChangeEvent.signedOut) {
          // Clear sensitive records upon sign out
          _patients = [];
          _appointments = [];
          _invoices = [];
          _callRecords = [];
          _messageRecords = [];
          _toothRecords = [];
          _remoteDataError = null;
          _domainErrors.clear();
          notifyListeners();
        }
      });
    }
  }

  /// Manually trigger a fresh pull of all records from Supabase
  Future<void> refreshRemoteData() async {
    await _fetchRemoteData();
  }

  void _loadInitialData({bool forceMockForTesting = false}) {
    if (SupabaseService.instance.isInitialized && !forceMockForTesting) {
      // Production: Supabase is the single source of truth.
      // Start with empty lists, zero mock fallbacks.
      _doctors = [];
      _patients = [];
      _appointments = [];
      _invoices = [];
      _callRecords = [];
      _messageRecords = [];
      _notifications = [];
      _callReminders = [];
      _toothRecords = [];
      _fetchRemoteData();
    } else {
      // Test harness fallback: active only in test environments where Supabase is not initialized
      _doctors = MockClinicData.getDoctors();
      _patients = MockClinicData.getPatients();
      _appointments = MockClinicData.getAppointments();
      _invoices = MockClinicData.getInvoices();
      _callRecords = MockClinicData.getCallRecords();
      _messageRecords = MockClinicData.getMessageRecords();
      _notifications = MockClinicData.getNotifications();
      _callReminders = MockClinicData.getCallReminders();
      _toothRecords = MockClinicData.getToothRecords();
    }
  }

  Future<void> _fetchRemoteData() async {
    _isLoadingRemote = true;
    notifyListeners();

    try {
      _domainErrors.clear();
      final List<String> failedDomains = [];

      final remoteDoctors = await _doctorService.fetchDoctors();
      if (remoteDoctors != null) {
        _doctors = remoteDoctors;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Doctors');
        _domainErrors['Doctors'] = 'Failed to load Doctors from Supabase';
      }

      final remotePatients = await _patientService.fetchPatients();
      if (remotePatients != null) {
        _patients = remotePatients;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Patients');
        _domainErrors['Patients'] = 'Failed to load Patients from Supabase';
      }

      final remoteAppointments = await _appointmentService.fetchAppointments();
      if (remoteAppointments != null) {
        _appointments = remoteAppointments;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Appointments');
        _domainErrors['Appointments'] = 'Failed to load Appointments from Supabase';
      }

      final remoteInvoices = await _billingService.fetchInvoices();
      if (remoteInvoices != null) {
        _invoices = remoteInvoices;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Invoices');
        _domainErrors['Invoices'] = 'Failed to load Invoices from Supabase';
      }

      final remoteReminders = await _reminderService.fetchReminders();
      if (remoteReminders != null) {
        _callReminders = remoteReminders;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Reminders');
        _domainErrors['Reminders'] = 'Failed to load Reminders from Supabase';
      }

      final remoteNotifications = await _notificationService.fetchNotifications();
      if (remoteNotifications != null) {
        _notifications = remoteNotifications;
        if (SupabaseService.instance.isInitialized) {
          _notificationService.initRealtimeSubscription(
            onInsert: (item) {
              final exists = _notifications.any((n) => n.id == item.id);
              if (!exists) {
                _notifications.insert(0, item);
                notifyListeners();
              }
            },
            onUpdate: (item) {
              final idx = _notifications.indexWhere((n) => n.id == item.id);
              if (idx != -1) {
                _notifications[idx] = item;
                notifyListeners();
              }
            },
          );
        }
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Notifications');
        _domainErrors['Notifications'] = 'Failed to load Notifications from Supabase';
      }

      final remoteToothRecords = await _toothService.fetchToothRecords();
      if (remoteToothRecords != null) {
        _toothRecords = remoteToothRecords;
      } else if (SupabaseService.instance.isInitialized) {
        failedDomains.add('Tooth Records');
        _domainErrors['Tooth Records'] = 'Failed to load Tooth Records from Supabase';
      }

      final remoteCallRecords = await CallService.instance.fetchCallHistory();
      _callRecords = remoteCallRecords;

      if (failedDomains.isNotEmpty) {
        _remoteDataError = 'Failed to load live data from Supabase: ${failedDomains.join(', ')}';
      } else {
        _remoteDataError = null;
      }
    } catch (e) {
      debugPrint('[ClinicState] Background Supabase fetch error: $e');
      _remoteDataError = 'Connection error communicating with Supabase: $e';
    } finally {
      _isLoadingRemote = false;
      notifyListeners();
    }
  }

  // Getters
  List<Doctor> get doctors => List.unmodifiable(_doctors);
  List<Patient> get patients => List.unmodifiable(_patients);
  List<Appointment> get appointments => List.unmodifiable(_appointments);
  List<Invoice> get invoices => List.unmodifiable(_invoices);
  List<CallRecord> get callRecords => List.unmodifiable(_callRecords);
  List<MessageRecord> get messageRecords => List.unmodifiable(_messageRecords);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  List<CallReminder> get callReminders => List.unmodifiable(_callReminders);
  List<ToothRecord> get toothRecords => List.unmodifiable(_toothRecords);
  List<PaymentRecord> get paymentRecords => List.unmodifiable(_paymentRecords);

  List<ToothRecord> getToothRecordsForPatient(String patientId) {
    return _toothRecords
        .where((r) => r.patientId == patientId)
        .toList()
      ..sort((a, b) => b.treatmentDate.compareTo(a.treatmentDate));
  }

  Map<int, ToothRecord> getLatestTeethMap(String patientId) {
    final records = getToothRecordsForPatient(patientId);
    final Map<int, ToothRecord> map = {};
    for (final r in records) {
      if (!map.containsKey(r.toothNumber)) {
        map[r.toothNumber] = r;
      }
    }
    return map;
  }

  Future<bool> addToothRecord(ToothRecord record) async {
    final saved = await _toothService.saveToothRecord(record);
    if (saved == null) {
      debugPrint('[ClinicState] Failed to save tooth record to Supabase: ${record.id}');
      return false;
    }
    _toothRecords.insert(0, saved);
    notifyListeners();
    return true;
  }

  Future<bool> updateToothRecord(ToothRecord record) async {
    final saved = await _toothService.saveToothRecord(record);
    if (saved == null) {
      debugPrint('[ClinicState] Failed to update tooth record to Supabase: ${record.id}');
      return false;
    }
    final idx = _toothRecords.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _toothRecords[idx] = saved;
    } else {
      _toothRecords.insert(0, saved);
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteToothRecord(String id) async {
    final success = await _toothService.deleteToothRecord(id);
    if (!success) {
      debugPrint('[ClinicState] Failed to delete tooth record on Supabase: $id');
      return false;
    }
    _toothRecords.removeWhere((r) => r.id == id);
    notifyListeners();
    return true;
  }

  int get pendingRemindersCount => _callReminders.where((r) => r.status == ReminderStatus.pending || r.status == ReminderStatus.retryRequired).length;
  int get confirmedRemindersCount => _callReminders.where((r) => r.status == ReminderStatus.confirmed).length;
  int get missedRemindersCount => _callReminders.where((r) => r.status == ReminderStatus.missed).length;
  int get remainingRemindersCount => _callReminders.where((r) => r.status != ReminderStatus.confirmed && r.status != ReminderStatus.cancelled).length;

  void updateReminderStatus(String id, ReminderStatus newStatus, {String? lastAttempt, String? nextAttempt}) {
    final index = _callReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _callReminders[index] = _callReminders[index].copyWith(
        status: newStatus,
        lastAttempt: lastAttempt ?? _callReminders[index].lastAttempt,
        nextAttempt: nextAttempt ?? _callReminders[index].nextAttempt,
      );
      notifyListeners();

      // Persist to Supabase
      _reminderService.updateStatus(
        id,
        newStatus,
        lastAttempt: lastAttempt,
        nextAttempt: nextAttempt,
      );
    }
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedDoctorFilter => _selectedDoctorFilter;
  int get currentNavIndex => _currentNavIndex;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.isRead).length;

  void setNavIndex(int index) {
    if (_currentNavIndex != index) {
      _currentNavIndex = index;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDoctorFilter(String? doctorId) {
    _selectedDoctorFilter = doctorId;
    notifyListeners();
  }

  // TODAY & TOMORROW FILTERED APPOINTMENTS
  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    return _appointments.where((apt) {
      return apt.dateTime.year == now.year &&
          apt.dateTime.month == now.month &&
          apt.dateTime.day == now.day;
    }).toList();
  }

  List<Appointment> get tomorrowAppointments {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _appointments.where((apt) {
      return apt.dateTime.year == tomorrow.year &&
          apt.dateTime.month == tomorrow.month &&
          apt.dateTime.day == tomorrow.day;
    }).toList();
  }

  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((apt) {
      return apt.dateTime.year == date.year &&
          apt.dateTime.month == date.month &&
          apt.dateTime.day == date.day;
    }).toList();
  }

  // WAITING ROOM ACTIVE PATIENTS (Arrived, Checked In, Waiting, In Progress)
  List<Appointment> get waitingRoomPatients {
    return todayAppointments.where((apt) => apt.status.isWaitingRoomActive).toList();
  }

  int get waitingRoomCount {
    return todayAppointments
        .where((apt) =>
            apt.status == AppointmentStatus.waiting ||
            apt.status == AppointmentStatus.checkedIn ||
            apt.status == AppointmentStatus.arrived)
        .length;
  }

  int get availableDoctorsCount {
    return _doctors.where((d) => d.status == DoctorStatus.available).length;
  }

  int get consultingDoctorsCount {
    return _doctors.where((d) => d.status == DoctorStatus.inConsultation).length;
  }

  double get todayBillingTotal {
    return _invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);
  }

  double get todayCollectedTotal {
    return _invoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);
  }

  // WORKFLOW ACTIONS: Moving patient through waiting room pipeline
  // Scheduled -> Arrived -> Checked In -> Waiting -> With Doctor -> Completed
  Future<bool> updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return false;

    final old = _appointments[index];
    final DateTime? updatedCheckIn = (newStatus == AppointmentStatus.checkedIn ||
            newStatus == AppointmentStatus.arrived) &&
        old.checkInTime == null
        ? DateTime.now()
        : old.checkInTime;

    final success = await _appointmentService.updateStatus(
      appointmentId,
      newStatus,
      checkInTime: updatedCheckIn,
    );

    if (!success) {
      debugPrint('[ClinicState] Failed to update appointment status on Supabase for $appointmentId');
      return false;
    }

    final updated = old.copyWith(
      status: newStatus,
      checkInTime: updatedCheckIn,
    );
    _appointments[index] = updated;

    // Update doctor status if moved to InProgress or Completed
    if (newStatus == AppointmentStatus.inProgress) {
      final docIndex = _doctors.indexWhere((d) => d.id == old.doctorId);
      if (docIndex != -1) {
        _doctors[docIndex] = _doctors[docIndex].copyWith(
          status: DoctorStatus.inConsultation,
          currentPatientName: old.patientName,
        );
        _doctorService.updateStatus(
          old.doctorId,
          DoctorStatus.inConsultation,
          currentPatientName: old.patientName,
        );
      }
    } else if (newStatus == AppointmentStatus.completed) {
      final docIndex = _doctors.indexWhere((d) => d.id == old.doctorId);
      if (docIndex != -1) {
        _doctors[docIndex] = _doctors[docIndex].copyWith(
          status: DoctorStatus.available,
          currentPatientName: null,
          completedTodayCount: _doctors[docIndex].completedTodayCount + 1,
        );
        _doctorService.updateStatus(
          old.doctorId,
          DoctorStatus.available,
          currentPatientName: null,
        );
      }
    }

    // Trigger notification for Check-In or Completion
    if (newStatus == AppointmentStatus.checkedIn || newStatus == AppointmentStatus.arrived) {
      final notif = NotificationItem(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Patient Checked In',
        message: '${old.patientName} has checked in for appointment with ${old.doctorName}.',
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.checkIn,
      );
      _notifications.insert(0, notif);
      _notificationService.insertNotification(notif);
    } else if (newStatus == AppointmentStatus.completed) {
      final notif = NotificationItem(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Consultation Completed',
        message: '${old.doctorName} completed consultation with ${old.patientName}.',
        timestamp: DateTime.now(),
        isRead: false,
        type: NotificationType.doctorAvailable,
      );
      _notifications.insert(0, notif);
      _notificationService.insertNotification(notif);
    }

    notifyListeners();
    return true;
  }

  // ADD APPOINTMENT
  Future<bool> addAppointment(Appointment appointment) async {
    final success = await _appointmentService.insertAppointment(appointment);
    if (!success) {
      debugPrint('[ClinicState] Failed to persist appointment to Supabase: ${appointment.id}');
      return false;
    }

    _appointments.insert(0, appointment);
    final notif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Appointment Booked',
      message: '${appointment.patientName} scheduled with ${appointment.doctorName} for ${appointment.timeString}.',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.appointment,
    );
    _notifications.insert(0, notif);
    notifyListeners();

    _notificationService.insertNotification(notif);
    return true;
  }

  // RESCHEDULE / CANCEL APPOINTMENT
  Future<bool> cancelAppointment(String appointmentId) async {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index == -1) return false;

    final success = await _appointmentService.cancelAppointment(appointmentId);
    if (!success) {
      debugPrint('[ClinicState] Failed to cancel appointment on Supabase for $appointmentId');
      return false;
    }

    final cancelledAppt = _appointments[index];
    _appointments[index] = cancelledAppt.copyWith(status: AppointmentStatus.cancelled);

    final notif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Appointment Cancelled',
      message: 'Appointment for ${cancelledAppt.patientName} with ${cancelledAppt.doctorName} was cancelled.',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.appointment,
    );
    _notifications.insert(0, notif);
    _notificationService.insertNotification(notif);

    notifyListeners();
    return true;
  }

  // ADD PATIENT
  Future<bool> addPatient(Patient patient) async {
    final success = await _patientService.insertPatient(patient);
    if (!success) {
      debugPrint('[ClinicState] Failed to insert patient to Supabase: ${patient.id}');
      return false;
    }

    _patients.insert(0, patient);
    notifyListeners();
    return true;
  }

  // UPDATE PATIENT
  Future<bool> updatePatient(Patient patient) async {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index == -1) return false;

    final success = await _patientService.updatePatient(patient);
    if (!success) {
      debugPrint('[ClinicState] Failed to update patient on Supabase: ${patient.id}');
      return false;
    }

    _patients[index] = patient;
    notifyListeners();
    return true;
  }

  // RECORD PAYMENT ON INVOICE
  Future<bool> recordPayment(
    String invoiceId,
    double amountPaid,
    String paymentMethod, {
    String? transactionRef,
    String? notes,
  }) async {
    final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (index == -1) return false;

    final old = _invoices[index];
    final newPaid = old.paidAmount + amountPaid;
    final newBalance = (old.totalAmount - newPaid).clamp(0.0, double.infinity);
    final newStatus = newBalance <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

    final staffProfile = AuthService.instance.currentProfile;
    final staffUserId = staffProfile?.id ?? AuthService.instance.currentUser?.id;
    final staffName = staffProfile?.fullName.isNotEmpty == true
        ? staffProfile!.fullName
        : 'Clinic Staff';

    final now = DateTime.now();
    final paymentRecord = PaymentRecord(
      id: 'PAY-${now.millisecondsSinceEpoch}',
      invoiceId: invoiceId,
      patientId: old.patientId,
      patientName: old.patientName,
      amount: amountPaid,
      paymentMethod: paymentMethod,
      transactionRef: transactionRef ?? old.transactionRef,
      receiptNumber: 'RCP-${now.millisecondsSinceEpoch.toString().substring(7)}',
      receivedByUserId: staffUserId,
      receivedByName: staffName,
      notes: notes ?? 'Counter payment recorded',
      paymentDate: now,
      createdAt: now,
    );

    // Persist to Supabase first
    final success = await _billingService.recordPayment(
      invoiceId: invoiceId,
      newPaidAmount: newPaid,
      newBalanceAmount: newBalance,
      newStatus: newStatus,
      paymentMethod: paymentMethod,
      paymentRecord: paymentRecord,
    );

    if (!success) {
      debugPrint('[ClinicState] Failed to record payment on Supabase for invoice $invoiceId');
      return false;
    }

    _invoices[index] = old.copyWith(
      paidAmount: newPaid,
      balanceAmount: newBalance,
      status: newStatus,
      paymentMethod: paymentMethod,
      transactionRef: transactionRef ?? old.transactionRef,
      receiptNumber: paymentRecord.receiptNumber,
      receivedBy: staffName,
      paymentDate: now,
      paymentStatusText: newStatus == PaymentStatus.paid ? 'Settled' : 'Partially Settled',
    );

    // Also update patient balance due
    final patientIndex = _patients.indexWhere((p) => p.id == old.patientId);
    if (patientIndex != -1) {
      final pOld = _patients[patientIndex];
      final updatedBal = (pOld.balanceDue - amountPaid).clamp(0.0, double.infinity);
      final updatedPatient = pOld.copyWith(balanceDue: updatedBal);
      _patients[patientIndex] = updatedPatient;
      _patientService.updatePatient(updatedPatient);
    }

    // Trigger payment notification
    final notif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Received',
      message: 'Received ₹${amountPaid.toStringAsFixed(0)} via $paymentMethod for ${old.patientName} (${old.invoiceNumber}).',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.paymentPending,
    );
    _notifications.insert(0, notif);
    _notificationService.insertNotification(notif);

    notifyListeners();
    return true;
  }

  // ADD INVOICE
  Future<bool> addInvoice(Invoice invoice) async {
    final success = await _billingService.insertInvoice(invoice);
    if (!success) {
      debugPrint('[ClinicState] Failed to insert invoice to Supabase: ${invoice.id}');
      return false;
    }

    // Avoid duplicate if already in memory
    final existingIdx = _invoices.indexWhere(
      (inv) => inv.id == invoice.id || inv.invoiceNumber == invoice.invoiceNumber,
    );
    if (existingIdx != -1) {
      _invoices[existingIdx] = invoice;
    } else {
      _invoices.insert(0, invoice);
    }

    // Update patient balance due with the new invoice balance
    final patientIndex = _patients.indexWhere((p) => p.id == invoice.patientId);
    if (patientIndex != -1) {
      final pOld = _patients[patientIndex];
      final updatedBal = pOld.balanceDue + invoice.balanceAmount;
      final updatedPatient = pOld.copyWith(balanceDue: updatedBal);
      _patients[patientIndex] = updatedPatient;
      _patientService.updatePatient(updatedPatient);
    }

    // Trigger new bill notification
    final notif = NotificationItem(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Bill Generated',
      message: 'Invoice ${invoice.invoiceNumber} for ${invoice.patientName} (₹${invoice.totalAmount.toStringAsFixed(0)}) created.',
      timestamp: DateTime.now(),
      isRead: false,
      type: NotificationType.paymentPending,
    );
    _notifications.insert(0, notif);
    _notificationService.insertNotification(notif);

    notifyListeners();
    return true;
  }

  /// Record an authentic call history entry
  void addCallRecord(CallRecord record) {
    _callRecords.insert(0, record);
    notifyListeners();
  }

  // Legacy communication log handler
  void logCall({
    required String patientId,
    required String patientName,
    required String phoneNumber,
    required CallDirection direction,
    required CallStatus status,
    required int durationSeconds,
    String? note,
  }) {
    final callId = 'CALL-${DateTime.now().millisecondsSinceEpoch}';
    _callRecords.insert(
      0,
      CallRecord(
        id: callId,
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        timestamp: DateTime.now(),
        durationSeconds: durationSeconds,
        direction: direction,
        status: status,
        note: note,
      ),
    );
    notifyListeners();

    // Persist to Supabase
    _reminderService.logCall(
      id: callId,
      patientId: patientId,
      patientName: patientName,
      phoneNumber: phoneNumber,
      direction: direction,
      status: status,
      durationSeconds: durationSeconds,
      note: note,
    );
  }

  void logMessage({
    required String patientId,
    required String patientName,
    required String phoneNumber,
    required MessageChannel channel,
    required String message,
    required String templateCategory,
  }) {
    final msgId = 'MSG-${DateTime.now().millisecondsSinceEpoch}';
    _messageRecords.insert(
      0,
      MessageRecord(
        id: msgId,
        patientId: patientId,
        patientName: patientName,
        phoneNumber: phoneNumber,
        channel: channel,
        message: message,
        templateCategory: templateCategory,
        timestamp: DateTime.now(),
        status: MessageDeliveryStatus.sent,
      ),
    );
    notifyListeners();

    // Persist to Supabase
    _reminderService.logMessage(
      id: msgId,
      patientId: patientId,
      patientName: patientName,
      phoneNumber: phoneNumber,
      channel: channel,
      message: message,
      templateCategory: templateCategory,
    );
  }

  // NOTIFICATIONS
  Future<bool> markNotificationAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return false;
    final previous = _notifications[index];
    if (previous.isRead) return true;

    // Optimistic local update
    _notifications[index] = previous.copyWith(isRead: true);
    notifyListeners();

    // Persist to Supabase with rollback if failed
    if (SupabaseService.instance.isInitialized) {
      final success = await _notificationService.markAsRead(id);
      if (!success) {
        final rbIndex = _notifications.indexWhere((n) => n.id == id);
        if (rbIndex != -1) {
          _notifications[rbIndex] = previous;
          notifyListeners();
        }
        return false;
      }
    }
    return true;
  }

  Future<bool> markAllNotificationsAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return true;

    final previous = List<NotificationItem>.from(_notifications);
    // Optimistic local update
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    // Persist to Supabase with rollback if failed
    if (SupabaseService.instance.isInitialized) {
      final success = await _notificationService.markAllAsRead();
      if (!success) {
        _notifications = previous;
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _notificationService.disposeRealtime();
    super.dispose();
  }
}
