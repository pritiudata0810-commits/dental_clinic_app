import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/tooth_logo.dart';
import '../../state/clinic_scope.dart';
import '../doctor/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _emailController = TextEditingController(text: 'receptionist@smilecare.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _errorMessage;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your work email or username';
        _isLoading = false;
      });
      return;
    }

    try {
      final role = await _authService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Trigger a live pull of Supabase records with authenticated credentials
      context.clinic.refreshRemoteData();

      if (role == 'doctor') {
        Navigator.of(context).pushReplacementNamed('/doctor');
      } else {
        Navigator.of(context).pushReplacementNamed('/receptionist');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Authentication failed: ${e.toString().replaceAll('Exception: ', '')}';
          _isLoading = false;
        });
      }
    }
  }

  void _showResetPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Station Password', style: AppTextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered clinic work email. We will send password reset instructions to your clinic administrator.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              decoration: const InputDecoration(
                labelText: 'Work Email',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to ${resetController.text}'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF5350C4), // Purple canvas matching Reference 1 outer background
      body: Stack(
        children: [
          // Background soft canvas layer
          Positioned.fill(
            child: Container(
              color: const Color(0xFF6B66D8),
            ),
          ),

          // Main Centered Content Viewport
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // Reference 1: Decorative diagonal purple pill graphics in top-right
                          Positioned(
                            top: -24,
                            right: -28,
                            child: _buildDecorativeTopPills(),
                          ),

                          // Inner Content Column
                          Padding(
                            padding: const EdgeInsets.fromLTRB(28, 40, 28, 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Logo: Clean Professional Tooth Logo
                                const ToothLogo(size: 68),
                                const SizedBox(height: 16),

                                // Application Name
                                const Text(
                                  'SmileCare',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1E1B4B),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'SmileCare OS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF5856D6),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Reference 1: "Welcome Back!" and supporting text
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2E2A72),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'SmileCare OS • Dental Clinic Management\nPlease enter your clinic credentials to continue.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Error Banner if any
                                if (_errorMessage != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, size: 18, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Reference 1: Deep Purple Rounded Form Card
                                Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4C45B2), // Deep purple card from Reference 1
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4C45B2).withValues(alpha: 0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Email / Username Label
                                      const Text(
                                        'Email Or User Name',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Email Input Field
                                      Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8E7F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.mail_outline_rounded, size: 18, color: Color(0xFF5856D6)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller: _emailController,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E1B4B), fontWeight: FontWeight.w500),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  hintText: 'Enter your Email here',
                                                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF8E8DBE)),
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF4C45B2)),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Password Label
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Password Input Field
                                      Container(
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8E7F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF5856D6)),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E1B4B), fontWeight: FontWeight.w500),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.zero,
                                                  hintText: '••••••••',
                                                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8E8DBE)),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: Icon(
                                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                                size: 18,
                                                color: const Color(0xFF6B66D8),
                                              ),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      // Remember me & Forgot Password Row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: Checkbox(
                                                    value: _rememberMe,
                                                    activeColor: Colors.white,
                                                    checkColor: const Color(0xFF4C45B2),
                                                    side: const BorderSide(color: Colors.white70, width: 1.5),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Remember me',
                                                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: _showResetPasswordDialog,
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.underline,
                                                decorationColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 20),

                                      // Reference 1: Pill Gradient "Sign in" Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                          ),
                                          onPressed: _isLoading ? null : _performLogin,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF6B63E8),
                                                  Color(0xFF8B85F8),
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius: BorderRadius.circular(24),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                    )
                                                  : const Text(
                                                      'Sign in',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Reference 1: "OR LOGIN WITH" / Quick Demo Role Credentials
                                Center(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Clinic Staff Sign In',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6B7280),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildRoleQuickFillPill(
                                              title: 'Receptionist Account',
                                              email: 'receptionist@smilecare.com',
                                              icon: Icons.person_rounded,
                                              color: const Color(0xFF5856D6),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _buildRoleQuickFillPill(
                                              title: 'Doctor Account',
                                              email: 'doctor@smilecare.com',
                                              icon: Icons.medical_services_rounded,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            "Don't have an account? ",
                                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                              );
                                            },
                                            child: const Text(
                                              'Register Now',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF4C45B2),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleQuickFillPill({
    required String title,
    required String email,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _emailController.text = email;
          _passwordController.text = 'password123';
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F2FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E0F9)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E2A72),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reference 1: Top right diagonal rounded pill decoration
  Widget _buildDecorativeTopPills() {
    return Transform.rotate(
      angle: -0.78, // ~ -45 degrees
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF6B66D8),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF5856D6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF8B85F8),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
