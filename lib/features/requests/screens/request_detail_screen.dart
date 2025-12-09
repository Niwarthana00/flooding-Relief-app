import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/features/requests/screens/tracking_screen.dart';
import 'package:sahana/features/chat/screens/chat_screen.dart';
import 'package:sahana/features/calls/screens/voice_call_screen.dart';
import 'package:sahana/core/config/agora_config.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestId;

  const RequestDetailScreen({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  Future<void> _launchCaller(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = requestData['category'] ?? 'Request';
    final status = requestData['status'] ?? 'Pending';
    final description = requestData['description'] ?? '';
    final urgency = requestData['urgency'] ?? 'Medium';
    final familySize = requestData['familySize'] ?? '1';
    final address = requestData['address'] ?? 'Location not set';
    final volunteerName = requestData['volunteerName'];
    final volunteerPhone =
        requestData['volunteerPhone'] ?? '+94 77 123 4567'; // Mock if missing
    final createdAt = requestData['createdAt'] as Timestamp?;
    final location = requestData['location'] as GeoPoint?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Card
            _buildStatusCard(status, createdAt),
            const SizedBox(height: 16),

            // Volunteer Card (Only if assigned)
            // Contact Card
            if (FirebaseAuth.instance.currentUser?.uid ==
                requestData['volunteerId'])
              _buildBeneficiaryContactCard(context)
            else if (volunteerName != null ||
                [
                  'assigned',
                  'arriving',
                  'completed',
                ].contains(status.toLowerCase()))
              _buildVolunteerCard(
                context,
                volunteerName ?? 'Volunteer',
                volunteerPhone,
              ),

            if (volunteerName != null) const SizedBox(height: 16),

            // Track Location Button (Only if active)
            if (['assigned', 'arriving'].contains(status.toLowerCase()))
              _buildTrackLocationButton(context, location),

            // Accept Button (Only if pending and NOT the owner)
            if (status.toLowerCase() == 'pending' &&
                FirebaseAuth.instance.currentUser?.uid != requestData['userId'])
              _buildAcceptButton(context),

            if ([
              'assigned',
              'arriving',
              'pending',
            ].contains(status.toLowerCase()))
              const SizedBox(height: 16),

            // Status Update Button (Only for assigned volunteer)
            if (FirebaseAuth.instance.currentUser?.uid ==
                    requestData['volunteerId'] &&
                ['assigned', 'arriving'].contains(status.toLowerCase()))
              _buildStatusUpdateButton(context, status),

            // Request Details Card
            _buildDetailsCard(description, familySize, urgency, address),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, Timestamp? createdAt) {
    final steps = [
      {'title': 'Request Submitted', 'time': _formatTime(createdAt)},
      {'title': 'Volunteer Assigned', 'time': 'Waiting...'},
      {'title': 'On The Way', 'time': 'ETA: --'},
      {'title': 'Delivered', 'time': ''},
    ];

    int currentStep = 0;
    final s = status.toLowerCase();
    if (s == 'pending')
      currentStep = 1;
    else if (s == 'assigned')
      currentStep = 2;
    else if (s == 'arriving')
      currentStep = 3;
    else if (s == 'completed')
      currentStep = 4;

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Request Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final isCompleted = index < currentStep;
              final isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[index]['title']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.textDark
                                : Colors.grey,
                          ),
                        ),
                        if (steps[index]['time']!.isNotEmpty && isCompleted)
                          Text(
                            steps[index]['time']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 30), // Spacing for timeline line
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(BuildContext context, String name, String phone) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Volunteer Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start in-app voice call
                    final channelName = AgoraConfig.getChannelName(requestId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceCallScreen(
                          channelName: channelName,
                          otherUserName: name,
                          isOutgoing: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Voice Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          requestId: requestId,
                          otherUserName: name,
                          otherUserId: requestData['volunteerId'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryContactCard(BuildContext context) {
    final name = requestData['userName'] ?? 'Beneficiary';
    // Note: Beneficiary phone might not be in requestData.
    // Ideally it should be fetched or stored. For now we use a placeholder or check if it exists.
    final phone = requestData['userPhone'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Beneficiary Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.orange,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Text(
                      phone,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start in-app voice call
                    final channelName = AgoraConfig.getChannelName(requestId);
                    final currentUserId =
                        FirebaseAuth.instance.currentUser?.uid;
                    final receiverId =
                        currentUserId == requestData['volunteerId']
                        ? requestData['userId']
                        : requestData['volunteerId'];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoiceCallScreen(
                          channelName: channelName,
                          otherUserName: name,
                          receiverId: receiverId,
                          isOutgoing: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Voice Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          requestId: requestId,
                          otherUserName: name,
                          otherUserId: requestData['userId'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackLocationButton(BuildContext context, GeoPoint? location) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: location == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackingScreen(
                      requestId: requestId,
                      deliveryLocation: location,
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.near_me),
        label: const Text('Track Live Location'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('requests')
                  .doc(requestId)
                  .update({
                    'status': 'assigned',
                    'volunteerId': user.uid,
                    'volunteerName': user.displayName ?? 'Volunteer',
                    'volunteerPhone':
                        user.phoneNumber ?? '', // Or fetch from user doc
                  });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request Accepted!')),
                );
                Navigator.pop(context);
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error accepting request: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Accept Request'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildStatusUpdateButton(BuildContext context, String currentStatus) {
    String nextStatus = '';
    String buttonText = '';
    Color buttonColor = AppColors.primaryBlue;

    if (currentStatus.toLowerCase() == 'assigned') {
      nextStatus = 'arriving';
      buttonText = 'Mark as Arriving';
      buttonColor = Colors.orange;
    } else if (currentStatus.toLowerCase() == 'arriving') {
      nextStatus = 'completed';
      buttonText = 'Mark as Completed';
      buttonColor = Colors.green;
    } else {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await FirebaseFirestore.instance
                .collection('requests')
                .doc(requestId)
                .update({'status': nextStatus});
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Status updated to $nextStatus!')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating status: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.update),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    String description,
    dynamic familySize,
    String urgency,
    String address,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Request Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          _buildDetailLabel('Description'),
          Text(
            description,
            style: const TextStyle(color: AppColors.textDark, height: 1.5),
          ),
          const SizedBox(height: 20),

          // Items Requested (Mocked/Static for now as per image style, or parsed if we had data)
          // Since we don't have itemized data, we'll skip the chips or show a placeholder if description is short.
          // For now, let's stick to the fields we have.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLabel('Family Size'),
                    Text(
                      '$familySize members',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailLabel('Urgency'),
                    Text(
                      urgency,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getUrgencyColor(urgency),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildDetailLabel('Delivery Location'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
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
        return Colors.black;
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
