import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/main.dart';

void main() {
  tearDown(() => Api.requestHandler = null);

  testWidgets('login exposes athlete and Personal entry choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(onLogin: _noopLogin)),
    );
    expect(find.text('SOU ATLETA'), findsOneWidget);
    expect(find.text('COACH / TRAINER'), findsOneWidget);
    expect(find.text('ENTRAR NO WEGYM OS'), findsOneWidget);
  });

  testWidgets('More menu opens a selected module', (tester) async {
    _installAppApi();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AppShell(onLogout: _noopLogout)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mais').last);
    await tester.pumpAndSettle();
    expect(find.text('Comunidade'), findsWidgets);
    await tester.tap(find.text('Comunidade').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('COMUNIDADE'), findsWidgets);
  });

  testWidgets(
    'desktop sidebar persists while each route replaces page content',
    (tester) async {
      _installAppApi();
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AppShell(onLogout: _noopLogout)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Geral').last, findsOneWidget);

      for (final (route, marker) in const <(String, String)>[
        ('Comunidade', 'MURAL SOCIAL & RECORDES'),
        ('Programas', 'PROGRAMAS DE TREINAMENTO'),
        ('Agendamentos', 'AGENDAMENTOS &'),
        ('Atividade', 'SESS'),
        ('Treinos', 'MODELO'),
        ('Vis\u00e3o Geral', 'BEM-VINDO DE VOLTA'),
      ]) {
        final option = find.text(route).last;
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(
          find.textContaining(marker),
          findsWidgets,
          reason: 'Selecting $route should replace the previous screen.',
        );
      }
    },
  );
}

void _noopLogin(String _) {}

void _noopLogout() {}

void _installAppApi() {
  Api.requestHandler = (path, {required method, body, required auth}) async {
    if (path == '/api/user/profile') {
      return {
        'id': 'athlete-user',
        'role': 'atleta',
        'name': 'Atleta teste',
        'athlete': {'id': 'athlete-1', 'name': 'Atleta teste'},
      };
    }
    if (path.startsWith('/api/workout-stats')) {
      return {
        'data': {'totalSessions': 2, 'totalVolume': 2400},
      };
    }
    if (path.startsWith('/api/workout-sessions') ||
        path.startsWith('/api/training-plans')) {
      return {'data': []};
    }
    if (path == '/api/social?feed=friends') return {'posts': []};
    if (path.startsWith('/api/')) return [];
    return {};
  };
}
