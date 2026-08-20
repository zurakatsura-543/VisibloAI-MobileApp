import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visiblo_ai_app/app/services/local_auth_service.dart';
import 'package:visiblo_ai_app/features/auth/models/test_account.dart';
import 'package:visiblo_ai_app/features/auth/services/auth_api_service.dart';
import 'package:visiblo_ai_app/features/auth/views/audit_view.dart';
import 'package:visiblo_ai_app/features/onboarding/controllers/onboarding_controller.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Get.putAsync<LocalAuthService>(() => LocalAuthService().init());
    Get.put(AuthApiService());
  });

  tearDown(Get.reset);

  testWidgets('audit route builds for a logged-in user', (tester) async {
    Get.find<LocalAuthService>().currentUser.value = const TestAccount(
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
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AuditView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
