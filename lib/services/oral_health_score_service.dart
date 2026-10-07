import 'package:flutter/material.dart';
import '../models/patient.dart';
import '../models/appointment.dart';
import '../models/tooth_record.dart';

class OralHealthFactor {
  final String title;
  final int score;
  final int maxScore;
  final String observation;
  final bool isPositive;

  const OralHealthFactor({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.observation,
    required this.isPositive,
  });

  double get ratio => maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
}

class OralHealthScoreResult {
  final int totalScore;
  final String category;
  final Color categoryColor;
  final Color categoryBgColor;
  final String summary;
  final List<OralHealthFactor> factors;
  final List<String> clinicalObservations;
  final List<String> recommendations;
  final DateTime calculatedAt;

  const OralHealthScoreResult({
    required this.totalScore,
    required this.category,
    required this.categoryColor,
    required this.categoryBgColor,
    required this.summary,
    required this.factors,
    required this.clinicalObservations,
    required this.recommendations,
    required this.calculatedAt,
  });
}

class OralHealthScoreService {
  /// Deterministically calculate the 0-100 Oral-Health Score based on 6 clinical factors
  static OralHealthScoreResult calculate({
    required Patient patient,
    required List<Appointment> appointments,
    required List<ToothRecord> toothRecords,
  }) {
    final now = DateTime.now();

    // -------------------------------------------------------------
    // FACTOR 1: Preventive Care & Hygiene (Max 20 pts)
    // -------------------------------------------------------------
    int preventiveScore = 20;
    String preventiveObs;
    final preventiveKeywords = ['scaling', 'cleaning', 'prophylaxis', 'polishing', 'fluoride'];
    final hasPreventiveCare = toothRecords.any((t) =>
            preventiveKeywords.any((k) => t.procedure.toLowerCase().contains(k))) ||
        appointments.any((a) =>
            preventiveKeywords.any((k) => a.appointmentType.toLowerCase().contains(k)));

    if (hasPreventiveCare) {
      preventiveScore = 20;
      preventiveObs = 'Documented regular dental prophylaxis / hygiene treatments.';
    } else if (patient.totalVisits >= 2) {
      preventiveScore = 14;
      preventiveObs = 'Routine checkups logged; periodic scaling recommended.';
    } else {
      preventiveScore = 8;
      preventiveObs = 'Baseline hygiene record; preventive recall advised.';
    }

    // -------------------------------------------------------------
    // FACTOR 2: Follow-up Adherence (Max 20 pts)
    // -------------------------------------------------------------
    int followUpScore = 20;
    String followUpObs;
    final pendingFollowUps = toothRecords.where((t) =>
        t.status == ToothStatus.requiresFollowUp ||
        t.completionStatus == ToothTreatmentCompletionStatus.requiresFollowUp).length;

    if (pendingFollowUps == 0) {
      followUpScore = 20;
      followUpObs = 'All scheduled follow-up milestones actively up to date.';
    } else if (pendingFollowUps == 1) {
      followUpScore = 12;
      followUpObs = '1 tooth procedure requires pending clinical follow-up evaluation.';
    } else {
      followUpScore = 6;
      followUpObs = '$pendingFollowUps tooth procedures have overdue follow-up milestones.';
    }

    // -------------------------------------------------------------
    // FACTOR 3: Treatment Completion (Max 20 pts)
    // -------------------------------------------------------------
    int treatmentScore = 20;
    String treatmentObs;
    if (toothRecords.isEmpty) {
      treatmentScore = 18;
      treatmentObs = 'No invasive restorative treatments required.';
    } else {
      final completed = toothRecords.where((t) =>
          t.completionStatus == ToothTreatmentCompletionStatus.completed).length;
      final inProgress = toothRecords.where((t) =>
          t.completionStatus == ToothTreatmentCompletionStatus.inProgress ||
          t.completionStatus == ToothTreatmentCompletionStatus.planned).length;

      final ratio = completed / (completed + inProgress > 0 ? completed + inProgress : 1);
      if (ratio >= 0.85) {
        treatmentScore = 20;
        treatmentObs = 'High treatment completion rate ($completed completed procedures).';
      } else if (ratio >= 0.5) {
        treatmentScore = 14;
        treatmentObs = 'Course of treatment in progress ($inProgress procedures underway).';
      } else {
        treatmentScore = 8;
        treatmentObs = 'Multiple procedures planned/in-progress awaiting completion.';
      }
    }

    // -------------------------------------------------------------
    // FACTOR 4: Appointment Adherence & Reliability (Max 15 pts)
    // -------------------------------------------------------------
    int apptScore = 15;
    String apptObs;
    final patientAppts = appointments.where((a) => a.patientId == patient.id).toList();
    if (patientAppts.isEmpty) {
      apptScore = 12;
      apptObs = 'Initial visit registered; regular appointment scheduling encouraged.';
    } else {
      final noShows = patientAppts.where((a) =>
          a.status == AppointmentStatus.noShow ||
          a.status == AppointmentStatus.cancelled).length;

      if (noShows == 0) {
        apptScore = 15;
        apptObs = 'Excellent visit adherence (100% attendance rate).';
      } else if (noShows == 1) {
        apptScore = 10;
        apptObs = '1 cancellation/no-show on record; generally reliable.';
      } else {
        apptScore = 5;
        apptObs = '$noShows missed or cancelled appointments logged.';
      }
    }

    // -------------------------------------------------------------
    // FACTOR 5: Active Pathological Burden / Caries (Max 15 pts)
    // -------------------------------------------------------------
    int cariesScore = 15;
    String cariesObs;
    final activeCaries = toothRecords.where((t) =>
        t.status == ToothStatus.caries || t.status == ToothStatus.fracture).length;
    final underTx = toothRecords.where((t) =>
        t.status == ToothStatus.underTreatment).length;

    if (activeCaries == 0 && underTx == 0) {
      cariesScore = 15;
      cariesObs = 'Zero active untreated cavitations or traumatic fractures.';
    } else if (activeCaries == 1) {
      cariesScore = 8;
      cariesObs = '1 active untreated carious lesion detected requiring restoration.';
    } else {
      cariesScore = (15 - (activeCaries * 5) - (underTx * 2)).clamp(2, 15);
      cariesObs = '$activeCaries active carious lesion(s) require restorative attention.';
    }

    // -------------------------------------------------------------
    // FACTOR 6: Visit Recency & Maintenance (Max 10 pts)
    // -------------------------------------------------------------
    int recencyScore = 10;
    String recencyObs;
    final daysSinceRegistration = now.difference(patient.registrationDate).inDays;
    // In our mock data lastVisit can be parsed or based on visits
    if (patient.totalVisits >= 3 || daysSinceRegistration < 60) {
      recencyScore = 10;
      recencyObs = 'Recent clinical interaction within recommended recall interval.';
    } else if (patient.totalVisits >= 1) {
      recencyScore = 7;
      recencyObs = 'Visits are sporadic; regular 6-month checkups advised.';
    } else {
      recencyScore = 4;
      recencyObs = 'Overdue for comprehensive routine dental examination.';
    }

    // Calculate Total Score
    final rawTotal = preventiveScore + followUpScore + treatmentScore + apptScore + cariesScore + recencyScore;
    final totalScore = rawTotal.clamp(0, 100);

    // Determine category
    final String category;
    final Color categoryColor;
    final Color categoryBgColor;
    final String summary;

    if (totalScore >= 85) {
      category = 'Excellent';
      categoryColor = const Color(0xFF16A34A);
      categoryBgColor = const Color(0xFFDCFCE7);
      summary = 'Oral health status is well maintained with strong preventive adherence.';
    } else if (totalScore >= 70) {
      category = 'Good';
      categoryColor = const Color(0xFF2563EB);
      categoryBgColor = const Color(0xFFDBEAFE);
      summary = 'Generally healthy dentition; completing planned treatments will boost score.';
    } else if (totalScore >= 50) {
      category = 'Moderate';
      categoryColor = const Color(0xFFD97706);
      categoryBgColor = const Color(0xFFFEF3C7);
      summary = 'Moderate risk indicators present; attention needed for pending procedures.';
    } else {
      category = 'Needs Attention';
      categoryColor = const Color(0xFFDC2626);
      categoryBgColor = const Color(0xFFFEE2E2);
      summary = 'Multiple active dental findings requiring prompt clinical intervention.';
    }

    final factors = [
      OralHealthFactor(
        title: 'Preventive Care',
        score: preventiveScore,
        maxScore: 20,
        observation: preventiveObs,
        isPositive: preventiveScore >= 15,
      ),
      OralHealthFactor(
        title: 'Follow-up Adherence',
        score: followUpScore,
        maxScore: 20,
        observation: followUpObs,
        isPositive: followUpScore >= 15,
      ),
      OralHealthFactor(
        title: 'Treatment Completion',
        score: treatmentScore,
        maxScore: 20,
        observation: treatmentObs,
        isPositive: treatmentScore >= 15,
      ),
      OralHealthFactor(
        title: 'Appointment Adherence',
        score: apptScore,
        maxScore: 15,
        observation: apptObs,
        isPositive: apptScore >= 12,
      ),
      OralHealthFactor(
        title: 'Caries & Active Pathologies',
        score: cariesScore,
        maxScore: 15,
        observation: cariesObs,
        isPositive: cariesScore >= 12,
      ),
      OralHealthFactor(
        title: 'Visit Recency',
        score: recencyScore,
        maxScore: 10,
        observation: recencyObs,
        isPositive: recencyScore >= 8,
      ),
    ];

    // Observations
    final observations = <String>[];
    if (activeCaries > 0) {
      observations.add('Unresolved active carious lesion(s) on file requiring restorative therapy.');
    }
    if (pendingFollowUps > 0) {
      observations.add('$pendingFollowUps procedure(s) flagged for postoperative clinical evaluation.');
    }
    if (toothRecords.any((t) => t.status == ToothStatus.rootCanal)) {
      observations.add('Endodontically treated teeth present — monitor coronal seal and periodic radiographs.');
    }
    if (toothRecords.any((t) => t.status == ToothStatus.implant)) {
      observations.add('Dental implant site logged — evaluate peri-implant tissue health during hygiene visits.');
    }
    if (observations.isEmpty) {
      observations.add('No acute periodontal or endodontic concerns identified.');
      observations.add('Coronal integrity and restorative restorations appear intact.');
    }

    // Recommendations
    final recommendations = <String>[];
    if (activeCaries > 0) {
      recommendations.add('Schedule direct resin composite or in-depth evaluation for carious lesions.');
    }
    if (pendingFollowUps > 0) {
      recommendations.add('Book review visit for in-progress or pending follow-up procedures.');
    }
    if (!hasPreventiveCare) {
      recommendations.add('Schedule routine 6-month ultrasonic scaling and prophylaxis.');
    }
    recommendations.add('Advise twice-daily fluoridated brushing and interdental flossing.');

    return OralHealthScoreResult(
      totalScore: totalScore,
      category: category,
      categoryColor: categoryColor,
      categoryBgColor: categoryBgColor,
      summary: summary,
      factors: factors,
      clinicalObservations: observations,
      recommendations: recommendations,
      calculatedAt: now,
    );
  }
}
