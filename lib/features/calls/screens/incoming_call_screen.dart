import 'package:flutter/material.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:sahana/features/calls/screens/voice_call_screen.dart';
import 'package:sahana/features/calls/services/call_signaling_service.dart';
import 'package:sahana/main.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callId;
  final String callerName;
  final String channelName;
  final CallSignalingService _callService = CallSignalingService();

  IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerName,
    required this.channelName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Caller Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            // Caller Name
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Incoming Voice Call...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline Button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _callService.updateCallStatus(
                            callId: callId,
                            status: 'declined',
                          );
                          // The stream in CallListenerWrapper will handle removing this screen
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Decline',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Accept Button
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _callService.updateCallStatus(
                            callId: callId,
                            status: 'accepted',
                          );
                          // Push VoiceCallScreen using global navigator key
                          navigatorKey.currentState?.push(
                            MaterialPageRoute(
                              builder: (context) => VoiceCallScreen(
                                channelName: channelName,
                                otherUserName: callerName,
                                isOutgoing: false,
                                callId: callId,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
