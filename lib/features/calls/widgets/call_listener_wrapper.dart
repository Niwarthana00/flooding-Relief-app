import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/features/calls/screens/incoming_call_screen.dart';
import 'package:sahana/features/calls/services/call_signaling_service.dart';

class CallListenerWrapper extends StatefulWidget {
  final Widget child;

  const CallListenerWrapper({super.key, required this.child});

  @override
  State<CallListenerWrapper> createState() => _CallListenerWrapperState();
}

class _CallListenerWrapperState extends State<CallListenerWrapper> {
  final CallSignalingService _callService = CallSignalingService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (user == null) {
          return widget.child;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _callService.listenForIncomingCalls(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              final callDoc = snapshot.data!.docs.first;
              final callData = callDoc.data() as Map<String, dynamic>;

              return Stack(
                children: [
                  widget.child,
                  IncomingCallScreen(
                    callId: callDoc.id,
                    callerName: callData['callerName'] ?? 'Unknown',
                    channelName: callData['channelName'],
                  ),
                ],
              );
            }

            return widget.child;
          },
        );
      },
    );
  }
}
