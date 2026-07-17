import 'package:get/get.dart';

import '../../features/auth/views/audit_view.dart';
import '../../features/auth/views/audit_module_detail_views.dart';
import '../../features/auth/views/alert_center_view.dart';
import '../../features/auth/bindings/alert_center_binding.dart';
import '../../features/auth/bindings/account_settings_binding.dart';
import '../../features/auth/bindings/citation_manager_binding.dart';
import '../../features/auth/bindings/gbp_manager_binding.dart';
import '../../features/auth/bindings/payment_binding.dart';
import '../../features/auth/bindings/review_poster_binding.dart';
import '../../features/auth/bindings/support_binding.dart';
import '../../features/auth/views/client_reviews_view.dart';
import '../../features/auth/views/citation_view.dart';
import '../../features/auth/views/dashboard_view.dart';
import '../../features/auth/views/gbp_events_view.dart';
import '../../features/auth/views/gbp_manager_view.dart';
import '../../features/auth/views/gbp_offers_view.dart';
import '../../features/auth/views/gbp_photos_view.dart';
import '../../features/auth/views/lead_detail_view.dart';
import '../../features/auth/views/leads_pipeline_view.dart';
import '../../features/auth/views/home_overview_view.dart';
import '../../features/auth/views/keyword_ranking_view.dart';
import '../../features/auth/controllers/seo_tools_controller.dart';
import '../../features/auth/views/account_detail_views.dart';
import '../../features/auth/bindings/website_manager_binding.dart';
import '../../features/auth/views/payment_view.dart';
import '../../features/auth/views/profile_view.dart';
import '../../features/auth/views/review_poster_view.dart';
import '../../features/auth/views/reports_view.dart';
import '../../features/auth/views/support_view.dart';
import '../../features/auth/views/website_manager_view.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/onboarding/views/business_location_view.dart';
import '../../features/onboarding/views/business_profile_view.dart';
import '../../features/onboarding/views/category_view.dart';
import '../../features/onboarding/views/custom_category_view.dart';
import '../../features/onboarding/views/forgot_password_view.dart';
import '../../features/onboarding/views/auth_boot_view.dart';
import '../../features/onboarding/views/google_connect_view.dart';
import '../../features/onboarding/views/google_oauth_webview_view.dart';
import '../../features/onboarding/views/login_view.dart';
import '../../features/onboarding/views/legal_document_view.dart';
import '../../features/onboarding/views/location_selection_view.dart';
import '../../features/onboarding/views/onboarding_survey_view.dart';
import '../../features/onboarding/views/otp_verification_view.dart';
import '../../features/onboarding/views/signup_view.dart';
import '../../features/onboarding/views/welcome_view.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.boot,
      page: () => const AuthBootView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.welcome,
      page: () => const WelcomeView(),
      binding: OnboardingBinding(),
    ),
    GetPage(name: AppRoutes.terms, page: () => const LegalDocumentView.terms()),
    GetPage(
      name: AppRoutes.privacyPolicy,
      page: () => const LegalDocumentView.privacyPolicy(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.signUp,
      page: () => const SignUpView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.googleOAuth,
      page: () => const GoogleOAuthWebViewView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.onboardingSurvey,
      page: () => const OnboardingSurveyView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.googleConnect,
      page: () => const GoogleConnectView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.locationSelection,
      page: () => const LocationSelectionView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.businessProfile,
      page: () => const BusinessProfileView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.businessLocation,
      page: () => const BusinessLocationView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.category,
      page: () => const CategoryView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.customCategory,
      page: () => const CustomCategoryView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const HomeOverviewView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.gbpPosts,
      page: () => const DashboardView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.gbpOffers,
      page: () => const GbpOffersView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.gbpPhotos,
      page: () => const GbpPhotosView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.gbpEvents,
      page: () => const GbpEventsView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.leadsPipeline,
      page: () => const LeadsPipelineView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.leadDetail,
      page: () => const LeadDetailView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.gbpManager,
      page: () => const GbpManagerView(),
      binding: GbpManagerBinding(),
    ),
    GetPage(
      name: AppRoutes.websiteManager,
      page: () => const WebsiteManagerView(),
      binding: WebsiteManagerBinding(),
    ),
    GetPage(
      name: AppRoutes.audit,
      page: () => const AuditView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.auditCategory,
      page: () => const AuditCategoryModuleView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.auditHours,
      page: () => const AuditHoursModuleView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.auditReviews,
      page: () => const AuditReviewModuleView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportsView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.alerts,
      page: () => const AlertCenterView(),
      binding: AlertCenterBinding(),
    ),
    GetPage(
      name: AppRoutes.payment,
      page: () => const PaymentView(),
      binding: PaymentBinding(),
    ),
    GetPage(
      name: AppRoutes.account,
      page: () => const AccountView(),
      binding: AccountSettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.accountBusinessProfile,
      page: () => const AccountBusinessProfileDetailView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.accountPackageBilling,
      page: () => const AccountGrowthPackageView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.accountGoogleBusinessProfile,
      page: () => const AccountGoogleBusinessProfileView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.accountWorkspaceHealth,
      page: () => const AccountWorkspaceHealthView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.accountWorkspaceHealthChecklist,
      page: () => const AccountWorkspaceHealthChecklistView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.clientReviews,
      page: () => const ClientReviewsView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.reviewPoster,
      page: () => const ReviewPosterView(),
      binding: ReviewPosterBinding(),
    ),
    GetPage(
      name: AppRoutes.keywordRanking,
      page: () => const KeywordRankingView(
        initialTab: SeoMobileTab.keywords,
      ),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.seoCompetitors,
      page: () => const KeywordRankingView(
        initialTab: SeoMobileTab.competitors,
      ),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.seoHeatmap,
      page: () => const KeywordRankingView(
        initialTab: SeoMobileTab.heatmap,
      ),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.citations,
      page: () => const CitationView(),
      binding: CitationManagerBinding(),
    ),
    GetPage(
      name: AppRoutes.support,
      page: () => const SupportView(),
      binding: SupportBinding(),
    ),
  ];
}
