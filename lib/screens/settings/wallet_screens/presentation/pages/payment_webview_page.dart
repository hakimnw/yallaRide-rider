import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String title;
  final String initialUrl;

  const PaymentWebViewPage({
    super.key,
    required this.title,
    required this.initialUrl,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebViewPlatform.instance; // Ensure initialization

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            print('PaymentWebView: Page started loading: $url');
            if (mounted) setState(() => _isLoading = true);
            // _tryCloseIfTerminal(url);
          },
          onPageFinished: (url) {
            print('PaymentWebView: Page finished loading: $url');
            if (mounted) setState(() => _isLoading = false);
            // _tryCloseIfTerminal(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            print('PaymentWebView: Navigation requested to: ${request.url}');
            _tryCloseIfTerminal(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _tryCloseIfTerminal(String url) {
    // Check for payment success/failure indicators
    final lower = url.toLowerCase();
    bool shouldPop = false;
    String? result;

    // Check for success indicators
    if (lower.contains('success') || lower.contains('completed') || lower.contains('approved')) {
      shouldPop = true;
      result = 'success';
    }
    // Check for failure indicators
    else if (lower.contains('failed') || lower.contains('cancelled') || lower.contains('error')) {
      shouldPop = true;
      result = 'failed';
    }
    // Pop when navigating to the base domain URL (fallback)
    else {
      final target = 'https://yallahridg.com'.toLowerCase();
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final hasQueryOrFragment = (uri.query.isNotEmpty || uri.fragment.isNotEmpty);
        if (!hasQueryOrFragment) {
          final currentNoSlash = lower.endsWith('/') ? lower.substring(0, lower.length - 1) : lower;
          final targetNoSlash = target.endsWith('/') ? target.substring(0, target.length - 1) : target;
          if (currentNoSlash == targetNoSlash) {
            shouldPop = true;
            result = 'completed'; // Assume success if back to main site
          }
        }
      }
    }

    if (shouldPop && mounted) {
      Navigator.of(context).pop(result ?? 'unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: _isLoading
              ? LinearProgressIndicator(value: _progress == 100 ? null : _progress / 100)
              : const SizedBox(height: 3),
        ),
      ),
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
