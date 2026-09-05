import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:jippymart_customer/utils/utils/app_constant.dart';
import 'package:jippymart_customer/utils/utils/common.dart';

/// Fetches the legal documents (privacy policy / terms & conditions) from:
///
/// GET /fm/terms-and-conditions/getTermsAndConditionsForAppType
///   ?appType=customer&appPolicyType=PRIVACYPOLICY | TERMSANDCONDITIONS
///
/// Response shape:
/// {
///   "terms_and_conditions_id": 1,
///   "app_type": "customer",
///   "content": "\n{\n  \"termsAndConditions\": \"<p>...</p>\"\n}\n"
/// }
///
/// The [content] field is itself a JSON string; the HTML lives inside its
/// `termsAndConditions` key.
class TermsApiService {
  static const String appTypeCustomer = 'customer';
  static const String policyTypePrivacy = 'PRIVACYPOLICY';
  static const String policyTypeTerms = 'TERMSANDCONDITIONS';

  static Future<String> getContent({
    required String appType,
    required String appPolicyType,
  }) async {
    try {
      final uri = Uri.parse(
        'http://192.168.0.14:8084/api/fm/terms-and-conditions/'
        'getTermsAndConditionsForAppType'
        '?appType=$appType&appPolicyType=$appPolicyType',
      );

      final response = await http
          .get(uri, headers: await getHeaders())
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return '';

      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return '';
      }
      if (decoded is! Map) return '';

      // Handle both a direct object and a { success: true, data: {...} } envelope.
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      dynamic body = map['data'];
      if (body is! Map) body = map;
      if (body is! Map<String, dynamic>) return '';

      final raw = body['content']?.toString() ?? '';
      final content = raw.trim();
      if (content.isEmpty) return '';

      // `content` is a JSON string like {"termsAndConditions": "<html>"}.
      try {
        final inner = jsonDecode(content);
        if (inner is Map) {
          final innerMap = Map<String, dynamic>.from(inner);
          final html =
              innerMap['termsAndConditions']?.toString() ??
              innerMap['terms_and_conditions']?.toString();
          if (html != null && html.trim().isNotEmpty) {
            return html;
          }
        }
      } catch (_) {
        // Not JSON → plain-text content, return it as-is.
      }

      return content;
    } catch (e) {
      debugPrint('[TERMS_API] getContent error: $e');
      return '';
    }
  }
}
