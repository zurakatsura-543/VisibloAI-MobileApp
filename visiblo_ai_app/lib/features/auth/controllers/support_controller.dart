import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/services/local_auth_service.dart';
import '../models/support_models.dart';
import '../models/test_account.dart';

class SupportController extends GetxController {
  SupportController({LocalAuthService? localAuthService})
    : _localAuthService = localAuthService ?? Get.find<LocalAuthService>();

  final LocalAuthService _localAuthService;

  final searchController = TextEditingController();
  final query = ''.obs;
  final isLaunching = false.obs;
  final errorMessage = RxnString();
  final infoMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(() {
      final value = searchController.text;
      if (query.value != value) {
        query.value = value;
      }
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  static const supportEmail = 'support@visibloai.com';

  bool get isPlanActivationRequest {
    final arguments = Get.arguments;
    return arguments is Map && arguments['topic'] == 'plan_activation';
  }

  final categories = const <SupportCategory>[
    SupportCategory(
      id: 'getting-started',
      title: 'Getting Started',
      description:
          'Learn the basics of using the dashboard and activating a workspace.',
      icon: Icons.menu_book_rounded,
    ),
    SupportCategory(
      id: 'gbp',
      title: 'GBP Management',
      description:
          'Managing your Google Business Profile, locations, posts, and photos.',
      icon: Icons.storefront_outlined,
    ),
    SupportCategory(
      id: 'reviews',
      title: 'Review Management',
      description: 'Handling reviews, responses, and review-poster campaigns.',
      icon: Icons.reviews_outlined,
    ),
    SupportCategory(
      id: 'seo',
      title: 'SEO & Rankings',
      description:
          'Improving local visibility with audit, keywords, citations, and reports.',
      icon: Icons.search_rounded,
    ),
  ];

  final articles = const <SupportArticle>[
    SupportArticle(
      id: 'connect-gbp',
      categoryId: 'getting-started',
      title: 'How to connect your Google Business Profile',
      summary:
          'Complete Google authentication, confirm your business location, and unlock live sync.',
      highlights: [
        'Open the Google connect flow from onboarding or GBP Manager.',
        'Finish Google authentication in the browser and return to the app.',
        'Choose the correct business location so reviews, posts, and reports map to the right profile.',
      ],
      relatedRoute: AppRoutes.gbpManager,
      relatedActionLabel: 'Open GBP Manager',
    ),
    SupportArticle(
      id: 'manage-locations',
      categoryId: 'getting-started',
      title: 'Managing multiple locations',
      summary:
          'Switch and maintain several business profiles under one workspace.',
      highlights: [
        'Use GBP Manager to verify locations and keep profile details current.',
        'Website, citations, and review-poster tools all depend on the active location data.',
        'Check plan limits in Settings if you need more connected profiles.',
      ],
      relatedRoute: AppRoutes.account,
      relatedActionLabel: 'Open Settings',
    ),
    SupportArticle(
      id: 'automated-reports',
      categoryId: 'getting-started',
      title: 'Setting up automated reports',
      summary:
          'Review trend windows, insights, and performance signals after your location is connected.',
      highlights: [
        'Reports become meaningful after GBP and website data start syncing.',
        'Use the date range tools to compare recent activity with longer windows.',
        'Watch alert and audit modules for follow-up actions after each reporting cycle.',
      ],
      relatedRoute: AppRoutes.reports,
      relatedActionLabel: 'Open Reports',
    ),
    SupportArticle(
      id: 'gbp-basics',
      categoryId: 'gbp',
      title: 'Managing your Google Business Profile',
      summary:
          'Keep profile details, verification, and review sync healthy from one place.',
      highlights: [
        'Use GBP Manager to verify locations, refresh data, and remove stale entries.',
        'Sync reviews to bring the latest customer feedback into the app.',
        'Check Alerts for profile issues that need attention.',
      ],
      relatedRoute: AppRoutes.gbpManager,
      relatedActionLabel: 'Open GBP Manager',
    ),
    SupportArticle(
      id: 'publish-posts',
      categoryId: 'gbp',
      title: 'Publishing posts, offers, and events',
      summary:
          'Use the content modules to keep your business profile fresh and active.',
      highlights: [
        'Create standard posts, offers, or events from the content section.',
        'Review the final copy before publishing to the connected location.',
        'Track performance later in Reports and Audit modules.',
      ],
      relatedRoute: AppRoutes.gbpPosts,
      relatedActionLabel: 'Open Content',
    ),
    SupportArticle(
      id: 'photos-guidance',
      categoryId: 'gbp',
      title: 'Uploading and managing photos',
      summary:
          'Organize your visual profile so new customers see accurate and recent imagery.',
      highlights: [
        'Use the Photos module to keep brand visuals current.',
        'Prefer clear storefront, interior, product, and team photos.',
        'Match profile photos with the same business identity used in Settings and Website Manager.',
      ],
      relatedRoute: AppRoutes.gbpPhotos,
      relatedActionLabel: 'Open Photos',
    ),
    SupportArticle(
      id: 'review-replies',
      categoryId: 'reviews',
      title: 'Best practices for responding to reviews',
      summary:
          'Reply quickly, stay specific, and use the response tools to keep tone consistent.',
      highlights: [
        'Respond to recent reviews first, especially lower ratings or unanswered feedback.',
        'Reference the customer experience without copying generic templates.',
        'Use the Reviews module to keep response coverage visible.',
      ],
      relatedRoute: AppRoutes.clientReviews,
      relatedActionLabel: 'Open Reviews',
    ),
    SupportArticle(
      id: 'review-poster-help',
      categoryId: 'reviews',
      title: 'Generating review posters for in-store sharing',
      summary:
          'Create QR posters tied to the correct location and export them for print or sharing.',
      highlights: [
        'Choose the correct business location before creating a poster.',
        'Confirm the live review URL resolves before exporting or sharing the poster.',
        'Use print-ready templates that match the business identity in Settings.',
      ],
      relatedRoute: AppRoutes.reviewPoster,
      relatedActionLabel: 'Open Review Poster',
    ),
    SupportArticle(
      id: 'seo-score',
      categoryId: 'seo',
      title: 'Understanding your SEO score',
      summary:
          'Use Audit and Alerts together to see why rankings or local visibility need attention.',
      highlights: [
        'Audit surfaces the biggest optimization gaps across profile quality and SEO readiness.',
        'Alerts highlight the issues that changed recently and should be addressed first.',
        'Reports help validate whether those fixes improved performance over time.',
      ],
      relatedRoute: AppRoutes.audit,
      relatedActionLabel: 'Open Audit',
    ),
    SupportArticle(
      id: 'keyword-tracking',
      categoryId: 'seo',
      title: 'Tracking local keyword performance',
      summary:
          'Monitor target keywords and compare ranking movement over time.',
      highlights: [
        'Check keyword ranking trends after making GBP or website updates.',
        'Use reports for broader context when rankings or traffic shift.',
        'Pair keyword tracking with citation and website health work for better results.',
      ],
      relatedRoute: AppRoutes.keywordRanking,
      relatedActionLabel: 'Open Keyword Ranking',
    ),
    SupportArticle(
      id: 'citations-basics',
      categoryId: 'seo',
      title: 'Keeping citations and business listings accurate',
      summary:
          'Use the citations workspace to keep NAP data and directory listings aligned.',
      highlights: [
        'Run scans to compare live directory data with the business profile.',
        'Prioritize mismatched phone, address, or website entries.',
        'Track submission and status changes as directories are updated.',
      ],
      relatedRoute: AppRoutes.citations,
      relatedActionLabel: 'Open Citations',
    ),
  ];

  final tutorials = const <SupportTutorial>[
    SupportTutorial(
      id: 'tutorial-connect-gbp',
      title: 'Connect your GBP in minutes',
      description:
          'Short walkthrough for authentication, callback, and location activation.',
      durationLabel: '3 min',
      steps: [
        'Open GBP Manager or the onboarding Google connect flow.',
        'Finish Google authentication and return to the app.',
        'Verify the connected location and refresh the profile.',
      ],
      relatedRoute: AppRoutes.gbpManager,
      relatedActionLabel: 'Open GBP Manager',
    ),
    SupportTutorial(
      id: 'tutorial-review-poster',
      title: 'Create a review-poster campaign',
      description:
          'Generate a live QR poster and share it with your team or customers.',
      durationLabel: '4 min',
      steps: [
        'Select the correct location in Review Poster.',
        'Confirm the resolved review link is correct.',
        'Pick a template, then export or share the poster.',
      ],
      relatedRoute: AppRoutes.reviewPoster,
      relatedActionLabel: 'Open Review Poster',
    ),
    SupportTutorial(
      id: 'tutorial-seo-audit',
      title: 'Turn audit insights into action',
      description:
          'Use Audit, Alerts, and Keyword Ranking together for a faster fix loop.',
      durationLabel: '5 min',
      steps: [
        'Review your current audit score and priority modules.',
        'Check alerts for the most recent changes or regressions.',
        'Track ranking movement after completing fixes.',
      ],
      relatedRoute: AppRoutes.audit,
      relatedActionLabel: 'Open Audit',
    ),
  ];

  final resources = const <SupportResourceLink>[
    SupportResourceLink(
      title: 'API Documentation',
      subtitle: 'Open the published API host used by the app.',
      url: 'https://app.visibloai.com/api',
    ),
    SupportResourceLink(
      title: 'Developer Portal',
      subtitle: 'Open the Visiblo application workspace in the browser.',
      url: 'https://app.visibloai.com',
    ),
    SupportResourceLink(
      title: 'Status Page',
      subtitle:
          'Open the main Visiblo website for service and company details.',
      url: 'https://www.visibloai.com',
    ),
  ];

  TestAccount? get currentUser => _localAuthService.currentUser.value;

  String get businessName {
    final user = currentUser;
    if (user == null) {
      return 'your workspace';
    }

    final businessName = user.businessName.trim();
    if (businessName.isNotEmpty) {
      return businessName;
    }

    final categoryTitle = user.categoryTitle.trim();
    if (categoryTitle.isNotEmpty) {
      return categoryTitle;
    }

    return 'your workspace';
  }

  String get ownerName {
    final user = currentUser;
    if (user == null) {
      return 'there';
    }

    final fullName = user.fullName.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    return 'there';
  }

  String get normalizedQuery => query.value.trim().toLowerCase();

  List<SupportCategory> get filteredCategories {
    final term = normalizedQuery;
    if (term.isEmpty) {
      return categories;
    }

    return categories
        .where((category) {
          final categoryMatches =
              category.title.toLowerCase().contains(term) ||
              category.description.toLowerCase().contains(term);
          if (categoryMatches) {
            return true;
          }

          return articles.any(
            (article) =>
                article.categoryId == category.id &&
                _articleMatches(article, term),
          );
        })
        .toList(growable: false);
  }

  List<SupportArticle> get searchResults {
    final term = normalizedQuery;
    if (term.isEmpty) {
      return popularArticles;
    }

    return articles
        .where((article) => _articleMatches(article, term))
        .toList(growable: false);
  }

  List<SupportArticle> get popularArticles {
    const titles = <String>[
      'How to connect your Google Business Profile',
      'Understanding your SEO score',
      'Best practices for responding to reviews',
      'Setting up automated reports',
      'Managing multiple locations',
    ];

    return titles
        .map(
          (title) => articles.firstWhere(
            (article) => article.title == title,
            orElse: () => articles.first,
          ),
        )
        .toList(growable: false);
  }

  int articleCountFor(String categoryId) {
    return articles.where((article) => article.categoryId == categoryId).length;
  }

  void setQuery(String value) {
    query.value = value;
  }

  void clearQuery() {
    searchController.clear();
    query.value = '';
  }

  void clearError() {
    errorMessage.value = null;
  }

  void clearInfo() {
    infoMessage.value = null;
  }

  Future<void> startLiveChat() async {
    await _openMailSupport(
      subject: 'Live chat request for $businessName',
      body: [
        'Hi Visiblo team,',
        '',
        'I would like live support for $businessName.',
        '',
        'Workspace owner: $ownerName',
        'Registered email: ${currentUser?.email.trim() ?? ''}',
        '',
        'Issue or question:',
      ].join('\n'),
      successMessage:
          'Live support opens through your default mail app in this build.',
      fallbackMessage: 'Unable to open the support mail app right now.',
    );
  }

  Future<void> submitTicket() async {
    final activationRequest = isPlanActivationRequest;
    await _openMailSupport(
      subject: activationRequest
          ? 'Plan activation request for $businessName'
          : 'Support ticket for $businessName',
      body: [
        'Hi Visiblo support,',
        '',
        activationRequest
            ? 'I would like help activating a plan for $businessName.'
            : 'I need help with $businessName.',
        '',
        'Workspace owner: $ownerName',
        'Registered email: ${currentUser?.email.trim() ?? ''}',
        '',
        activationRequest
            ? 'Please contact me with the next steps.'
            : 'Please describe the issue:',
      ].join('\n'),
      successMessage: activationRequest
          ? 'Plan activation request opened in your mail app.'
          : 'Support ticket draft opened in your mail app.',
      fallbackMessage: 'Unable to open the support ticket flow right now.',
    );
  }

  Future<void> openResource(SupportResourceLink resource) async {
    await _openExternalUrl(
      resource.url,
      fallbackMessage: 'Unable to open ${resource.title} right now.',
    );
  }

  void openRoute(String route) {
    errorMessage.value = null;
    infoMessage.value = null;
    if (Get.currentRoute == route) {
      return;
    }
    Get.toNamed(route);
  }

  bool _articleMatches(SupportArticle article, String term) {
    if (article.title.toLowerCase().contains(term) ||
        article.summary.toLowerCase().contains(term)) {
      return true;
    }

    return article.highlights.any(
      (highlight) => highlight.toLowerCase().contains(term),
    );
  }

  Future<void> _openMailSupport({
    required String subject,
    required String body,
    required String successMessage,
    required String fallbackMessage,
  }) async {
    if (isLaunching.value) {
      return;
    }

    isLaunching.value = true;
    errorMessage.value = null;

    try {
      final mailUri = Uri(
        scheme: 'mailto',
        path: supportEmail,
        queryParameters: <String, String>{'subject': subject, 'body': body},
      );
      final launched = await launchUrl(
        mailUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception(fallbackMessage);
      }
      infoMessage.value = successMessage;
    } catch (error) {
      errorMessage.value = _humanizeError(error, fallback: fallbackMessage);
    } finally {
      isLaunching.value = false;
    }
  }

  Future<void> _openExternalUrl(
    String url, {
    required String fallbackMessage,
  }) async {
    if (isLaunching.value) {
      return;
    }

    isLaunching.value = true;
    errorMessage.value = null;

    try {
      final parsedUrl = Uri.parse(url);
      final launched = await launchUrl(
        parsedUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception(fallbackMessage);
      }
      infoMessage.value = null;
    } catch (error) {
      errorMessage.value = _humanizeError(error, fallback: fallbackMessage);
    } finally {
      isLaunching.value = false;
    }
  }

  String _humanizeError(Object error, {required String fallback}) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return fallback;
    }
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
