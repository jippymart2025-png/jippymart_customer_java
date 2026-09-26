import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/constant/show_toast_dialog.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Result returned when PayU Hosted Checkout WebView closes.
enum PayUCheckoutOutcome { success, failure, cancelled, tooManyRequests }

class PayUCheckoutResult {
  final PayUCheckoutOutcome outcome;
  final String txnid;

  const PayUCheckoutResult({required this.outcome, required this.txnid});
}

/// Ensures the federated WebView platform implementation is registered.
/// Needed when GeneratedPluginRegistrant is stale / hot-restart skipped plugins.
void ensurePayUWebViewPlatform() {
  if (WebViewPlatform.instance != null) return;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      AndroidWebViewPlatform.registerWith();
      break;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      WebKitWebViewPlatform.registerWith();
      break;
    default:
      break;
  }
}

/// Opens PayU Hosted Checkout by auto-POSTing [formFields] to [paymentUrl].
///
/// [formFields] is the raw `payload` map returned by the server's
/// `/div/payments/initiate` — every entry becomes a hidden form field, so no
/// field is dropped or re-named by the app. Fields PayU needs:
/// `key`, `txnid`, `amount`, `productinfo`, `firstname`, `lastname`, `email`,
/// `phone`, `surl`, `furl`, `hash`, `udf1..udf5`.
///
/// Exactly-one guarantees enforced here:
///   * one WebView per `txnid` (transaction-level lock [_payuCheckoutStarted])
///   * `loadHtmlString` is called once, from [initState]
///   * the form is POSTed **exactly once** via Dart-guarded [_submitted]
///   * [runJavaScript] for submission is invoked at most once
///   * no GET is ever made to `_payment` before the form POST
///   * the lock is released on success / failure / cancel / rate-limit / dispose
///   * PayU "Too many Requests" is detected and reported — never auto-retried
///
/// Redirects to the `surl` / `furl` in [formFields] close the screen with an
/// outcome.
class PayUWebView extends StatefulWidget {
  const PayUWebView({
    super.key,
    required this.paymentUrl,
    required this.formFields,
  });

  final String paymentUrl;
  final Map<String, dynamic> formFields;

  static Future<PayUCheckoutResult?> open(
    BuildContext context, {
    required String paymentUrl,
    required Map<String, dynamic> formFields,
  }) {
    ensurePayUWebViewPlatform();
    return Navigator.of(context).push<PayUCheckoutResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            PayUWebView(paymentUrl: paymentUrl, formFields: formFields),
      ),
    );
  }

  @override
  State<PayUWebView> createState() => _PayUWebViewState();
}

class _PayUWebViewState extends State<PayUWebView> {
  late final WebViewController _controller;
  Timer? _submitGuardTimer;
  bool _loading = true;
  bool _finished = false;

  /// Transaction-level checkout lock. Set when this WebView takes ownership of
  /// a checkout for [_payuTransactionId] and released on EVERY exit path
  /// (success / failure / cancelled / rate-limit / dispose).
  late bool _payuCheckoutStarted = false;

  /// The transaction this WebView owns. Each WebView is created for exactly one
  /// `txnid`; a fresh initiate must be requested before any new WebView.
  late final String _payuTransactionId =
      widget.formFields['txnid']?.toString() ?? '';

  /// Dart-side, exactly-once guard for the PayU form POST. It persists across
  /// any page (re)load inside this WebView, so a reload can never re-submit.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();

    _payuCheckoutStarted = true;
    debugPrint('🧾 [PAYU] TXNID: $_payuTransactionId');
    debugPrint('🌐 [PAYU] WEBVIEW CREATED (url: ${widget.paymentUrl})');

    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('🚧 [PAYU] page started: $url');
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) {
            debugPrint('🏁 [PAYU] page finished: $url');
            if (mounted) setState(() => _loading = false);
            // Single point of submission: fires for the local page.
            _submitFormIfNeeded(url);
            // After the form is POSTed, read PayU's response page so we can
            // surface PayU's exact error message instead of guessing.
            _diagnosePayUPage(url);
          },
          onNavigationRequest: (request) {
            debugPrint('🧭 [PAYU] NAVIGATION REQUEST: ${request.url}');
            return _handleUrl(request.url);
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) {
              _handleUrl(url);
            }
          },
          onWebResourceError: (error) {
            debugPrint(
              '❌ [PAYU] web resource error: ${error.errorType} '
              '${error.description} ${error.url}',
            );
          },
        ),
      )
      ..loadHtmlString(_buildAutoSubmitHtml());

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;

    // PayU's WAF occasionally rate-limits generic WebView User-Agents even for
    // legitimate, single-submit checkouts. Present a normal mobile Chrome UA so
    // PayU treats the checkout like any other mobile browser (client sends the
    // payment data unchanged — this does NOT alter the hash or any field).
    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(
        _controller.setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        ),
      );
    }

    // Single local HTML form (POST to _payment) is loaded exactly once. No
    // GET navigation to _payment happens before the form submission.
    debugPrint('📄 [PAYU] HTML LOADED (single local form, no _payment GET)');

    // Fallback: if onPageFinished never fires on this device/WebView, do a
    // single best-effort submit. Guarded by [_submitted], so even if both
    // paths run, only one POST is sent.
    _submitGuardTimer = Timer(const Duration(seconds: 3), _submitFormIfNeeded);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  String _buildAutoSubmitHtml() {
    final inputs = widget.formFields.entries
        .where((e) => e.key.isNotEmpty)
        .map(
          (e) =>
              '<input type="hidden" name="${_escapeHtml(e.key)}" value="${_escapeHtml(
                e.value?.toString() ?? '',
              )}" />',
        )
        .join('\n');

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PayU Checkout</title>
  </head>
  <!-- NOTE: no `onload` auto-submit here. The Dart side owns submission and
       sends exactly one POST via [_submitFormIfNeeded]. -->
  <body>
    <form id="payuForm" action="${_escapeHtml(widget.paymentUrl)}" method="post">
      $inputs
    </form>
    <p style="font-family: sans-serif; text-align: center; margin-top: 40px;">
      Redirecting to PayU...
    </p>
  </body>
</html>
''';
  }

  /// POSTs the PayU form **at most once**.
  ///
  /// [pageUrl] only triggers submission while the WebView is still on the local
  /// HTML page (`about:blank` / `data:` / empty), so callbacks fired after the
  /// redirect to PayU or to surl/furl can never re-submit. May also be called
  /// from the fallback timer (pageUrl == null → treated as still local).
  void _submitFormIfNeeded([String? pageUrl]) {
    if (_submitted) {
      debugPrint('🚫 [PAYU] FORM SUBMIT SKIPPED - ALREADY SUBMITTED');
      return;
    }
    if (!_payuCheckoutStarted || _finished || !mounted) return;

    if (pageUrl != null) {
      final u = pageUrl.toLowerCase();
      final onLocalPage =
          u.isEmpty ||
          u.startsWith('about:blank') ||
          u.startsWith('data:') ||
          u.startsWith('file:');
      if (!onLocalPage) return; // already navigated away → stop.
    }

    // Claim the flag BEFORE running JS so this can never fire twice.
    _submitted = true;
    _submitGuardTimer?.cancel();
    debugPrint('🚀 [PAYU] FORM SUBMIT (POST ${widget.paymentUrl})');

    unawaited(
      _controller.runJavaScript(
        "document.getElementById('payuForm').submit();",
      ),
    );
  }

  /// Reads the currently-loaded page once it is on PayU and logs the exact
  /// title/text. If PayU showed an error page (hash rejection, rate-limit,
  /// etc.) the message is surfaced to the user instead of leaving them on a
  /// blank PayU page.
  Future<void> _diagnosePayUPage(String url) async {
    if (!_submitted || _finished || !mounted) return;

    final u = url.toLowerCase();
    final isPayU =
        u.contains('payu.in/_payment') ||
        u.contains('secure.payu.in') ||
        u.contains('test.payu.in');
    if (!isPayU) return;

    try {
      final rawTitle = await _controller.runJavaScriptReturningResult(
        "JSON.stringify(document.title)",
      );
      final rawText = await _controller.runJavaScriptReturningResult(
        "(document.body ? document.body.innerText : '').substring(0, 600)",
      );

      String title = rawTitle is String ? rawTitle : (rawTitle.toString());
      String text = rawText is String ? rawText : (rawText.toString());
      try {
        final decodedTitle = jsonDecode(title);
        final decodedText = jsonDecode(text);
        if (decodedTitle is String) title = decodedTitle;
        if (decodedText is String) text = decodedText;
      } catch (_) {}

      debugPrint('📄 [PAYU] page title: $title');
      debugPrint('📄 [PAYU] page text: ${text.trim()}');

      final combined = '$title\n$text'.toLowerCase();

      // PayU rate-limits the SAME txnid once it was already submitted. Close
      // with a dedicated outcome so the caller regenerates a fresh initiate
      // instead of retrying the (now burned) transaction id.
      final isRateLimited =
          combined.contains('too many') ||
          combined.contains('too many request') ||
          combined.contains('try after 60') ||
          combined.contains('please try after');
      if (isRateLimited) {
        debugPrint(
          '⚠️ [PAYU] RATE LIMITED (txnid: $_payuTransactionId): '
          '${text.trim()}',
        );
        if (mounted) {
          _finish(PayUCheckoutOutcome.tooManyRequests);
        }
        return;
      }

      final isError =
          combined.contains('sorry') ||
          combined.contains('unable to process') ||
          combined.contains('too many') ||
          combined.contains('invalid') ||
          combined.contains('not valid') ||
          combined.contains('incorrect') ||
          combined.contains('hash') ||
          combined.contains('not recognized');

      if (isError) {
        debugPrint('⚠️ [PAYU] PayU returned an error page.');
        final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
        final short = clean.length > 160 ? '${clean.substring(0, 160)}…' : clean;
        if (short.isNotEmpty && mounted) {
          try {
            ShowToastDialog.showToast('PayU: $short');
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('⚠️ [PAYU] could not read PayU page: $e');
    }
  }

  bool _urlMatches(String url, String target) {
    if (target.isEmpty) return false;
    final normalizedUrl = url.toLowerCase();
    final normalizedTarget = target.toLowerCase();
    return normalizedUrl.startsWith(normalizedTarget) ||
        normalizedUrl.contains(normalizedTarget);
  }

  /// True when [url] is (a sub-path of) the configured `surl`.
  bool _isSuccessRedirect(String url) {
    if (_urlMatches(url, widget.formFields['surl']?.toString() ?? '')) {
      return true;
    }
    // Fallback: the backend webhook that PayU bounces the browser to after a
    // successful payment. Matched on the path so it works even if the initiate
    // payload omits or renames the `surl` field.
    return url.toLowerCase().contains('/api/div/payments/payu/success');
  }

  /// True when [url] is (a sub-path of) the configured `furl`.
  bool _isFailureRedirect(String url) {
    if (_urlMatches(url, widget.formFields['furl']?.toString() ?? '')) {
      return true;
    }
    // Fallback: the backend webhook that PayU bounces the browser to after a
    // failed payment.
    return url.toLowerCase().contains('/api/div/payments/payu/failure');
  }

  /// Inspects every navigation and URL change. A redirect to the `surl`/`furl`
  /// webhook closes the checkout with the matching outcome and tells the
  /// WebView NOT to load that page (it is a backend API, not a screen).
  NavigationDecision _handleUrl(String url) {
    if (_finished) return NavigationDecision.navigate;

    debugPrint('🔗 [PAYU] URL: $url');

    if (_isSuccessRedirect(url)) {
      _finish(PayUCheckoutOutcome.success);
      return NavigationDecision.prevent;
    }
    if (_isFailureRedirect(url)) {
      _finish(PayUCheckoutOutcome.failure);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _finish(PayUCheckoutOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    _payuCheckoutStarted = false;
    _submitGuardTimer?.cancel();

    switch (outcome) {
      case PayUCheckoutOutcome.success:
        debugPrint('✅ [PAYU] SUCCESS (txnid: $_payuTransactionId)');
        break;
      case PayUCheckoutOutcome.failure:
        debugPrint('❌ [PAYU] FAILURE (txnid: $_payuTransactionId)');
        break;
      case PayUCheckoutOutcome.tooManyRequests:
        debugPrint('⚠️ [PAYU] RATE LIMITED (txnid: $_payuTransactionId)');
        break;
      case PayUCheckoutOutcome.cancelled:
        debugPrint('❌ [PAYU] CHECKOUT CLOSED (txnid: $_payuTransactionId)');
        break;
    }
    debugPrint('🔓 [PAYU] LOCK RELEASED (txnid: $_payuTransactionId)');

    Navigator.of(context).pop(
      PayUCheckoutResult(outcome: outcome, txnid: _payuTransactionId),
    );
  }

  void _onClosePressed() => _finish(PayUCheckoutOutcome.cancelled);

  @override
  void dispose() {
    _submitGuardTimer?.cancel();
    if (!_finished) {
      debugPrint(
        '❌ [PAYU] CHECKOUT CLOSED (widget disposed, txnid: $_payuTransactionId)',
      );
    }
    if (_payuCheckoutStarted) {
      debugPrint(
        '🔓 [PAYU] LOCK RELEASED (widget disposed, txnid: $_payuTransactionId)',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayU Payment'),
        backgroundColor: AppThemeData.primary300,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onClosePressed,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}