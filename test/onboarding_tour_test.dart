import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/onboarding_tour.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  tearDown(() {
    Api.requestHandler = null;
  });

  testWidgets(
    'athlete tour advances, can be skipped, and persists completion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () =>
                      showOnboardingIfNeeded(context, role: 'atleta'),
                  child: const Text('Abrir tutorial'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir tutorial'));
      await tester.pumpAndSettle();
      expect(find.text('Bem-vindo ao WEGYM'), findsOneWidget);
      await tester.tap(find.text('PR\u00d3XIMO'));
      await tester.pumpAndSettle();
      expect(find.text('Treinos inteligentes'), findsOneWidget);
      await tester.tap(find.text('PULAR'));
      await tester.pumpAndSettle();

      expect(await Api.hasCompletedOnboarding(), isTrue);
      await tester.tap(find.text('Abrir tutorial'));
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingTourDialog), findsNothing);
    },
  );

  testWidgets('Personal tour uses the coach-specific content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OnboardingTourDialog(role: 'personal')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Painel do Personal'), findsOneWidget);
    await tester.tap(find.text('PR\u00d3XIMO'));
    await tester.pumpAndSettle();
    expect(find.text('Gest\u00e3o de alunos'), findsOneWidget);
    expect(find.text('PULAR'), findsOneWidget);
  });

  test(
    'login returns the role supplied by the authenticated API response',
    () async {
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            if (path == '/api/auth/login') {
              expect(auth, isFalse);
              return {
                'token': 'personal-token',
                'user': {'id': 'personal-1', 'role': 'personal'},
              };
            }
            throw StateError('Unexpected request: $method $path');
          };

      expect(await Api.login('coach@example.com', 'password123'), 'personal');
      expect(await Api.token(), 'personal-token');
    },
  );
}
