import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/tooth_logo.dart';
import '../../widgets/common/app_button.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/doctor/main_shell.dart';
import '../../widgets/layout/app_shell.dart';

/// Central Authentication Gate that evaluates session state on startup
/// and routes to the appropriate dashboard or login screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService.instance;
  bool _isChecking = true;
  UserProfile? _profile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final profile = await _authService.restoreSession();
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isChecking = false;
      });
    } on ProfileNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Network or initialization issue: proceed to login view
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: const Color(0xFF5350C4),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ToothLogo(size: 72),
              const SizedBox(height: 20),
              const Text(
                'SmileCare OS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Checking secure clinic session...',
                style: TextStyle(fontSize: 13, color: Color(0xFFD6D5F7)),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Profile missing error state
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Profile Configuration Required',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await _authService.signOut();
                            setState(() {
                              _errorMessage = null;
                              _profile = null;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _checkInitialSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Authenticated user routing
    if (_profile != null) {
      if (_profile!.isDoctor) {
        return const MainShell();
      } else {
        return const AppShell();
      }
    }

    // Default: Show login screen
    return const LoginScreen();
  }
}

/// Route guard that verifies the authenticated user has one of the allowed roles.
class RoleGuardedRoute extends StatelessWidget {
  final List<UserRole> allowedRoles;
  final Widget child;

  const RoleGuardedRoute({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final profile = auth.currentProfile;

    // 1. Not authenticated -> Redirect to login
    if (!auth.isAuthenticated || profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Authenticated but unauthorized role -> Show access denied banner
    if (!allowedRoles.contains(profile.role)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B)),
            onPressed: () {
              // Return to the user's primary dashboard
              if (profile.isDoctor) {
                Navigator.of(context).pushReplacementNamed('/doctor');
              } else {
                Navigator.of(context).pushReplacementNamed('/receptionist');
              }
            },
          ),
          title: const Text('Access Restricted', style: AppTextStyles.h4),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Unauthorized Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You don't have permission to access this section.\nYour current role is: ${profile.role.displayName}.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Return to Authorized Dashboard',
                    icon: Icons.dashboard_rounded,
                    onPressed: () {
                      if (profile.isDoctor) {
                        Navigator.of(context).pushReplacementNamed('/doctor');
                      } else {
                        Navigator.of(context).pushReplacementNamed('/receptionist');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 3. Authorized -> Render requested screen
    return child;
  }
}
