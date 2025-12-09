import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sahana/core/services/voice_call_service.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'dart:async';
import 'package:sahana/features/calls/services/call_signaling_service.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;
  final bool isOutgoing;
  final String? callId;
  final String? receiverId; // Required if isOutgoing is true

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
    this.isOutgoing = true,
    this.callId,
    this.receiverId,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final VoiceCallService _callService = VoiceCallService();
  final CallSignalingService _signalingService = CallSignalingService();
  String? _currentCallId;
  StreamSubscription<DocumentSnapshot>? _callStatusSubscription;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isUserJoined = false;
  int _callDuration = 0;
  Timer? _timer;
  bool _isCallEnded = false;

  @override
  void initState() {
    super.initState();
    _currentCallId = widget.callId;
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // If outgoing, create call document
    if (widget.isOutgoing) {
      if (widget.receiverId == null) {
        debugPrint('Receiver ID is null for outgoing call');
        return;
      }
      try {
        _currentCallId = await _signalingService.makeCall(
          callerId: user.uid,
          callerName: user.displayName ?? 'Unknown',
          receiverId: widget.receiverId!,
          channelName: widget.channelName,
        );
      } catch (e) {
        debugPrint('Error creating call: $e');
        if (mounted) Navigator.pop(context);
        return;
      }
    }

    // Listen to call status
    if (_currentCallId != null) {
      _callStatusSubscription = _signalingService
          .listenToCallStatus(_currentCallId!)
          .listen((snapshot) {
            if (!snapshot.exists) {
              _endCall();
              return;
            }
            final data = snapshot.data() as Map<String, dynamic>;
            final status = data['status'];
            if (status == 'ended' || status == 'declined') {
              _endCall();
            }
          });
    }

    await _callService.initialize();

    // Register event handlers
    _callService.registerEventHandlers(
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() {
          _isUserJoined = true;
        });
        _startTimer();
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() {
          _isUserJoined = false;
        });
        _endCall();
      },
      onLeaveChannel: (connection, stats) {
        _endCall();
      },
    );

    // Join the call
    await _callService.joinCall(widget.channelName);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _callService.toggleMute(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    await _callService.toggleSpeaker(_isSpeakerOn);
  }

  Future<void> _endCall() async {
    if (_isCallEnded) return;
    _isCallEnded = true;

    _timer?.cancel();
    _callStatusSubscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final durationStr = _formatDuration(_callDuration);

      if (widget.isOutgoing) {
        if (_isUserJoined) {
          // Log Outgoing Call to Self
          await _signalingService.logNotification(
            userId: user.uid,
            title: 'Outgoing Call',
            body: 'Call with ${widget.otherUserName}: $durationStr',
            type: 'call_log',
          );
          // Log Incoming Call to Receiver (so they see duration)
          if (widget.receiverId != null) {
            await _signalingService.logNotification(
              userId: widget.receiverId!,
              title: 'Incoming Call',
              body:
                  'Call with ${user.displayName ?? 'Volunteer'}: $durationStr',
              type: 'call_log',
            );
          }
        } else {
          // Log Missed Call to Receiver
          if (widget.receiverId != null) {
            await _signalingService.logNotification(
              userId: widget.receiverId!,
              title: 'Missed Call',
              body: 'You missed a call from ${user.displayName ?? 'Volunteer'}',
              type: 'missed_call',
            );
          }
        }
      } else {
        // Receiver Side
        // We rely on Caller to log the "Incoming Call" duration to us to avoid duplicates.
        // But if Caller crashes, we might miss it.
        // Let's log to self just in case, but checking if we want duplicates?
        // Actually, if both log to self, it's safer.
        // Let's change strategy: EVERYONE LOGS TO SELF.
        // Caller logs to Self. Receiver logs to Self.
        // EXCEPT Missed Call: Caller logs to Receiver.

        if (_isUserJoined) {
          // Log Incoming Call to Self
          await _signalingService.logNotification(
            userId: user.uid,
            title: 'Incoming Call',
            body: 'Call with ${widget.otherUserName}: $durationStr',
            type: 'call_log',
          );
        }
      }
    }

    // Update status to ended if we have a call ID
    if (_currentCallId != null) {
      await _signalingService.endCall(callId: _currentCallId!);
    }

    await _callService.leaveCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callStatusSubscription?.cancel();
    _callService.leaveCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // User Avatar
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

            // User Name
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Call Status
            Text(
              _isUserJoined
                  ? _formatDuration(_callDuration)
                  : widget.isOutgoing
                  ? 'Calling...'
                  : 'Connecting...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Call Controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    onTap: _toggleMute,
                    backgroundColor: _isMuted
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    iconColor: _isMuted ? AppColors.primaryBlue : Colors.white,
                  ),

                  // End Call Button
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End',
                    onTap: _endCall,
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    size: 70,
                  ),

                  // Speaker Button
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    onTap: _toggleSpeaker,
                    backgroundColor: _isSpeakerOn
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                    iconColor: _isSpeakerOn
                        ? AppColors.primaryBlue
                        : Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
    required Color iconColor,
    double size = 60,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
