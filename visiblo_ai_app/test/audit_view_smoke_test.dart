import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visiblo_ai_app/app/app.dart';
import 'package:visiblo_ai_app/app/services/local_auth_service.dart';
import 'package:visiblo_ai_app/features/auth/models/test_account.dart';
import 'package:visiblo_ai_app/features/auth/views/audit_view.dart';
import 'package:visiblo_ai_app/features/onboarding/controllers/onboarding_controller.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Get.putAsync<LocalAuthService>(() => LocalAuthService().init());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('audit view renders for a logged in user', (tester) async {
    final authService = Get.find<LocalAuthService>();
    authService.currentUser.value = const TestAccount(
      fullName: 'Lois Becket',
      email: 'lois@example.com',
      password: '123456',
      businessName: 'Zoneup Realty',
      industry: 'Clinic / Dentist',
      categoryTitle: 'Clinic / Dentist',
      categorySubtitle: 'Dental, Skin, Health',
      city: 'Mumbai',
      country: 'India',
      timeZone: 'Asia/Kolkata',
    );

    Get.put(OnboardingController(), permanent: true);

    await tester.pumpWidget(const GetMaterialApp(home: AuditView()));
    await tester.pumpAndSettle();

    expect(find.text('OPTIMIZATION MODULES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('audit tab navigation opens a working audit screen', (
    tester,
  ) async {
    final authService = Get.find<LocalAuthService>();
    authService.currentUser.value = const TestAccount(
      fullName: 'Lois Becket',
      email: 'lois@example.com',
      password: '123456',
      businessName: 'Zoneup Realty',
      industry: 'Clinic / Dentist',
      categoryTitle: 'Clinic / Dentist',
      categorySubtitle: 'Dental, Skin, Health',
      city: 'Mumbai',
      country: 'India',
      timeZone: 'Asia/Kolkata',
    );

    await tester.pumpWidget(const VisibloAiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Audit'));
    await tester.pumpAndSettle();

    expect(find.text('OPTIMIZATION MODULES'), findsOneWidget);
    expect(find.text('Fix the profile step by step'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
