import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseService _supabase = SupabaseService.instance;

  User? get currentUser => _supabase.client?.auth.currentUser;

  /// Authenticate with email & password and retrieve user role
  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase.client;

    // Remote Supabase Auth
    if (client != null) {
      try {
        final res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (res.user != null) {
          // Fetch role from profiles table
          final profile = await client
              .from('profiles')
              .select('role')
              .eq('id', res.user!.id)
              .maybeSingle();

          if (profile != null && profile['role'] != null) {
            return profile['role'].toString();
          }

          // Fallback to user metadata
          final metaRole = res.user!.userMetadata?['role'];
          if (metaRole != null) {
            return metaRole.toString();
          }
        }
      } catch (e) {
        debugPrint('[AuthService] Supabase auth error: $e');
        rethrow;
      }
    }

    // Fallback: credential-based routing
    final clean = email.trim().toLowerCase();
    if (clean.contains('doctor') || clean.contains('sharma') || clean.contains('dr.')) {
      return 'doctor';
    } else {
      return 'receptionist';
    }
  }

  /// Sign out current session
  Future<void> signOut() async {
    final client = _supabase.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (e) {
        debugPrint('[AuthService] Sign out error: $e');
      }
    }
  }
}
