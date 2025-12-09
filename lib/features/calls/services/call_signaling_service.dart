import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CallSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a call document
  Future<String> makeCall({
    required String callerId,
    required String callerName,
    required String receiverId,
    required String channelName,
  }) async {
    try {
      final docRef = await _firestore.collection('calls').add({
        'callerId': callerId,
        'callerName': callerName,
        'receiverId': receiverId,
        'channelName': channelName,
        'status': 'ringing',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error making call: $e');
      rethrow;
    }
  }

  // Update call status
  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    try {
      await _firestore.collection('calls').doc(callId).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  // End call
  Future<void> endCall({required String callId}) async {
    await updateCallStatus(callId: callId, status: 'ended');
  }

  // Listen for incoming calls
  Stream<QuerySnapshot> listenForIncomingCalls(String userId) {
    return _firestore
        .collection('calls')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  // Listen to specific call status
  Stream<DocumentSnapshot> listenToCallStatus(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  // Log notification
  Future<void> logNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }
}
