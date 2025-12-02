import 'package:flutter/material.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/core/services/auth_service.dart';
import 'package:sahana/features/auth/screens/role_selection_screen.dart';
import 'package:sahana/features/requests/screens/create_request_screen.dart';

class BeneficiaryDashboard extends StatefulWidget {
  const BeneficiaryDashboard({super.key});

  @override
  State<BeneficiaryDashboard> createState() => _BeneficiaryDashboardState();
}

class _BeneficiaryDashboardState extends State<BeneficiaryDashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _selectedIndex == 0
          ? const _HomeTab()
          : _selectedIndex == 1
          ? const Center(child: Text("Requests"))
          : const Center(child: Text("Profile")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Custom Header Section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Top Row: Profile & Actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Nimal Perera', // Hardcoded for UI demo
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await AuthService().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleSelectionScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white24,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Daily Request Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Request Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Available',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.0, // 0% used
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'You can create 1 request today',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Create New Request Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Create New Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669), // Darker green
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF059669).withOpacity(0.4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Emergency Request Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB), // Light yellow bg
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFCD34D),
                    ), // Yellow border
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Emergency Request',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'For critical emergencies, you can request admin approval to bypass the daily limit.',
                              style: TextStyle(
                                color: const Color(0xFF92400E).withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Active Requests Header
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '2 active',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active Request Cards (Hardcoded)
                const _RequestCard(
                  title: 'Food Package',
                  status: 'Arriving',
                  statusColor: Color(0xFFDCFCE7), // Light green bg
                  statusTextColor: Color(0xFF166534), // Dark green text
                  priority: 'High Priority',
                  description:
                      'Rice, dhal, milk powder, and cooking oil for family of 4',
                  location: 'Colombo 07',
                  time: '2 hours ago',
                  volunteerName: 'Kasun Silva',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 16),
                const _RequestCard(
                  title: 'Medical Supplies',
                  status: 'Assigned',
                  statusColor: Color(0xFFDBEAFE), // Light blue bg
                  statusTextColor: Color(0xFF1E40AF), // Dark blue text
                  priority: 'Critical Priority',
                  priorityColor: Colors.red,
                  description:
                      'First aid kit and basic medicines needed urgently',
                  location: 'Colombo 07',
                  time: '4 hours ago',
                  volunteerName: 'Amila Fernando',
                  icon: Icons.medical_services_outlined,
                ),

                const SizedBox(height: 32),

                // Past Requests Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Past Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: const Text('View All')),
                  ],
                ),
                const SizedBox(height: 16),

                // Past Request Card
                const _RequestCard(
                  title: 'Clothing & Essentials',
                  status: 'Completed',
                  statusColor: Color(0xFFF3F4F6), // Grey bg
                  statusTextColor: Color(0xFF4B5563), // Grey text
                  priority: 'Medium Priority',
                  priorityColor: Colors.blue,
                  description: 'Clothes for children and basic toiletries',
                  location: 'Colombo 07',
                  time: '2 days ago',
                  icon: Icons.checkroom_outlined,
                  isCompleted: true,
                ),
                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
  final String priority;
  final Color priorityColor;
  final String description;
  final String location;
  final String time;
  final String? volunteerName;
  final IconData icon;
  final bool isCompleted;

  const _RequestCard({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.statusTextColor,
    required this.priority,
    this.priorityColor = const Color(0xFFEA580C), // Orange default
    required this.description,
    required this.location,
    required this.time,
    this.volunteerName,
    required this.icon,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (!isCompleted) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusTextColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: const TextStyle(color: AppColors.textLight, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Footer Info
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),

          if (volunteerName != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Volunteer: ',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  volunteerName!,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
