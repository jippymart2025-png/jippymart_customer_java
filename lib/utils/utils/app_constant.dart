class AppConst {
  // Default API base URL. Remote Config can override this at runtime.
  // static const String defaultBaseUrl = "https://admin.jippymart.in/api/";

  // static const String defaultBaseUrl = "https://web.jippymart.com/api/";

  static const String defaultBaseUrl = "http://192.168.88.8:8000/api/";

  /// Active API base URL used throughout the app. Initialized with
  /// [defaultBaseUrl] and can be overridden by Firebase Remote Config.
  static String baseUrl = defaultBaseUrl;
}
