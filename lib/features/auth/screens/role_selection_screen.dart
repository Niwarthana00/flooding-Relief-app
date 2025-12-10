import 'package:flutter/material.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/features/auth/screens/beneficiary_login_screen.dart';
import 'package:sahana/features/auth/screens/volunteer_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0FDF4), // Very Light Green
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Icon with Glow
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      size: 64,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'SAHANA',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Flood Relief Assistance Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Role Cards
                  _RoleCard(
                    title: 'I Need Help',
                    subtitle: 'Request assistance for you and your family',
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BeneficiaryLoginScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  _RoleCard(
                    title: 'I Want to Help',
                    subtitle: 'Volunteer to distribute relief items',
                    icon: Icons.handshake_rounded,
                    color: AppColors.primaryBlue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VolunteerLoginScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  // Footer
                  Text(
                    'Together we can overcome any disaster',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade50,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
