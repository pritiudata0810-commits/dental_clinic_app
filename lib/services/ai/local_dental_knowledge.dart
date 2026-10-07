import 'package:flutter/foundation.dart';

/// Structured result of a local dental knowledge lookup.
@immutable
class DentalKnowledgeResult {
  final String topic;
  final String title;
  final String content;
  final bool isSupported;
  final bool isPatientDiagnosisAttempt;
  final String? patientName;

  const DentalKnowledgeResult({
    required this.topic,
    required this.title,
    required this.content,
    this.isSupported = true,
    this.isPatientDiagnosisAttempt = false,
    this.patientName,
  });

  @override
  String toString() => 'DentalKnowledgeResult(topic: $topic, title: $title)';
}

/// Deterministic, purely local dental educational knowledge base.
/// Operates 100% offline with zero external network or LLM API calls.
/// Provides strictly educational dental guidance and enforces medical safety guards
/// (no patient diagnosis, no medication prescriptions, no symptom certainty claims).
class LocalDentalKnowledge {
  /// Known dental topics catalog.
  static const Map<String, Map<String, String>> _topics = {
    'plaque': {
      'title': 'Dental Plaque',
      'summary':
          'Dental plaque is a soft, sticky, colorless film of bacteria, food particles, and saliva that constantly forms on teeth.',
      'causes':
          'It forms when bacteria in the mouth interact with sugars and starches left behind from food and beverages.',
      'care':
          'If not removed daily by thorough brushing and flossing, plaque bacteria produce acids that can demineralize enamel and irritate gum tissue. Regular professional cleanings remove plaque in hard-to-reach areas.',
      'disclaimer':
          'For signs of persistent gum irritation or plaque buildup, consult a qualified dental professional.',
    },
    'tartar': {
      'title': 'Tartar (Dental Calculus)',
      'summary':
          'Tartar, also known as dental calculus, is hardened and calcified dental plaque that bonds firmly to tooth enamel and below the gumline.',
      'causes':
          'It develops when unremoved plaque absorbs minerals from saliva and hardens over time (often within 24 to 72 hours).',
      'care':
          'Unlike soft plaque, tartar cannot be safely removed with regular brushing or flossing at home; it requires professional scaling with ultrasonic or hand instruments by a dentist or dental hygienist.',
      'disclaimer':
          'Schedule regular dental scaling every 6 months to prevent tartar accumulation.',
    },
    'gingivitis': {
      'title': 'Gingivitis (Early Gum Inflammation)',
      'summary':
          'Gingivitis is an early, reversible stage of gum disease characterized by redness, swelling, and bleeding during brushing or flossing.',
      'causes':
          'It is most commonly caused by plaque accumulation along the gumline that triggers a local inflammatory response.',
      'care':
          'Gingivitis can usually be reversed with improved daily oral hygiene (brushing twice daily and flossing) combined with professional dental cleanings.',
      'disclaimer':
          'If gums bleed continuously or remain swollen, consult a dentist promptly to prevent progression to periodontitis.',
    },
    'gum_disease': {
      'title': 'Gum Disease (Periodontal Disease)',
      'summary':
          'Gum disease encompasses conditions ranging from mild gingivitis to severe periodontitis, which affects the bone and supportive ligaments anchoring the teeth.',
      'causes':
          'Toxins produced by chronic bacterial plaque buildup under the gumline trigger an immune response that gradually damages gum attachments and underlying alveolar bone.',
      'care':
          'Management includes deep cleanings (scaling and root planing), meticulous home care, and periodic periodontal maintenance visits.',
      'disclaimer':
          'Periodontal conditions require comprehensive in-person dental evaluation and personalized clinical management.',
    },
    'cavities': {
      'title': 'Cavities (Dental Caries / Tooth Decay)',
      'summary':
          'A cavity is localized permanent damage to the hard surface of a tooth (enamel and dentin) that develops into tiny openings or holes.',
      'causes':
          'Cavities develop when oral bacteria ferment dietary carbohydrates, producing acids that erode the tooth mineral matrix over time.',
      'care':
          'Early demineralization can sometimes be remineralized with fluoride. Developed cavities require restorative dental treatment, such as composite fillings or inlays.',
      'disclaimer':
          'Tooth pain, visible pits, or sensitivity should be evaluated by a dentist for accurate diagnosis and prompt restoration.',
    },
    'sensitivity': {
      'title': 'Tooth Sensitivity (Dentin Hypersensitivity)',
      'summary':
          'Tooth sensitivity is discomfort or sharp pain in one or more teeth triggered by hot, cold, sweet, or acidic foods and drinks, or cold air.',
      'causes':
          'It occurs when protective enamel thins or gums recede, exposing the underlying dentin and its microscopic tubules that lead to the tooth nerve.',
      'care':
          'Common conservative measures include using desensitizing toothpaste, soft-bristled toothbrushes, and avoiding aggressive horizontal brushing.',
      'disclaimer':
          'Persistent or severe sensitivity may indicate a cracked tooth, deep decay, or nerve involvement that requires dental assessment.',
    },
    'cleaning': {
      'title': 'Professional Dental Cleaning (Prophylaxis)',
      'summary':
          'A dental cleaning is a preventive clinical procedure performed by a dental professional to remove plaque, tartar, and surface stains from teeth.',
      'causes':
          'Routine cleanings prevent gum inflammation, combat bad breath, and halt the progression of tooth decay in areas unreachable by home brushing.',
      'care':
          'During the visit, the clinician uses specialized ultrasonic and manual scaling instruments, followed by polishing and oral health screening.',
      'disclaimer':
          'Most dental associations recommend a routine dental exam and cleaning every 6 months.',
    },
    'root_canal': {
      'title': 'Root Canal Treatment (Endodontic Therapy)',
      'summary':
          'A root canal is a dental procedure designed to relieve pain and save a severely infected or badly damaged tooth by removing inflamed or necrotic pulp tissue.',
      'causes':
          'It becomes necessary when deep decay, repeated dental procedures, or traumatic injury allows bacteria to reach the central pulp chamber and nerve canal.',
      'care':
          'The dentist cleans, disinfects, shapes, and seals the root canals with a biocompatible material, usually finishing with a protective crown.',
      'disclaimer':
          'Severe throbbing pain, prolonged sensitivity to heat, or swelling near a tooth requires immediate clinical dental examination.',
    },
    'xray': {
      'title': 'Dental Radiographs (X-rays)',
      'summary':
          'Dental X-rays are diagnostic imaging tools that capture internal views of teeth, tooth roots, jawbone structure, and facial bones.',
      'causes':
          'They allow dentists to detect hidden cavities between teeth, monitor bone levels, evaluate unerupted teeth, and identify periapical infections not visible to the naked eye.',
      'care':
          'Modern digital dental X-rays emit very low levels of radiation and are safeguarded with lead aprons and targeted digital sensors.',
      'disclaimer':
          'The frequency of dental X-rays is determined by your dentist based on your individual risk factors and clinical history.',
    },
    'brushing': {
      'title': 'Proper Tooth Brushing Technique',
      'summary':
          'Tooth brushing is the foundational daily habit for removing bacterial plaque and preventing tooth decay and gum disease.',
      'causes':
          'Food debris and bacterial biofilm accumulate constantly on all surfaces of the teeth throughout the day and night.',
      'care':
          'Brush twice daily for at least two minutes using a soft-bristled toothbrush and fluoride toothpaste. Hold the brush at a 45-degree angle to the gumline and use gentle circular strokes.',
      'disclaimer':
          'Avoid aggressive horizontal scrubbing, which can cause gum recession and enamel abrasion. Replace your toothbrush every 3 months.',
    },
    'flossing': {
      'title': 'Dental Flossing (Interdental Cleaning)',
      'summary':
          'Flossing is the practice of cleaning between the contact points of adjacent teeth and just beneath the gum margins where toothbrush bristles cannot reach.',
      'causes':
          'Up to 35-40% of tooth surfaces are interproximal (between teeth), making interdental cleaning essential to prevent interproximal cavities and interdental gingivitis.',
      'care':
          'Floss at least once daily. Gently slide the floss between teeth, curve it into a "C" shape against each tooth surface, and gently slide it up and down.',
      'disclaimer':
          'If gums bleed when you first start flossing, this often resolves within a week as gum health improves. If bleeding persists, see your dentist.',
    },
    'mouthwash': {
      'title': 'Mouthwash (Oral Rinse)',
      'summary':
          'Mouthwash is an adjunct liquid solution used to rinse the mouth to reduce oral bacteria, freshen breath, or deliver topical fluoride.',
      'causes':
          'It reaches areas throughout the oral cavity, cheeks, and tongue that physical brushing may miss, though it does not replace mechanical brushing and flossing.',
      'care':
          'Therapeutic mouthwashes can provide anti-plaque, anti-gingivitis, or remineralizing benefits. Swish the recommended amount for 30 to 60 seconds as directed.',
      'disclaimer':
          'Mouthwash is an adjunct to, not a replacement for, daily brushing and flossing. Consult your dentist regarding alcohol-free or specialized formulas.',
    },
    'oral_hygiene': {
      'title': 'Comprehensive Oral Hygiene',
      'summary':
          'Good oral hygiene is the practice of keeping the mouth clean and disease-free through daily preventive care and regular professional dental visits.',
      'causes':
          'Optimal oral care prevents dental caries, gingivitis, periodontal bone loss, bad breath (halitosis), and complications linked to systemic health.',
      'care':
          'A complete routine includes: brushing twice daily for two minutes, flossing daily, drinking plenty of water, limiting sugary snacks, and visiting the dentist every 6 months.',
      'disclaimer':
          'Personalized oral health advice should be tailored to your specific clinical needs by your dental provider.',
    },
  };

  /// Normalizes user queries for robust topic matching.
  static String normalizeTopicQuery(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll('’', "'").replaceAll('`', "'");
    s = s.replaceAll(RegExp(r'[?!.,;:"#%&*()\[\]{}_/\\-]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Identifies the matched topic key from natural phrasing, or null if unsupported.
  static String? detectTopic(String rawQuery) {
    final q = normalizeTopicQuery(rawQuery);
    if (q.isEmpty) return null;

    // Check Plaque
    if (q.contains('plaque') || q.contains('dental plaque') || q.contains('bacterial film')) {
      return 'plaque';
    }

    // Check Tartar / Calculus
    if (q.contains('tartar') || q.contains('calculus') || q.contains('hardened plaque')) {
      return 'tartar';
    }

    // Check Gingivitis
    if (q.contains('gingivitis') || q.contains('gum inflammation') || q.contains('bleeding gums')) {
      return 'gingivitis';
    }

    // Check Gum disease / Periodontitis
    if (q.contains('gum disease') ||
        q.contains('periodontal') ||
        q.contains('periodontitis') ||
        q.contains('pyorrhea')) {
      return 'gum_disease';
    }

    // Check Cavities / Tooth decay
    if (q.contains('cavity') ||
        q.contains('cavities') ||
        q.contains('tooth decay') ||
        q.contains('dental caries') ||
        q.contains('caries') ||
        q.contains('rotten tooth')) {
      return 'cavities';
    }

    // Check Tooth sensitivity
    if (q.contains('sensitiv') ||
        q.contains('sensitive teeth') ||
        q.contains('sensitive tooth') ||
        q.contains('teeth sensitivity') ||
        q.contains('tooth sensitivity')) {
      return 'sensitivity';
    }

    // Check Dental cleaning / Prophylaxis
    if (q.contains('dental cleaning') ||
        q.contains('teeth cleaning') ||
        q.contains('tooth cleaning') ||
        q.contains('prophylaxis') ||
        q.contains('scaling') ||
        (q.contains('cleaning') && (q.contains('teeth') || q.contains('dental') || q.contains('hygienist')))) {
      return 'cleaning';
    }

    // Check Root canal
    if (q.contains('root canal') ||
        q.contains('endodontic') ||
        q.contains('rct') ||
        q.contains('infected pulp') ||
        q.contains('pulp infection')) {
      return 'root_canal';
    }

    // Check Dental X-ray
    if (q.contains('xray') ||
        q.contains('x ray') ||
        q.contains('radiograph') ||
        q.contains('dental imaging')) {
      return 'xray';
    }

    // Check Brushing
    if (q.contains('brushing') ||
        q.contains('how often brush') ||
        q.contains('how long brush') ||
        q.contains('proper way to brush') ||
        q.contains('how to brush') ||
        q.contains('brush teeth') ||
        q.contains('toothbrush') ||
        q.contains('brush my teeth') ||
        q.contains('brush')) {
      return 'brushing';
    }

    // Check Flossing
    if (q.contains('floss') ||
        q.contains('flossing') ||
        q.contains('interdental cleaning')) {
      return 'flossing';
    }

    // Check Mouthwash
    if (q.contains('mouthwash') ||
        q.contains('oral rinse') ||
        q.contains('mouth rinse') ||
        q.contains('mouth rinse')) {
      return 'mouthwash';
    }

    // Check Oral hygiene / general healthy teeth
    if (q.contains('oral hygiene') ||
        q.contains('healthy teeth') ||
        q.contains('keep my teeth healthy') ||
        q.contains('dental health') ||
        q.contains('oral health') ||
        q.contains('maintain hygiene') ||
        q.contains('hygiene tips')) {
      return 'oral_hygiene';
    }

    return null;
  }

  /// Detects whether the query is attempting to solicit a medical diagnosis for a specific patient.
  /// Example: "Does Rahul have gingivitis?", "Does Aarav have a cavity?", "Does the patient have tartar?"
  static bool isDiagnosisAttempt(String rawQuery) {
    final lower = rawQuery.toLowerCase();
    final hasInquiry = lower.contains('does ') ||
        lower.contains('has ') ||
        lower.contains('is ') ||
        lower.contains('could ') ||
        lower.contains('diagnose');

    // Cues for personal diagnosis inquiry
    final hasCondition = lower.contains('gingivitis') ||
        lower.contains('cavity') ||
        lower.contains('cavities') ||
        lower.contains('plaque') ||
        lower.contains('tartar') ||
        lower.contains('decay') ||
        lower.contains('gum disease') ||
        lower.contains('periodontitis') ||
        lower.contains('sensitivity') ||
        lower.contains('root canal');

    final hasPatientCue = RegExp(r'\b(?:p|pt)-\d+\b', caseSensitive: false).hasMatch(rawQuery) ||
        lower.contains('patient') ||
        lower.contains('rahul') ||
        lower.contains('aarav') ||
        lower.contains('pooja') ||
        lower.contains('neha') ||
        lower.contains('priya') ||
        lower.contains('amit');

    return hasCondition && hasInquiry && hasPatientCue;
  }

  /// Extracts patient name from a diagnosis query if present.
  static String? extractPatientNameFromDiagnosis(String rawQuery) {
    final match = RegExp(r'\b(?:does|has)\s+([A-Za-z0-9\-_]+(?:\s+[A-Za-z0-9\-_]+)?)\s+(?:have|suffer|need|got)', caseSensitive: false).firstMatch(rawQuery);
    if (match != null) {
      final name = match.group(1)!.trim();
      if (!['the', 'a', 'anyone', 'someone'].contains(name.toLowerCase())) {
        return name;
      }
    }
    return null;
  }

  /// Main lookup method. Returns educational, safe response based strictly on local knowledge.
  static DentalKnowledgeResult query(String rawQuery) {
    // 1. Guard against patient-specific medical diagnosis attempts
    if (isDiagnosisAttempt(rawQuery)) {
      final patient = extractPatientNameFromDiagnosis(rawQuery) ?? 'the patient';
      final topicKey = detectTopic(rawQuery);
      final topicTitle = topicKey != null && _topics.containsKey(topicKey)
          ? _topics[topicKey]!['title']!
          : 'this condition';

      final message = 'I can provide general educational information about $topicTitle, but I cannot diagnose $patient. '
          'Clinical diagnosis requires an in-person physical examination, dental instruments, and professional diagnostic evaluation by a qualified dentist.';

      return DentalKnowledgeResult(
        topic: topicKey ?? 'diagnosis_guard',
        title: 'Clinical Diagnosis Guard',
        content: message,
        isSupported: true,
        isPatientDiagnosisAttempt: true,
        patientName: patient,
      );
    }

    // 2. Detect local topic
    final topicKey = detectTopic(rawQuery);
    if (topicKey == null || !_topics.containsKey(topicKey)) {
      const unsupportedMessage =
          "I don't have a verified local knowledge entry for that dental topic yet. "
          "I can currently explain topics such as plaque, tartar, gingivitis, cavities, tooth sensitivity, "
          "gum disease, root canals, dental cleaning, dental X-rays, brushing, flossing, mouthwash, and oral hygiene.";

      return const DentalKnowledgeResult(
        topic: 'unknown',
        title: 'Topic Not Found',
        content: unsupportedMessage,
        isSupported: false,
      );
    }

    final entry = _topics[topicKey]!;
    final buffer = StringBuffer();
    buffer.writeln('${entry['title']}:');
    buffer.writeln('• ${entry['summary']}');
    buffer.writeln('• Cause & Context: ${entry['causes']}');
    buffer.writeln('• Care & Management: ${entry['care']}');
    buffer.write('• Note: ${entry['disclaimer']}');

    return DentalKnowledgeResult(
      topic: topicKey,
      title: entry['title']!,
      content: buffer.toString().trim(),
      isSupported: true,
    );
  }

  /// List of all supported topic keys.
  static List<String> get supportedTopicKeys => List.unmodifiable(_topics.keys);
}
