import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class LegalDocumentView extends StatefulWidget {
  const LegalDocumentView.terms({super.key})
    : title = 'Terms & Conditions',
      url = 'https://www.visibloai.com/terms';

  const LegalDocumentView.privacyPolicy({super.key})
    : title = 'Privacy Policy',
      url = 'https://www.visibloai.com/privacy-policy';

  final String title;
  final String url;

  @override
  State<LegalDocumentView> createState() => _LegalDocumentViewState();
}

class _LegalDocumentViewState extends State<LegalDocumentView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
              _progress = 0;
            });
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = error.description.isEmpty
                  ? 'The document could not be loaded right now.'
                  : error.description;
            });
          },
        ),
      );
    _loadPage();
  }

  Future<void> _loadPage() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      setState(() {
        _isLoading = false;
        _error = 'The document URL is invalid.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _progress = 0;
    });

    await _webViewController.loadRequest(uri);
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: Text(
          widget.title,
          style: AppTypography.button(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _webViewController)),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress == 0 || _progress >= 100
                    ? null
                    : _progress / 100,
                color: AppColors.primary,
                backgroundColor: const Color(0xFFDCE8F6),
              ),
            ),
          if (_error != null)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF7FAFD),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.public_off_rounded,
                      size: 40,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Unable to load ${widget.title}',
                      style: AppTypography.button(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: AppTypography.body(
                        fontSize: AppTypography.bodyTextCompact,
                        color: AppColors.mutedText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: _loadPage,
                          child: const Text('Retry'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: _openInBrowser,
                          child: const Text('Open in browser'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
