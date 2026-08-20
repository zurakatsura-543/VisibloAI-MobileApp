import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:visiblo_ai_app/app/widgets/connectivity_banner.dart';
import 'package:visiblo_ai_app/core/connectivity_service.dart';

void main() {
  late ConnectivityService connectivity;

  setUp(() {
    connectivity = Get.put(ConnectivityService());
  });

  tearDown(Get.reset);

  testWidgets('shows a persistent offline indicator', (tester) async {
    connectivity.isOffline.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConnectivityBanner(child: Text('App content'))),
      ),
    );

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('App content'), findsOneWidget);
  });

  testWidgets('shows a restored indicator when the app reconnects', (
    tester,
  ) async {
    connectivity.showConnectionRestored.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ConnectivityBanner(child: Text('App content'))),
      ),
    );

    expect(find.text('Back online'), findsOneWidget);
    expect(find.text('No internet connection'), findsNothing);
  });
}
