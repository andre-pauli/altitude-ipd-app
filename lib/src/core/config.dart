class AppConfig {
  // Firebase Configuration
  static const String firebaseApiKey =
      "AIzaSyBvSf8UA0u8KDSLMUCx2a2wSs7SU5kFAkY";
  static const String firebaseDatabaseUrl =
      "https://altitude-ipd-app-64069-default-rtdb.firebaseio.com";
  static const String firebaseProjectId = "altitude-ipd-app-64069";
  static const String firebaseStorageBucket =
      "altitude-ipd-app-64069.firebasestorage.app";
  static const String firebaseMessagingSenderId = "648813911018";
  static const String firebaseAppId =
      "1:648813911018:android:56bfd63434b03b56277093";

  // WebRTC Configuration
  static const String signalingServerUrl = "http://91.108.125.86:3000";
  static const List<Map<String, String>> iceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ];

  // Telegram Configuration
  static const String telegramBotToken =
      "7819105841:AAHH_FehkoavVorcUp_AkkWRCmklPNvcSik";
  static const String telegramChatId = "-4708090583";

  // Weather API Configuration
  static const String weatherApiKey = "3b5f158ce6139961df47c7579f9f1629";
  static const String weatherBaseUrl =
      "https://api.openweathermap.org/data/2.5/weather";

  // App Configuration
  static const String appName = "Altitude IPD";
  static const String appVersion = "1.0.0";
  static const int callTimeoutSeconds = 100;
  static const String supportPhoneNumber = "17-98215-9000";

  // UI Configuration
  static const double defaultWidth = 1200.0;
  static const double defaultHeight = 1920.0;
  static const String defaultFontFamily = "Roboto";

  // Call Configuration
  static const String defaultRoomPrefix = "Elevador";
  static const int maxCallDurationMinutes = 30;
  static const bool enableVideoCalls = true;
  static const bool enableAudioCalls = true;

  // Debug Configuration
  static const bool enableDebugLogs = true;
  static const bool enableFirebaseLogs = true;
  static const bool enableWebRTCLogs = true;
}
