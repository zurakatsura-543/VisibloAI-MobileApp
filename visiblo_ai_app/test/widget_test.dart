import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visiblo_ai_app/app/app.dart';
import 'package:visiblo_ai_app/app/services/local_auth_service.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await Get.putAsync<LocalAuthService>(() => LocalAuthService().init());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('welcome screen renders get started CTA', (tester) async {
    await tester.pumpWidget(const VisibloAiApp());
    await tester.pump();

    expect(find.text('Get started'), findsOneWidget);
  });
}
