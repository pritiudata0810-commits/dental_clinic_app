import 'package:flutter/material.dart';

/// SmileCare Design System Color Palette
/// Inspired by Reference Image 1 (Login) and Reference Image 2 (Dashboard).
/// Professional purple palette with soft lavender backgrounds, white surfaces,
/// dark readable text, and balanced healthcare accents.
class AppColors {
  // Primary Purple Brand Colors (Reference 1 & 2)
  static const Color primary = Color(0xFF5856D6); // Vibrant Elegant Purple #5856D6
  static const Color primaryDark = Color(0xFF3730A3); // Deep Indigo/Navy Purple #3730A3
  static const Color primaryDeep = Color(0xFF2E285F); // Rich Night Purple #2E285F
  static const Color primaryLight = Color(0xFFEEEDFC); // Soft Lavender Tint #EEEDFC
  static const Color primaryHover = Color(0xFF4C47C8); // Hover State #4C47C8
  static const Color primaryContainer = Color(0xFF4B45B2); // Card Purple in Reference 1

  // Soft Teal / Cyan Accents (Healthcare Clarity)
  static const Color accent = Color(0xFF10B981); // Emerald #10B981
  static const Color accentLight = Color(0xFFD1FAE5);
  static const Color accentMuted = Color(0xFF059669);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);

  // Neutral & Canvas Backgrounds (Reference 2 Soft Lavender Canvas)
  static const Color background = Color(0xFFF4F5FC); // Soft Lavender Canvas #F4F5FC
  static const Color surface = Color(0xFFFFFFFF); // White Surface #FFFFFF
  static const Color surfaceMuted = Color(0xFFF1F0FA); // Light Lavender-Gray
  static const Color surfaceHover = Color(0xFFF8F7FD);

  // Borders & Dividers
  static const Color border = Color(0xFFE4E4F2); // Subtle Lavender Border
  static const Color borderLight = Color(0xFFECECF8);
  static const Color borderDark = Color(0xFFCBD5E1);

  // Typography & Text
  static const Color textPrimary = Color(0xFF1E1B4B); // Very Dark Indigo #1E1B4B
  static const Color textSecondary = Color(0xFF64748B); // Slate Muted #64748B
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Status & Workflow Badges
  // Scheduled / Confirmed
  static const Color statusScheduledBg = Color(0xFFEEEDFC);
  static const Color statusScheduledText = Color(0xFF5856D6);

  // Arrived / Checked In / Waiting
  static const Color statusWaitingBg = Color(0xFFFEF3C7);
  static const Color statusWaitingText = Color(0xFFB45309);

  // In Consultation / With Doctor
  static const Color statusInConsultationBg = Color(0xFFEDE9FE);
  static const Color statusInConsultationText = Color(0xFF6D28D9);

  // Completed / Paid
  static const Color statusCompletedBg = Color(0xFFD1FAE5);
  static const Color statusCompletedText = Color(0xFF047857);

  // Cancelled / No Show / Overdue
  static const Color statusCancelledBg = Color(0xFFFFE4E6);
  static const Color statusCancelledText = Color(0xFFBE123C);

  // Partial / Pending
  static const Color statusPendingBg = Color(0xFFFFEDD5);
  static const Color statusPendingText = Color(0xFFC2410C);

  // Doctor Availability Indicators
  static const Color doctorAvailable = Color(0xFF10B981);
  static const Color doctorConsulting = Color(0xFF8B5CF6);
  static const Color doctorBusy = Color(0xFFF59E0B);
  static const Color doctorBreak = Color(0xFF64748B);
  static const Color doctorUnavailable = Color(0xFFEF4444);

  // Action Buttons
  static const Color callGreen = Color(0xFF10B981);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color smsBlue = Color(0xFF5856D6);
}
