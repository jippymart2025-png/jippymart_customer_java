import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

      return _extractHtml(content);
    } catch (e) {
      debugPrint('[TERMS_API] getContent error: $e');
      return '';
    }
  }

  /// Turns the API [content] field into renderable HTML.
  ///
  /// The backend returns content in a few shapes depending on the policy type:
  ///  * `{"termsAndConditions": "<p>..."}`  (JSON string wrapper)
  ///  * `{"privacyPolicy": "<p>..."}`        (same wrapper, different key)
  ///  * `"<p>..."`                           (plain HTML, possibly entity-escaped)
  ///
  /// Returns the extracted HTML with common entities decoded so the
  /// `flutter_html` widget renders the text (escaped markup like `&lt;p&gt;`)
  /// as real tags instead of showing raw characters.
  static String _extractHtml(String content) {
    String? html;

    try {
      final inner = jsonDecode(content);
      if (inner is Map) {
        html = _firstStringValue(Map<String, dynamic>.from(inner));
      }
    } catch (_) {
      // Not JSON → the whole content is HTML.
    }

    if (html == null || html.trim().isEmpty) {
      html = content;
    }

    return _decodeEntities(html.trim());
  }

  /// Returns the first non-empty string value of [map], preferring the
  /// HTML-bearing keys returned by the backend.
  static String? _firstStringValue(Map<String, dynamic> map) {
    const knownKeys = [
      'termsAndConditions',
      'terms_and_conditions',
      'privacyPolicy',
      'privacy_policy',
      'content',
      'html',
      'value',
      'text',
    ];
    for (final key in knownKeys) {
      final v = map[key];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    for (final v in map.values) {
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  /// Decodes common HTML entities so escaped markup becomes real markup.
  static String _decodeEntities(String input) {
    const namedEntities = <String, String>{
      '&nbsp;': '\u00a0',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&ldquo;': '\u201c',
      '&rdquo;': '\u201d',
      '&lsquo;': '\u2018',
      '&rsquo;': '\u2019',
      '&trade;': '\u2122',
      '&copy;': '\u00a9',
      '&reg;': '\u00ae',
      '&bull;': '\u2022',
      '&ndash;': '\u2013',
      '&mdash;': '\u2014',
      '&hellip;': '\u2026',
      '&times;': '\u00d7',
      '&divide;': '\u00f7',
      '&middot;': '\u00b7',
      '&deg;': '\u00b0',
      '&plusmn;': '\u00b1',
      '&sect;': '\u00a7',
      '&para;': '\u00b6',
      '&euro;': '\u20ac',
      '&pound;': '\u00a3',
      '&cent;': '\u00a2',
      '&yen;': '\u00a5',
      '&eacute;': '\u00e9',
      '&egrave;': '\u00e8',
      '&Eacute;': '\u00c9',
      '&agrave;': '\u00e0',
      '&Agrave;': '\u00c0',
      '&ccedil;': '\u00e7',
      '&Ccedil;': '\u00c7',
      '&oacute;': '\u00f3',
      '&Oacute;': '\u00d3',
      '&iacute;': '\u00ed',
      '&Iacute;': '\u00cd',
      '&uacute;': '\u00fa',
      '&Uacute;': '\u00da',
      '&ntilde;': '\u00f1',
      '&Ntilde;': '\u00d1',
      '&auml;': '\u00e4',
      '&ouml;': '\u00f6',
      '&uuml;': '\u00fc',
      '&szlig;': '\u00df',
      '&rarr;': '\u2192',
      '&larr;': '\u2190',
    };

    return input.replaceAllMapped(
      RegExp(r'&(#\d+|#x[0-9a-fA-F]+|[a-zA-Z]+);'),
      (match) {
        final whole = match.group(0)!;
        final code = match.group(1)!;
        if (code.startsWith('#')) {
          final numString =
              code.startsWith('#x')
                  ? code.substring(2)
                  : code.substring(1);
          final radix = code.startsWith('#x') ? 16 : 10;
          final value = int.tryParse(numString, radix: radix);
          if (value != null && value > 0 && value <= 0x10FFFF) {
            return String.fromCharCode(value);
          }
          return whole;
        }
        return namedEntities[whole] ?? whole;
      },
    );
  }
}
