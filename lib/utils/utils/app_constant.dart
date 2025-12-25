class AppConst {
  // Default API base URL. Remote Config can override this at runtime.
  // static const String defaultBaseUrl = "http://sanhits.online/api/";
  // static const String defaultBaseUrl = "https://web.jippymart.in/api/";

  static const String defaultBaseUrl = "http://192.168.0.27:8002/api/";

  /// Active API base URL used throughout the app. Initialized with
  /// [defaultBaseUrl] and can be overridden by Firebase Remote Config.
  static String baseUrl = defaultBaseUrl;
}
