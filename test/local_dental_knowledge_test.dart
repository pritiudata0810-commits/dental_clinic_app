import 'package:flutter_test/flutter_test.dart';
import 'package:dental_clinic_app/services/ai/local_dental_knowledge.dart';
import 'package:dental_clinic_app/services/ai/local_assistant_engine.dart';
import 'package:dental_clinic_app/state/clinic_state.dart';
import 'package:dental_clinic_app/models/patient.dart';

void main() {
  group('Phase 6: Local Dental Knowledge Base Unit & Integration Tests', () {
    late ClinicState clinicState;

    setUp(() {
      clinicState = ClinicState();
      final p1 = Patient(
        id: 'P-601',
        name: 'Rahul Sharma',
        phone: '9876543210',
        email: 'rahul@example.com',
        dateOfBirth: '15 Jan 1990',
        age: '34',
        gender: 'Male',
        address: 'Pune',
        emergencyContact: 'Anita Sharma 9876543211',
        assignedDoctorId: 'DOC-1',
        assignedDoctorName: 'Dr. Priya Sharma',
        lastVisit: '10 Sep 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 30)),
        balanceDue: 2500.0,
      );
      clinicState.setPatientsForTesting([p1]);
    });

    test('1. Plaque question returns educational information and care', () {
      final res = LocalDentalKnowledge.query("What is plaque?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('plaque'));
      expect(res.content, contains('Dental Plaque'));
      expect(res.content, contains('film of bacteria'));
      expect(res.content, contains('brushing and flossing'));
    });

    test('2. Tartar question explains dental calculus and professional scaling', () {
      final res = LocalDentalKnowledge.query("What is dental calculus?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('tartar'));
      expect(res.content, contains('Tartar (Dental Calculus)'));
      expect(res.content, contains('professional scaling'));
    });

    test('3. Gingivitis question explains early gum inflammation and reversibility', () {
      final res = LocalDentalKnowledge.query("Explain gingivitis.");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('gingivitis'));
      expect(res.content, contains('Gingivitis'));
      expect(res.content, contains('bleeding'));
      expect(res.content, contains('consult a dentist'));
    });

    test('4. Cavity question explains tooth decay, bacterial acids, and fillings', () {
      final res = LocalDentalKnowledge.query("How do cavities happen?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('cavities'));
      expect(res.content, contains('Cavities (Dental Caries / Tooth Decay)'));
      expect(res.content, contains('acids'));
      expect(res.content, contains('evaluated by a dentist'));
    });

    test('5. Tooth sensitivity question explains exposed dentin and desensitizing care', () {
      final res = LocalDentalKnowledge.query("Why are my teeth sensitive?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('sensitivity'));
      expect(res.content, contains('Tooth Sensitivity (Dentin Hypersensitivity)'));
      expect(res.content, contains('dentin'));
      expect(res.content, contains('desensitizing toothpaste'));
    });

    test('6. Gum disease question explains periodontitis and bone support', () {
      final res = LocalDentalKnowledge.query("What is periodontal disease?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('gum_disease'));
      expect(res.content, contains('Gum Disease (Periodontal Disease)'));
      expect(res.content, contains('alveolar bone'));
      expect(res.content, contains('in-person dental evaluation'));
    });

    test('7. Dental cleaning question explains professional prophylaxis', () {
      final res = LocalDentalKnowledge.query("What happens during teeth cleaning?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('cleaning'));
      expect(res.content, contains('Professional Dental Cleaning (Prophylaxis)'));
      expect(res.content, contains('ultrasonic'));
    });

    test('8. Root canal question explains pulp therapy and clinical preservation', () {
      final res = LocalDentalKnowledge.query("Why is root canal treatment done?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('root_canal'));
      expect(res.content, contains('Root Canal Treatment'));
      expect(res.content, contains('pulp tissue'));
      expect(res.content, contains('crown'));
    });

    test('9. Dental X-ray question explains radiographs and diagnostic safety', () {
      final res = LocalDentalKnowledge.query("Why do dentists take X-rays?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('xray'));
      expect(res.content, contains('Dental Radiographs (X-rays)'));
      expect(res.content, contains('radiation'));
    });

    test('10. Brushing question explains two-minute twice daily technique', () {
      final res = LocalDentalKnowledge.query("What is the proper way to brush?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('brushing'));
      expect(res.content, contains('Proper Tooth Brushing Technique'));
      expect(res.content, contains('twice daily'));
      expect(res.content, contains('45-degree angle'));
    });

    test('11. Flossing question explains interdental cleaning and contact areas', () {
      final res = LocalDentalKnowledge.query("Why should I floss?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('flossing'));
      expect(res.content, contains('Dental Flossing'));
      expect(res.content, contains('between teeth'));
    });

    test('12. Mouthwash question explains adjunct oral rinses', () {
      final res = LocalDentalKnowledge.query("Should I use mouthwash?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('mouthwash'));
      expect(res.content, contains('Mouthwash (Oral Rinse)'));
      expect(res.content, contains('adjunct'));
    });

    test('13. Oral hygiene question outlines daily routine and preventative care', () {
      final res = LocalDentalKnowledge.query("How do I keep my teeth healthy?");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('oral_hygiene'));
      expect(res.content, contains('Comprehensive Oral Hygiene'));
      expect(res.content, contains('every 6 months'));
    });

    test('14. Case normalization handles uppercase, extra spaces, and punctuation', () {
      final res = LocalDentalKnowledge.query("   WHAT IS GINGIVITIS???   ");
      expect(res.isSupported, isTrue);
      expect(res.topic, equals('gingivitis'));
    });

    test('15. Unsupported dental topic returns helpful guide without guessing', () {
      final res = LocalDentalKnowledge.query("What are dental implants?");
      expect(res.isSupported, isFalse);
      expect(res.content, contains("I don't have a verified local knowledge entry for that dental topic yet"));
      expect(res.content, contains('plaque'));
      expect(res.content, contains('root canals'));
    });

    test('16. Dental knowledge works without Supabase / during database errors', () async {
      clinicState.setRemoteErrorForTesting('Supabase connection offline (test error)');
      final res = await LocalAssistantEngine.processQuery("What is plaque?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains('Dental Plaque'));
      clinicState.clearRemoteError();
    });

    test('17. Patient diagnosis is NOT generated when user asks about a patient', () async {
      final res = await LocalAssistantEngine.processQuery("Does Rahul have gingivitis?", clinicState: clinicState);
      expect(res.success, isTrue);
      expect(res.intent, equals(AssistantIntent.dentalKnowledge));
      expect(res.text, contains('I cannot diagnose Rahul'));
      expect(res.text, contains('qualified dentist'));
      expect(res.data?['isPatientDiagnosisAttempt'], isTrue);
    });

    test('18. Existing Phase 1–5 clinic queries still work alongside knowledge base', () async {
      final resApt = await LocalAssistantEngine.processQuery("What appointments do we have today?", clinicState: clinicState);
      expect(resApt.intent, equals(AssistantIntent.todayAppointments));

      final resBal = await LocalAssistantEngine.processQuery("Rahul Sharma's balance", clinicState: clinicState);
      expect(resBal.intent, equals(AssistantIntent.patientBalance));

      final resDoc = await LocalAssistantEngine.processQuery("Who is available right now?", clinicState: clinicState);
      expect(resDoc.intent, equals(AssistantIntent.doctorAvailability));
    });

    test('19. Database error propagation remains intact for clinic queries', () async {
      clinicState.setRemoteErrorForTesting('Network timeout');
      final resClinic = await LocalAssistantEngine.processQuery("Rahul Sharma's balance", clinicState: clinicState);
      expect(resClinic.success, isFalse);
      expect(resClinic.errorMessage, equals('Network timeout'));
      expect(resClinic.text, contains('Database error: Network timeout'));
      clinicState.clearRemoteError();
    });

    test('20. Security: No secrets, passwords, tokens, or biometric fields in responses', () {
      for (final topic in LocalDentalKnowledge.supportedTopicKeys) {
        final res = LocalDentalKnowledge.query("Explain $topic");
        final lower = res.content.toLowerCase();
        expect(lower.contains('password'), isFalse);
        expect(lower.contains('secret'), isFalse);
        expect(lower.contains('token'), isFalse);
        expect(lower.contains('api_key'), isFalse);
        expect(lower.contains('biometric'), isFalse);
      }
    });

    test('21. Knowledge base is 100% deterministic and contains no mock clinic data', () {
      final res1 = LocalDentalKnowledge.query("What is plaque?");
      final res2 = LocalDentalKnowledge.query("What is plaque?");
      expect(res1.content, equals(res2.content));
      expect(res1.content.contains('MockClinicData'), isFalse);
    });
  });
}
