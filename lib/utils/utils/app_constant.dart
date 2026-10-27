class AppConst {
  // static const String defaultBaseUrl = "https://web.jippymart.com/api/";

  static const String defaultBaseUrl = "http://192.168.29.36:8084/api/";

  // static const String defaultBaseUrl =
  //     "http://srv1617582.hstgr.cloud:8084/api/";

  /// Active API base URL used throughout the app. Initialized with
  /// [defaultBaseUrl] and can be overridden by Firebase Remote Config.
  static String baseUrl = defaultBaseUrl;
}
