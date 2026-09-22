import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Central access point for Supabase backend services.
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient? get client {
    if (!_isInitialized || !SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (e) {
      debugPrint('[SupabaseService] Client not ready: $e');
      return null;
    }
  }

  /// Initialize Supabase Flutter SDK
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[SupabaseService] No credentials configured. Running in local/offline fallback mode.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      instance._isInitialized = true;
      debugPrint('[SupabaseService] Initialized successfully with remote Supabase project.');
    } catch (e) {
      debugPrint('[SupabaseService] Failed to initialize Supabase: $e. Falling back to local state.');
      instance._isInitialized = false;
    }
  }
}
