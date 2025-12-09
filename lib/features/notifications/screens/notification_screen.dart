import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:sahana/features/chat/screens/chat_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Group notifications
          final docs = snapshot.data!.docs;
          final List<QueryDocumentSnapshot> uniqueDocs = [];
          final Set<String> processedSenders = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Only group unread chat notifications or all?
            // User said "messages dammahama", implying unread.
            // But if they are read, maybe we want to see history?
            // Usually notification center shows latest per conversation.
            // Let's group all chat notifications from same sender.
            if (data['type'] == 'chat') {
              final senderId = data['senderId'];
              if (senderId != null) {
                if (!processedSenders.contains(senderId)) {
                  processedSenders.add(senderId);
                  uniqueDocs.add(doc);
                }
              } else {
                uniqueDocs.add(doc);
              }
            } else {
              uniqueDocs.add(doc);
            }
          }

          return ListView.separated(
            itemCount: uniqueDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = uniqueDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final createdAt = data['createdAt'] as Timestamp?;

              return Container(
                color: isRead
                    ? Colors.white
                    : AppColors.primaryBlue.withOpacity(0.05),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey[200]
                        : AppColors.primaryBlue.withOpacity(0.2),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? Colors.grey : AppColors.primaryBlue,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        data['body'] ?? '',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () async {
                    _markAsRead(user.uid, doc.id);

                    // Navigate based on notification type
                    final type = data['type'];
                    if (type == 'chat') {
                      // Navigate to chat screen
                      final requestId = data['requestId'];
                      final senderId = data['senderId'];

                      if (requestId != null && senderId != null) {
                        try {
                          // Get sender details
                          final senderDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(senderId)
                              .get();

                          final senderName =
                              senderDoc.data()?['name'] ?? 'User';

                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  requestId: requestId,
                                  otherUserName: senderName,
                                  otherUserId: senderId,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error navigating to chat: $e');
                        }
                      }
                    } else if (data['requestId'] != null) {
                      // Navigate to request details
                      // You can implement this later
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return DateFormat('MMM d').format(date);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markAsRead(String userId, String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
