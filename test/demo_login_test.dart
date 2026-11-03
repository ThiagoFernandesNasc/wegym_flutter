import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/main.dart';

void main() {
  testWidgets(
    'demo login opens the athlete account when its card is selected',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests = <String>[];
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requests.add(path);
            throw StateError('The preview should work without the backend.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const WegymApp());
      await tester.pumpAndSettle();
      final account = find.textContaining('joao@wegym.com.br');
      await tester.ensureVisible(account);
      await tester.tap(account);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ENTRAR NO WEGYM OS'));
      await tester.pumpAndSettle();
      final skipOnboarding = find.text('PULAR');
      if (skipOnboarding.evaluate().isNotEmpty) {
        await tester.tap(skipOnboarding);
        await tester.pumpAndSettle();
      }

      expect(find.textContaining('BEM-VINDO DE VOLTA'), findsOneWidget);
      expect(find.text('38.450 kg'), findsOneWidget);
      expect(await Api.previewRole(), 'atleta');
      expect(requests, ['/api/auth/login']);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo login opens the Personal account when its card is selected',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests = <String>[];
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requests.add(path);
            throw StateError('The preview should work without the backend.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const WegymApp());
      await tester.pumpAndSettle();
      final account = find.textContaining('personal@wegym.com.br');
      await tester.ensureVisible(account);
      await tester.tap(account);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ENTRAR NO WEGYM OS'));
      await tester.pumpAndSettle();
      final skipOnboarding = find.text('PULAR');
      if (skipOnboarding.evaluate().isNotEmpty) {
        await tester.tap(skipOnboarding);
        await tester.pumpAndSettle();
      }

      expect(find.text('GESTÃO DE ALUNOS & COACHING'), findsOneWidget);
      expect(await Api.previewRole(), 'personal');
      expect(requests, ['/api/auth/login']);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );
}
