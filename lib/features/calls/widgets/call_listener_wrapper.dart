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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return widget.child;
    }

    return StreamBuilder(
      stream: _callService.listenForIncomingCalls(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final callDoc = snapshot.data!.docs.first;
          final callData = callDoc.data() as Map<String, dynamic>;

          // Only show if we are not already in a call (basic check)
          // Ideally we should check if the IncomingCallScreen is already pushed

          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Check if we are already showing the incoming call screen to avoid duplicates
            // This is a simple implementation. For production, use a more robust navigation service.
            // For now, we rely on the fact that if a call is 'ringing', we show the screen.
            // But we need to be careful not to push it multiple times.

            // A better approach is to navigate only if the top route is not IncomingCallScreen
            // But since we don't have easy access to route stack here without a navigation key...
            // We will just push it. The IncomingCallScreen should handle "Decline" which removes the doc or changes status,
            // which will trigger this stream again with empty docs.

            // However, StreamBuilder builds repeatedly. We shouldn't push navigation inside build directly without checks.
            // But since we are using addPostFrameCallback, it happens after build.

            // To prevent multiple pushes, we can check if the call ID is different or if we haven't handled this call ID yet.
          });

          // Instead of pushing navigation here which is tricky in a wrapper,
          // we can return a Stack with the IncomingCallScreen on top if there is a call.
          // This acts like an overlay.

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
  }
}
