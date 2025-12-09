import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/core/services/auth_service.dart';
import 'package:sahana/features/auth/screens/role_selection_screen.dart';
import 'package:sahana/features/requests/screens/create_request_screen.dart';
import 'package:sahana/features/requests/screens/request_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:sahana/core/providers/locale_provider.dart';
import 'package:sahana/l10n/app_localizations.dart';
import 'package:sahana/features/profile/screens/edit_profile_screen.dart';

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
          ? const _RequestsTab()
          : const _ProfileTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: AppLocalizations.of(context)!.requests,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _locationText = 'Loading location...';
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('location')) {
            final geoPoint = data['location'] as GeoPoint;
            _getAddressFromLatLng(geoPoint);
          } else {
            if (mounted) {
              setState(() {
                _locationText = 'Location not set';
              });
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Error fetching location';
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isUpdatingLocation = true;
      _locationText = 'Updating...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Permission denied';
            _isUpdatingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Permission permanently denied';
          _isUpdatingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final geoPoint = GeoPoint(position.latitude, position.longitude);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'location': geoPoint});
        await _getAddressFromLatLng(geoPoint);
      }
    } catch (e) {
      setState(() {
        _locationText = 'Error updating';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(GeoPoint point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _locationText = '${place.locality}, ${place.administrativeArea}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Unknown Location';
        });
      }
    }
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7); // Yellow
      case 'approved':
      case 'assigned':
      case 'arriving':
        return const Color(0xFFDCFCE7); // Green
      case 'completed':
        return const Color(0xFFF3F4F6); // Grey
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2); // Red
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'approved':
      case 'assigned':
      case 'arriving':
        return const Color(0xFF166534);
      case 'completed':
        return const Color(0xFF4B5563);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food package':
      case 'food':
        return Icons.inventory_2_outlined;
      case 'medical supplies':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'clothing & essentials':
      case 'clothing':
        return Icons.checkroom_outlined;
      case 'shelter materials':
      case 'shelter':
        return Icons.home_work_outlined;
      case 'cash assistance':
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final displayName =
            userData?['name'] ?? user?.displayName ?? 'Beneficiary';
        final firstName = displayName.split(' ').first;
        final photoURL = userData?['photoURL'] ?? user?.photoURL;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final activeRequests = docs.where((doc) {
              final status = (doc['status'] as String).toLowerCase();
              return [
                'pending',
                'approved',
                'assigned',
                'arriving',
              ].contains(status);
            }).toList();

            final pastRequests = docs.where((doc) {
              final status = (doc['status'] as String).toLowerCase();
              return ['completed', 'rejected', 'cancelled'].contains(status);
            }).toList();

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
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                backgroundImage: photoURL != null
                                    ? NetworkImage(photoURL)
                                    : null,
                                child: photoURL == null
                                    ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    firstName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: _isUpdatingLocation
                                        ? null
                                        : _updateLocation,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _locationText,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationStyle:
                                                  TextDecorationStyle.dotted,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_isUpdatingLocation)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.refresh,
                                            color: Colors.white70,
                                            size: 12,
                                          ),
                                      ],
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
                                      builder: (_) =>
                                          const RoleSelectionScreen(),
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
                                  builder: (context) =>
                                      const CreateRequestScreen(),
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
                              backgroundColor: const Color(
                                0xFF059669,
                              ), // Darker green
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF059669,
                              ).withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Active Requests Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active Requests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${activeRequests.length} active',
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Active Request Cards
                        if (activeRequests.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No active requests'),
                            ),
                          )
                        else
                          ...activeRequests.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _RequestCard(
                                title: data['category'] ?? 'Request',
                                status: data['status'] ?? 'Pending',
                                statusColor: _getStatusColor(
                                  data['status'] ?? 'Pending',
                                ),
                                statusTextColor: _getStatusTextColor(
                                  data['status'] ?? 'Pending',
                                ),
                                priority:
                                    '${data['urgency'] ?? 'Medium'} Priority',
                                priorityColor: _getUrgencyColor(
                                  data['urgency'] ?? 'Medium',
                                ),
                                description: data['description'] ?? '',
                                location: data['address'] ?? 'Location',
                                time: _getTimeAgo(
                                  data['createdAt'] as Timestamp?,
                                ),
                                volunteerName: data['volunteerName'],
                                icon: _getCategoryIcon(
                                  data['category']?.toString().toLowerCase(),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestDetailScreen(
                                        requestData: data,
                                        requestId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),

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
                            TextButton(
                              onPressed: () {},
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Past Request Cards
                        if (pastRequests.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No past requests'),
                            ),
                          )
                        else
                          ...pastRequests.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: _RequestCard(
                                title: data['category'] ?? 'Request',
                                status: data['status'] ?? 'Completed',
                                statusColor: _getStatusColor(
                                  data['status'] ?? 'Completed',
                                ),
                                statusTextColor: _getStatusTextColor(
                                  data['status'] ?? 'Completed',
                                ),
                                priority:
                                    '${data['urgency'] ?? 'Medium'} Priority',
                                priorityColor: _getUrgencyColor(
                                  data['urgency'] ?? 'Medium',
                                ),
                                description: data['description'] ?? '',
                                location: data['address'] ?? 'Location',
                                time: _getTimeAgo(
                                  data['createdAt'] as Timestamp?,
                                ),
                                icon: _getCategoryIcon(
                                  data['category']?.toString().toLowerCase(),
                                ),
                                isCompleted: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RequestDetailScreen(
                                        requestData: data,
                                        requestId: doc.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }),
                        const SizedBox(height: 80), // Bottom padding
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  String _filter = 'All'; // All, Active, Past

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'approved':
      case 'assigned':
      case 'arriving':
        return const Color(0xFFDCFCE7);
      case 'completed':
        return const Color(0xFFF3F4F6);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'approved':
      case 'assigned':
      case 'arriving':
        return const Color(0xFF166534);
      case 'completed':
        return const Color(0xFF4B5563);
      case 'rejected':
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'food package':
      case 'food':
        return Icons.inventory_2_outlined;
      case 'medical supplies':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'clothing & essentials':
      case 'clothing':
        return Icons.checkroom_outlined;
      case 'shelter materials':
      case 'shelter':
        return Icons.home_work_outlined;
      case 'cash assistance':
      case 'cash':
        return Icons.payments_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.requests,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.textDark),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Requests')),
              const PopupMenuItem(value: 'Active', child: Text('Active Only')),
              const PopupMenuItem(value: 'Past', child: Text('Past Only')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final filteredDocs = docs.where((doc) {
            final status = (doc['status'] as String).toLowerCase();
            final isActive = [
              'pending',
              'approved',
              'assigned',
              'arriving',
            ].contains(status);

            if (_filter == 'Active') return isActive;
            if (_filter == 'Past') return !isActive;
            return true;
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No requests found',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateRequestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final isCompleted = [
                'completed',
                'rejected',
                'cancelled',
              ].contains(status.toLowerCase());

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _RequestCard(
                  title: data['category'] ?? 'Request',
                  status: status,
                  statusColor: _getStatusColor(status),
                  statusTextColor: _getStatusTextColor(status),
                  priority: '${data['urgency'] ?? 'Medium'} Priority',
                  priorityColor: _getUrgencyColor(data['urgency'] ?? 'Medium'),
                  description: data['description'] ?? '',
                  location: data['address'] ?? 'Location',
                  time: _getTimeAgo(data['createdAt'] as Timestamp?),
                  volunteerName: data['volunteerName'],
                  icon: _getCategoryIcon(
                    data['category']?.toString().toLowerCase(),
                  ),
                  isCompleted: isCompleted,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailScreen(
                          requestData: data,
                          requestId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Center(child: Text("Not logged in"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final displayName =
            userData?['name'] ?? user.displayName ?? 'Beneficiary';
        final email = user.email ?? '';
        final photoURL = userData?['photoURL'] ?? user.photoURL;

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      backgroundImage: photoURL != null
                          ? NetworkImage(photoURL)
                          : null,
                      child: photoURL == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.primaryGreen,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildProfileItem(
                      Icons.person_outline,
                      AppLocalizations.of(context)!.editProfile,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileItem(
                      Icons.language,
                      AppLocalizations.of(context)!.changeLanguage,
                      () {
                        _showLanguageBottomSheet(context);
                      },
                    ),
                    _buildProfileItem(
                      Icons.history,
                      AppLocalizations.of(context)!.history,
                      () {},
                    ),
                    _buildProfileItem(
                      Icons.notifications_outlined,
                      'Notifications',
                      () {},
                    ),
                    _buildProfileItem(
                      Icons.settings_outlined,
                      'Settings',
                      () {},
                    ),
                    _buildProfileItem(
                      Icons.help_outline,
                      'Help & Support',
                      () {},
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<LocaleProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Language',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildLanguageItem(context, provider, 'English', 'en'),
                  _buildLanguageItem(context, provider, 'සිංහල', 'si'),
                  _buildLanguageItem(context, provider, 'தமிழ்', 'ta'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageItem(
    BuildContext context,
    LocaleProvider provider,
    String name,
    String code,
  ) {
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      leading: Text(
        code.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
      title: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
          : null,
      onTap: () {
        provider.setLocale(Locale(code));
        Navigator.pop(context);
      },
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
  final VoidCallback? onTap;

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
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
                    mainAxisSize: MainAxisSize.min,
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
                      Flexible(
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Volunteer: ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Expanded(
                    child: Text(
                      volunteerName!,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
