import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../models/billing.dart';
import '../models/communication.dart';
import '../models/notification_item.dart';
import '../models/call_reminder.dart';
import '../mock_data/mock_clinic_data.dart';
import '../services/patient_service.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';
import '../services/billing_service.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicState extends ChangeNotifier {
  final PatientService _patientService = PatientService();
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final BillingService _billingService = BillingService();
  final ReminderService _reminderService = ReminderService();
  final NotificationService _notificationService = NotificationService();

  List<Doctor> _doctors = [];
  List<Patient> _patients = [];
  List<Appointment> _appointments = [];
  List<Invoice> _invoices = [];
  List<CallRecord> _callRecords = [];
  List<MessageRecord> _messageRecords = [];
  List<NotificationItem> _notifications = [];
  List<CallReminder> _callReminders = [];

  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedDoctorFilter;

  // Active navigation index for receptionist sidebar
  int _currentNavIndex = 0;

  // Constructor & Init
  ClinicState() {
    _loadInitialData();
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
        }
      });
    }
  }

  /// Manually trigger a fresh pull of all records from Supabase
  Future<void> refreshRemoteData() async {
    await _fetchRemoteData();
  }

  void _loadInitialData() {
    // 1. Load mock data first for zero-latency initial UI render & offline fallback
    _doctors = MockClinicData.getDoctors();
    _patients = MockClinicData.getPatients();
    _appointments = MockClinicData.getAppointments();
    _invoices = MockClinicData.getInvoices();
    _callRecords = MockClinicData.getCallRecords();
    _messageRecords = MockClinicData.getMessageRecords();
    _notifications = MockClinicData.getNotifications();
    _callReminders = MockClinicData.getCallReminders();

    // 2. Fetch persistent Supabase data if connected
    _fetchRemoteData();
  }

  Future<void> _fetchRemoteData() async {
    try {
      final remoteDoctors = await _doctorService.fetchDoctors();
      if (remoteDoctors != null && remoteDoctors.isNotEmpty) {
        _doctors = remoteDoctors;
      }

      final remotePatients = await _patientService.fetchPatients();
      if (remotePatients != null && remotePatients.isNotEmpty) {
        _patients = remotePatients;
      }

      final remoteAppointments = await _appointmentService.fetchAppointments();
      if (remoteAppointments != null && remoteAppointments.isNotEmpty) {
        _appointments = remoteAppointments;
      }

      final remoteInvoices = await _billingService.fetchInvoices();
      if (remoteInvoices != null && remoteInvoices.isNotEmpty) {
        _invoices = remoteInvoices;
      }

      final remoteReminders = await _reminderService.fetchReminders();
      if (remoteReminders != null && remoteReminders.isNotEmpty) {
        _callReminders = remoteReminders;
      }

      final remoteNotifications = await _notificationService.fetchNotifications();
      if (remoteNotifications != null && remoteNotifications.isNotEmpty) {
        _notifications = remoteNotifications;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[ClinicState] Background Supabase fetch error: $e');
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
  void updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      final old = _appointments[index];
      Appointment updated = old.copyWith(
        status: newStatus,
        checkInTime: (newStatus == AppointmentStatus.checkedIn ||
                newStatus == AppointmentStatus.arrived) &&
            old.checkInTime == null
            ? DateTime.now()
            : old.checkInTime,
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

      notifyListeners();

      // Persist to Supabase
      _appointmentService.updateStatus(
        appointmentId,
        newStatus,
        checkInTime: updated.checkInTime,
      );
    }
  }

  // ADD APPOINTMENT
  void addAppointment(Appointment appointment) {
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

    // Persist to Supabase
    _appointmentService.insertAppointment(appointment);
    _notificationService.insertNotification(notif);
  }

  // RESCHEDULE / CANCEL APPOINTMENT
  void cancelAppointment(String appointmentId) {
    final index = _appointments.indexWhere((a) => a.id == appointmentId);
    if (index != -1) {
      _appointments[index] = _appointments[index].copyWith(status: AppointmentStatus.cancelled);
      notifyListeners();

      // Persist to Supabase
      _appointmentService.cancelAppointment(appointmentId);
    }
  }

  // ADD PATIENT
  void addPatient(Patient patient) {
    _patients.insert(0, patient);
    notifyListeners();

    // Persist to Supabase
    _patientService.insertPatient(patient);
  }

  // UPDATE PATIENT
  void updatePatient(Patient patient) {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      _patients[index] = patient;
      notifyListeners();

      // Persist to Supabase
      _patientService.updatePatient(patient);
    }
  }

  // RECORD PAYMENT ON INVOICE
  void recordPayment(String invoiceId, double amountPaid, String paymentMethod) {
    final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
    if (index != -1) {
      final old = _invoices[index];
      final newPaid = old.paidAmount + amountPaid;
      final newBalance = (old.totalAmount - newPaid).clamp(0.0, double.infinity);
      final newStatus = newBalance <= 0 ? PaymentStatus.paid : PaymentStatus.partial;

      _invoices[index] = old.copyWith(
        paidAmount: newPaid,
        balanceAmount: newBalance,
        status: newStatus,
        paymentMethod: paymentMethod,
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

      notifyListeners();

      // Persist to Supabase
      _billingService.recordPayment(
        invoiceId: invoiceId,
        newPaidAmount: newPaid,
        newBalanceAmount: newBalance,
        newStatus: newStatus,
        paymentMethod: paymentMethod,
      );
    }
  }

  // ADD INVOICE
  void addInvoice(Invoice invoice) {
    _invoices.insert(0, invoice);
    notifyListeners();

    // Persist to Supabase
    _billingService.insertInvoice(invoice);
  }

  // RECORD COMMUNICATION LOGS (SIMULATED)
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
  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      // Persist to Supabase
      _notificationService.markAsRead(id);
    }
  }

  void markAllNotificationsAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    // Persist to Supabase
    _notificationService.markAllAsRead();
  }
}
