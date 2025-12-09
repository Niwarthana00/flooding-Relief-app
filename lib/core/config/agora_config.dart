class AgoraConfig {
  // Agora App ID
  static const String appId = 'b66420727fba4330a684fe55c826011e';

  // Agora Token (Optional - for production use)
  // For testing, you can use null and enable "Testing Mode" in Agora Console
  static const String? token = null;

  // Channel name will be dynamic based on request ID
  static String getChannelName(String requestId) {
    return 'sahana_call_$requestId';
  }
}
