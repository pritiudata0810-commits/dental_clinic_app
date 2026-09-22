import 'package:flutter/foundation.dart';

/// Configuration provider for Supabase credentials.
///
/// Values can be provided at build/run time via:
/// `--dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...`
/// or set directly here.
class SupabaseConfig {
  // Compile-time environment variable overrides
  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Static properties
  static String get url => _envUrl;
  static String get anonKey => _envAnonKey;

  /// Returns true if valid Supabase credentials have been configured.
  static bool get isConfigured =>
      url.trim().isNotEmpty &&
      anonKey.trim().isNotEmpty &&
      url.startsWith('http');

  /// Safe logging for debugging without revealing full key
  static void logStatus() {
    if (isConfigured) {
      final maskedKey = anonKey.length > 10
          ? '${anonKey.substring(0, 6)}...${anonKey.substring(anonKey.length - 4)}'
          : '***';
      debugPrint('[SupabaseConfig] Configured with URL: $url and Key: $maskedKey');
    } else {
      debugPrint('[SupabaseConfig] Running in offline/fallback mock mode (Supabase credentials not set).');
    }
  }
}
