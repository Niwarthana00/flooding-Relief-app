import 'package:flutter/material.dart';
import 'package:sahana/core/services/voice_call_service.dart';
import 'package:sahana/core/theme/app_colors.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';

class VoiceCallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;
  final bool isOutgoing;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
    this.isOutgoing = true,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final VoiceCallService _callService = VoiceCallService();
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isUserJoined = false;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
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
    _timer?.cancel();
    await _callService.leaveCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
                  : 'Incoming call...',
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
