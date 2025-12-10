import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sahana/core/services/auth_service.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/features/auth/screens/volunteer_registration_screen.dart';
import 'package:sahana/features/dashboard/screens/volunteer_dashboard.dart';
import 'package:sahana/core/services/notification_service.dart';

class VolunteerLoginScreen extends StatefulWidget {
  const VolunteerLoginScreen({super.key});

  @override
  State<VolunteerLoginScreen> createState() => _VolunteerLoginScreenState();
}

class _VolunteerLoginScreenState extends State<VolunteerLoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        if (mounted) {
          // Check if user exists in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signed in successfully!')),
            );

            if (userDoc.exists) {
              // User exists, save token and go to Dashboard
              await NotificationService().initialize();

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VolunteerDashboard(),
                  ),
                );
              }
            } else {
              // New user, go to Registration
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const VolunteerRegistrationScreen(),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing in: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD), // Light Blue
              Color(0xFFFFFFFF), // White
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or Icon Placeholder
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            size: 64,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Welcome Text
                      const Text(
                        'Volunteer Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sign in to help distribute relief and support those in need',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.primaryBlue,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement Email/Password Login
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 10,
                            shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Google Sign In Button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : SizedBox(
                              height: 56,
                              child: _GoogleSignInButton(
                                onPressed: _handleGoogleSignIn,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
            height: 24,
            width: 24,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sign in with Google',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
