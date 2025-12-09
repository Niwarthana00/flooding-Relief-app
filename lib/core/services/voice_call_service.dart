import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sahana/core/config/agora_config.dart';

class VoiceCallService {
  static final VoiceCallService _instance = VoiceCallService._internal();
  factory VoiceCallService() => _instance;
  VoiceCallService._internal();

  RtcEngine? _engine;
  bool _isInCall = false;
  String? _currentChannelName;

  bool get isInCall => _isInCall;
  String? get currentChannelName => _currentChannelName;

  Future<void> initialize() async {
    if (_engine != null) return;

    // Request microphone permission
    await [Permission.microphone].request();

    // Create Agora RTC Engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // Enable audio
    await _engine!.enableAudio();
  }

  Future<void> joinCall(String channelName, {int uid = 0}) async {
    if (_engine == null) {
      await initialize();
    }

    _currentChannelName = channelName;

    // Join channel
    await _engine!.joinChannel(
      token: AgoraConfig.token ?? '',
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    _isInCall = true;
  }

  Future<void> leaveCall() async {
    if (_engine == null) return;

    await _engine!.leaveChannel();
    _isInCall = false;
    _currentChannelName = null;
  }

  Future<void> toggleMute(bool mute) async {
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(mute);
  }

  Future<void> toggleSpeaker(bool enableSpeaker) async {
    if (_engine == null) return;
    await _engine!.setEnableSpeakerphone(enableSpeaker);
  }

  void registerEventHandlers({
    Function(RtcConnection connection, int remoteUid, int elapsed)?
    onUserJoined,
    Function(
      RtcConnection connection,
      int remoteUid,
      UserOfflineReasonType reason,
    )?
    onUserOffline,
    Function(RtcConnection connection, RtcStats stats)? onLeaveChannel,
  }) {
    if (_engine == null) return;

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('Successfully joined channel: ${connection.channelId}');
        },
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onLeaveChannel: onLeaveChannel,
        onError: (ErrorCodeType err, String msg) {
          print('Agora Error: $err - $msg');
        },
      ),
    );
  }

  Future<void> dispose() async {
    if (_engine == null) return;

    await _engine!.leaveChannel();
    await _engine!.release();
    _engine = null;
    _isInCall = false;
    _currentChannelName = null;
  }
}
