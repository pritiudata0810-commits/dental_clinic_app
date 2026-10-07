import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'supabase_service.dart';

/// Thrown when user credentials match but no profile row exists in the database
class ProfileNotFoundException implements Exception {
  final String message;
  const ProfileNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Thrown when backend authentication or network is unavailable
class AuthServerException implements Exception {
  final String message;
  const AuthServerException(this.message);

  @override
  String toString() => message;
}

/// Thrown when an authenticated user attempts an operation not permitted by their role
class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);

  @override
  String toString() => message;
}

/// Production-Grade Authentication Service powered by Supabase Auth and Database Profiles.
///
/// Identity is strictly rooted in `Supabase.client.auth.currentUser.id` (auth.uid()).
/// Role authorization is strictly retrieved from the database `public.profiles` table.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final SupabaseService _supabase = SupabaseService.instance;
  UserProfile? _currentProfile;

  /// Current authenticated Supabase Auth user
  User? get currentUser => _supabase.client?.auth.currentUser;

  /// Cached strongly-typed profile of the active user
  UserProfile? get currentProfile => _currentProfile;

  /// True if a user is authenticated with a valid loaded profile
  bool get isAuthenticated => currentUser != null && _currentProfile != null;

  /// Stream of Supabase Auth state changes
  Stream<AuthState>? get onAuthStateChange =>
      _supabase.client?.auth.onAuthStateChange;

  /// Sign in with email and password, load database profile, and enforce roles.
  ///
  /// Rejects mock/string-based role deduction completely.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final client = _supabase.client;
    if (client == null) {
      throw const AuthServerException(
        'Unable to connect to the clinic server. Please check your network connection.',
      );
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthServerException('Please enter both email and password.');
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthServerException('Invalid email or password.');
      }

      // Fetch official database profile
      final profile = await fetchProfile(user.id);
      if (profile == null) {
        // Authenticated at Supabase Auth, but no record in public.profiles
        debugPrint(
          '[AuthService] Auth user ${user.id} logged in, but no profile found in public.profiles',
        );
        throw const ProfileNotFoundException(
          'Your account is authenticated, but no clinic profile is configured. Please contact the clinic administrator.',
        );
      }

      _currentProfile = profile;
      notifyListeners();
      return profile;
    } on AuthException catch (e) {
      debugPrint('[AuthService] Supabase AuthException: ${e.message} (code: ${e.statusCode})');
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw const AuthServerException(
          'Your email has not been confirmed yet. Please verify your email or contact the clinic administrator.',
        );
      } else if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AuthServerException('Invalid email or password.');
      }
      throw AuthServerException(e.message);
    } catch (e) {
      if (e is ProfileNotFoundException || e is AuthServerException) {
        rethrow;
      }
      debugPrint('[AuthService] Unexpected error: $e');
      throw AuthServerException(
        'Unable to connect to the clinic server. Please try again.',
      );
    }
  }

  /// Retrieve the profile for a given user ID directly from `public.profiles`.
  Future<UserProfile?> fetchProfile(String userId) async {
    final client = _supabase.client;
    if (client == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      debugPrint('[AuthService] Error fetching profile: $e');
      return null;
    }
  }

  /// Check active session on app startup and restore current profile if valid.
  Future<UserProfile?> restoreSession() async {
    final client = _supabase.client;
    if (client == null) return null;

    final session = client.auth.currentSession;
    if (session == null || session.isExpired) {
      _currentProfile = null;
      return null;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      _currentProfile = null;
      return null;
    }

    final profile = await fetchProfile(user.id);
    _currentProfile = profile;
    notifyListeners();
    return profile;
  }

  /// Safely sign out the current session and clear cached profile.
  Future<void> signOut() async {
    final client = _supabase.client;
    _currentProfile = null;
    notifyListeners();

    if (client != null) {
      try {
        await client.auth.signOut();
        debugPrint('[AuthService] User signed out successfully.');
      } catch (e) {
        debugPrint('[AuthService] Sign out error: $e');
      }
    }
  }
}
