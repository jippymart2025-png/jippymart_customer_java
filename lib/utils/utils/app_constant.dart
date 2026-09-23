class AppConst {
  // static const String defaultBaseUrl = "https://web.jippymart.com/api/";

  // static const String defaultBaseUrl = "https://test.jippymart.in/api/";

  static const String defaultBaseUrl = "http://192.168.0.11:8084/api/";

  /// Active API base URL used throughout the app. Initialized with
  /// [defaultBaseUrl] and can be overridden by Firebase Remote Config.
  static String baseUrl = defaultBaseUrl;

  static const String outletBaseUrl = 'http://192.168.0.11:8084/api/';
}
