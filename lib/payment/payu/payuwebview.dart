import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'model/payupayload.dart';

/// Result returned when PayU Hosted Checkout WebView closes.
enum PayUCheckoutOutcome { success, failure, cancelled }

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

/// Opens PayU Hosted Checkout by auto-POSTing [payload] to [paymentUrl].
/// Detects redirect to [payload.surl] / [payload.furl] and pops with outcome.
class PayUWebView extends StatefulWidget {
  const PayUWebView({
    super.key,
    required this.paymentUrl,
    required this.payload,
  });

  final String paymentUrl;
  final PayUPayload payload;

  static Future<PayUCheckoutResult?> open(BuildContext context, {
    required String paymentUrl,
    required PayUPayload payload,
  }) {
    ensurePayUWebViewPlatform();
    return Navigator.of(context).push<PayUCheckoutResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PayUWebView(paymentUrl: paymentUrl, payload: payload),
      ),
    );
  }

  @override
  State<PayUWebView> createState() => _PayUWebViewState();
}

class _PayUWebViewState extends State<PayUWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    ensurePayUWebViewPlatform();

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
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            _handleUrl(request.url);
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _handleUrl(url);
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
    final fields = widget.payload.toFormData();
    final inputs = fields.entries
        .map(
          (e) =>
      '<input type="hidden" name="${_escapeHtml(e.key)}" value="${_escapeHtml(
          e.value)}" />',
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
  <body onload="document.getElementById('payuForm').submit();">
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

  bool _urlMatches(String url, String target) {
    if (target.isEmpty) return false;
    final normalizedUrl = url.toLowerCase();
    final normalizedTarget = target.toLowerCase();
    return normalizedUrl.startsWith(normalizedTarget) ||
        normalizedUrl.contains(normalizedTarget);
  }

  void _handleUrl(String url) {
    if (_finished) return;

    final surl = widget.payload.surl;
    final furl = widget.payload.furl;

    if (_urlMatches(url, surl)) {
      _finish(PayUCheckoutOutcome.success);
    } else if (_urlMatches(url, furl)) {
      _finish(PayUCheckoutOutcome.failure);
    }
  }

  void _finish(PayUCheckoutOutcome outcome) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(
      context,
    ).pop(PayUCheckoutResult(outcome: outcome, txnid: widget.payload.txnid));
  }

  void _onClosePressed() {
    if (_finished) return;
    _finished = true;
    Navigator.of(context).pop(
      PayUCheckoutResult(
        outcome: PayUCheckoutOutcome.cancelled,
        txnid: widget.payload.txnid,
      ),
    );
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
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
