import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/figma_modules.dart';
import 'package:wegym_flutter/legal_document_page.dart';
import 'package:wegym_flutter/main.dart';

void main() {
  testWidgets('login opens legal documents and returns with navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(onLogin: _noopLogin)),
    );
    await _pumpLoginUi(tester);
    final termsLink = find.byKey(const ValueKey('legal-link-terms-login'));
    await tester.ensureVisible(termsLink);
    await tester.tap(termsLink);
    await _pumpLoginUi(tester);

    expect(find.text('TERMOS DE USO'), findsOneWidget);
    expect(find.text('1. ACEITA\u00c7\u00c3O DOS TERMOS'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _pumpLoginUi(tester);
    expect(find.text('ENTRAR NO WEGYM OS'), findsOneWidget);

    final privacyLink = find.byKey(const ValueKey('legal-link-privacy-login'));
    await tester.ensureVisible(privacyLink);
    await tester.tap(privacyLink);
    await _pumpLoginUi(tester);
    expect(find.text('POL\u00cdTICA DE PRIVACIDADE'), findsOneWidget);
    expect(find.text('1. INTRODU\u00c7\u00c3O'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _pumpLoginUi(tester);

    await tester.tap(find.text('Primeiro acesso na academia?'));
    await _pumpLoginUi(tester);
    await tester.ensureVisible(find.text('CRIAR CONTA'));
    await tester.tap(find.text('CRIAR CONTA'));
    await _pumpLoginUi(tester);
    final signupPrivacy = find.byKey(
      const ValueKey('legal-link-privacy-signup'),
    );
    await tester.ensureVisible(signupPrivacy);
    await tester.tap(signupPrivacy);
    await _pumpLoginUi(tester);
    expect(find.text('POL\u00cdTICA DE PRIVACIDADE'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _pumpLoginUi(tester);
    expect(
      find.byKey(const ValueKey('legal-link-privacy-signup')),
      findsOneWidget,
    );
    expect(find.text('CRIAR CONTA'), findsOneWidget);
  });

  testWidgets('profile provides legal document links', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    Api.requestHandler = (path, {required method, body, required auth}) async {
      if (path == '/api/user/profile') {
        return {
          'id': 'user-1',
          'role': 'atleta',
          'name': 'Atleta teste',
          'email': 'atleta@example.com',
          'athlete': {'name': 'Atleta teste'},
        };
      }
      if (path == '/api/integrations') return [];
      if (path == '/api/subscriptions/me') return {'data': null};
      return {};
    };
    addTearDown(() => Api.requestHandler = null);

    await tester.pumpWidget(
      const MaterialApp(
        home: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
      ),
    );
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final terms = find.byKey(const ValueKey('legal-link-terms-profile'));
    await tester.ensureVisible(terms);
    await tester.pumpAndSettle();
    await tester.tap(terms);
    await tester.pumpAndSettle();
    expect(find.text('TERMOS DE USO'), findsOneWidget);
  });

  testWidgets('legal pages adapt to mobile and desktop widths', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalDocumentPage(kind: LegalDocumentKind.privacy),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('POL\u00cdTICA DE PRIVACIDADE'), findsOneWidget);
      expect(find.text('1. INTRODU\u00c7\u00c3O'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Page width $size');
    }
  });
}

Future<void> _pumpLoginUi(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _noopLogin(String _) {}
