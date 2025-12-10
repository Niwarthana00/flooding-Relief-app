import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/features/chat/screens/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Query requests where user is participant
        // Firestore doesn't support logical OR directly in queries easily for this structure without composite indexes or separate queries.
        // However, we can stream all requests and filter client side if the dataset isn't huge,
        // OR we can rely on a 'participants' array if we had one.
        // Since we don't, and we have two roles, let's try to query based on the user's role or just fetch relevant ones.
        // A better approach for scalability is to have a 'chats' collection, but sticking to existing structure:
        // We'll try to fetch requests where userId == uid OR volunteerId == uid.
        // Since we can't do OR, we might need two streams or just fetch one if we know the role.
        // But the dashboard knows the role.
        // Actually, let's just fetch ALL requests for now and filter? No, that's bad.
        // Let's assume we can determine the role or just try both?
        // Wait, the user is logged in. If they are a beneficiary, they are 'userId'. If volunteer, 'volunteerId'.
        // But a user *could* theoretically be both in some apps, but here likely one.
        // Let's check the user document to see the role, or just use the dashboard context.
        // For simplicity, let's try to fetch where 'userId' == uid. If empty, try 'volunteerId' == uid?
        // Or better, use a StreamGroup or MergeStream?
        // Let's just use a simple approach: The user is likely EITHER beneficiary OR volunteer.
        // We can check the user's role from Firestore first?
        // Actually, let's just use the 'users' collection to get the role, then query accordingly.
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
          final role = userData?['role'];

          Query query = FirebaseFirestore.instance.collection('requests');
          if (role == 'volunteer') {
            query = query.where('volunteerId', isEqualTo: user?.uid);
          } else {
            query = query.where('userId', isEqualTo: user?.uid);
          }

          return StreamBuilder<QuerySnapshot>(
            stream: query
                .orderBy('createdAt', descending: true)
                .snapshots(), // Using createdAt to ensure all requests show up
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];

              // Filter out requests that are not relevant (e.g. maybe completed ones should still be shown for history?)
              // Let's show all assigned/active requests + completed ones.
              final chatDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // Show if there is a volunteer assigned (so a chat can exist)
                return data['volunteerId'] != null;
              }).toList();

              if (chatDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: chatDocs.length,
                itemBuilder: (context, index) {
                  final doc = chatDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final otherUserName = role == 'volunteer'
                      ? (data['userName'] ?? 'Beneficiary')
                      : (data['volunteerName'] ?? 'Volunteer');
                  final otherUserId = role == 'volunteer'
                      ? data['userId']
                      : data['volunteerId'];

                  return _ChatListItem(
                    requestId: doc.id,
                    otherUserName: otherUserName,
                    otherUserId: otherUserId,
                    lastMessage:
                        'Tap to view conversation', // We could fetch the last message if we had a subcollection summary
                    timestamp:
                        data['updatedAt'] as Timestamp? ??
                        data['createdAt'] as Timestamp?,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final String requestId;
  final String otherUserName;
  final String otherUserId;
  final String lastMessage;
  final Timestamp? timestamp;

  const _ChatListItem({
    required this.requestId,
    required this.otherUserName,
    required this.otherUserId,
    required this.lastMessage,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                requestId: requestId,
                otherUserName: otherUserName,
                otherUserId: otherUserId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: Text(
                  otherUserName.isNotEmpty
                      ? otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          otherUserName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        // We could add a time here if we had it
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
