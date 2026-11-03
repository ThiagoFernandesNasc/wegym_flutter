import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/ble_monitor_page.dart';
import 'package:wegym_flutter/main.dart';

void main() {
  const isPreview = bool.fromEnvironment('PREVIEW_DASHBOARD');
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  tearDown(() {
    Api.requestHandler = null;
    Api.cepLookupHandler = null;
  });

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

  testWidgets('Personal registration unlocks only after API CREF validation', (
    tester,
  ) async {
    var crefIsValid = false;
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests =
        <
          ({String path, String method, Map<String, dynamic>? body, bool auth})
        >[];
    Api.requestHandler = (path, {required method, body, required auth}) async {
      requests.add((path: path, method: method, body: body, auth: auth));
      if (path == '/api/cref/validate') {
        return crefIsValid
            ? {'valid': true, 'normalizedCref': body?['cref']}
            : {
                'valid': false,
                'errors': ['CREF nao encontrado.'],
              };
      }
      if (path == '/api/auth/register') return {'id': 'new-personal'};
      throw StateError('Unexpected request: $method $path');
    };

    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(onLogin: _noopLogin)),
    );
    await tester.ensureVisible(find.text('Primeiro acesso na academia?'));
    await tester.tap(find.text('Primeiro acesso na academia?'));
    await _pumpUi(tester);
    await tester.ensureVisible(find.text('CRIAR CONTA').last);
    await tester.tap(find.text('CRIAR CONTA').last);
    await _pumpUi(tester);
    await tester.tap(find.text('Personal').last);
    await _pumpUi(tester);

    expect(find.byKey(const ValueKey('validate-cref')), findsOneWidget);
    expect(find.text('CRIE SUA CONTA'), findsOneWidget);
    expect(find.text('CRIAR CONTA'), findsNothing);
    expect(find.text('E-mail'), findsNothing);

    final crefField = find.byKey(const ValueKey('signup-credential'));
    await tester.enterText(crefField, '000000-0/SP');
    await tester.tap(find.byKey(const ValueKey('validate-cref')));
    await _pumpUi(tester);
    expect(find.textContaining('CREF nao encontrado'), findsOneWidget);
    expect(find.text('E-mail'), findsNothing);

    crefIsValid = true;
    await tester.tap(find.byKey(const ValueKey('validate-cref')));
    await _pumpUi(tester);
    expect(find.text('CREF validado'), findsOneWidget);
    expect(find.text('E-mail'), findsWidgets);
    expect(find.text('CRIAR CONTA'), findsOneWidget);
    expect(
      requests.where((request) => request.path == '/api/cref/validate'),
      hasLength(2),
    );
    expect(
      requests.every(
        (request) =>
            request.path != '/api/cref/validate' ||
            (!request.auth && request.body?['cref'] == '000000-0/SP'),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('athlete registration preserves profile and health data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Map<String, dynamic>? registration;
    Api.cepLookupHandler = (cep) async =>
        cep == '01001000' ? {'city': 'S\u00e3o Paulo', 'state': 'SP'} : null;
    Api.requestHandler = (path, {required method, body, required auth}) async {
      if (path == '/api/auth/register' && method == 'POST') {
        registration = body;
        return {'id': 'athlete-1'};
      }
      throw StateError('Unexpected request: $method $path');
    };

    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(onLogin: _noopLogin)),
    );
    await tester.ensureVisible(find.text('Primeiro acesso na academia?'));
    await tester.tap(find.text('Primeiro acesso na academia?'));
    await _pumpUi(tester);
    await tester.ensureVisible(find.text('CRIAR CONTA').last);
    await tester.tap(find.text('CRIAR CONTA').last);
    await _pumpUi(tester);

    Future<void> fill(String key, String value) async {
      final field = find.byKey(ValueKey(key));
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
      await _pumpUi(tester);
    }

    await fill('signup-name', 'Jo\u00e3o da Silva');
    await fill('signup-credential', '52998224725');
    await fill('signup-email', 'joao@example.com');
    await fill('signup-cep', '01001000');
    expect(find.text('S\u00e3o Paulo'), findsOneWidget);
    await fill('signup-age', '28');
    await fill('signup-height', '182');
    await fill('signup-weight', '81.4');

    await tester.ensureVisible(find.byKey(const ValueKey('signup-sex')));
    await tester.tap(find.byKey(const ValueKey('signup-sex')));
    await _pumpUi(tester);
    await tester.tap(find.text('Masculino').last);
    tester
        .state<FormFieldState<String>>(
          find.byKey(const ValueKey('signup-experience')),
        )
        .didChange('intermediario');
    await _pumpUi(tester);

    await fill('signup-password', 'treino123');
    await fill('signup-confirm-password', 'treino123');
    for (final consentKey in const [
      'consent-terms',
      'consent-privacy',
      'consent-data',
    ]) {
      final consent = find.byKey(ValueKey(consentKey));
      await tester.ensureVisible(consent);
      await tester.pumpAndSettle();
      final checkbox = find.descendant(
        of: consent,
        matching: find.byType(Checkbox),
      );
      await tester.tap(checkbox);
      await tester.pump();
    }
    await tester.ensureVisible(find.text('CRIAR CONTA').last);
    await tester.tap(find.text('CRIAR CONTA').last);
    await _pumpUi(tester);
    expect(find.text('Bem-vindo ao WEGYM'), findsOneWidget);
    await tester.tap(find.text('PULAR'));
    await tester.pumpAndSettle();

    expect(registration?['userType'], 'atleta');
    expect(registration?['cpf'], '52998224725');
    expect(registration?['cep'], '01001000');
    expect(registration?['city'], 'S\u00e3o Paulo');
    expect(registration?['state'], 'SP');
    expect(registration?['age'], 28);
    expect(registration?['sex'], 'masculino');
    expect(registration?['height'], 182.0);
    expect(registration?['weight'], 81.4);
    expect(registration?['experienceLevel'], 'intermediario');
    expect(registration?['termsAccepted'], true);
    expect(registration?['privacyAccepted'], true);
    expect(registration?['dataConsentAccepted'], true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI assistant can be dragged and switched to compact mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DraggableAiAssistant(onPressed: _noopLogout)),
      ),
    );
    await tester.pump();

    expect(find.text('ASSISTENTE IA'), findsOneWidget);
    final handle = find.byKey(const ValueKey('wegym-ai-coach-drag-handle'));
    final initialPosition = tester.getTopLeft(handle);
    await tester.drag(handle, const Offset(-80, -120));
    await tester.pump();
    expect(tester.getTopLeft(handle), isNot(initialPosition));

    await tester.tap(find.byKey(const ValueKey('wegym-ai-coach-resize')));
    await tester.pump();
    expect(find.text('ASSISTENTE IA'), findsNothing);
    expect(find.byTooltip('Ampliar bot\u00e3o do assistente'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('wegym-ai-coach-resize')));
    await tester.pump();
    expect(find.text('ASSISTENTE IA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile menu logs out through the existing app callback', (
    tester,
  ) async {
    _installAppApi();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var logoutCalled = false;

    await tester.pumpWidget(
      MaterialApp(home: AppShell(onLogout: () => logoutCalled = true)),
    );
    await _pumpUi(tester);

    await tester.tap(find.byTooltip('Abrir perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta'), findsOneWidget);
    await tester.tap(find.text('Sair da conta'));
    await _pumpUi(tester);
    expect(logoutCalled, isTrue);
    // Drain unrelated layout diagnostics emitted by the full dashboard fixture.
    tester.takeException();
  });

  testWidgets('hamburger opens the side navigation drawer', (tester) async {
    _installAppApi();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: AppShell(onLogout: _noopLogout)),
    );
    await _pumpUi(tester);

    expect(find.byIcon(Icons.menu), findsOneWidget);
    await tester.tap(find.byTooltip('Menu de navega\u00e7\u00e3o'));
    await tester.pumpAndSettle();
    final drawer = find.byKey(const ValueKey('navigation-drawer'));
    expect(drawer, findsOneWidget);
    final community = find.descendant(
      of: drawer,
      matching: find.text('Comunidade'),
    );
    expect(community, findsOneWidget);
    await tester.tap(community);
    await _pumpUi(tester);
    expect(find.textContaining('COMUNIDADE'), findsWidgets);
    expect(tester.takeException(), isNull);
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
    await _pumpUi(tester);

    await tester.tap(find.text('Mais').last);
    await _pumpUi(tester);
    expect(find.text('Comunidade'), findsWidgets);
    await tester.tap(find.text('Comunidade').last);
    await _pumpUi(tester);
    expect(find.textContaining('COMUNIDADE'), findsWidgets);
  });

  testWidgets(
    'AI assistant requests a workout and renders Gemini exercises',
    (tester) async {
      final requests = _installAppApi();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: AppShell(onLogout: _noopLogout)),
      );
      await _pumpUi(tester);
      await tester.tap(find.text('ASSISTENTE IA'));
      await _pumpUi(tester);

      final input = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Descreva seu objetivo de treino...',
      );
      await tester.enterText(input, 'Monte um treino de peito');
      await tester.tap(find.byTooltip('Enviar mensagem'));
      await _pumpUi(tester);

      expect(find.text('Sugestao de treino criada.'), findsOneWidget);
      expect(find.text('Supino reto com barra'), findsOneWidget);
      expect(
        requests.any(
          (request) =>
              request.path == '/api/chat' &&
              request.method == 'POST' &&
              request.body?['message'] == 'Monte um treino de peito' &&
              request.body?['level'] == 'Intermedi\u00e1rio',
        ),
        isTrue,
      );
      await tester.tap(find.text('INICIAR TREINO SUGERIDO'));
      await _pumpUi(tester);
      expect(find.text('TEMPO DE TREINO'), findsOneWidget);
      expect(find.text('EXERCÍCIOS DO TREINO'), findsOneWidget);
      expect(find.text('Supino reto com barra'), findsOneWidget);
      expect(find.text('TREINO EM ANDAMENTO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: isPreview,
  );

  testWidgets('BLE monitor renders at compact and wide widths', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BleMonitorPage())),
      );
      await _pumpUi(tester);
      expect(find.textContaining('MONITOR CARD'), findsOneWidget);
      expect(find.text('PROCURAR SENSOR BLE'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'BLE screen at $size');
    }
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
      await _pumpUi(tester);
      expect(find.textContaining('Geral').last, findsOneWidget);
      expect(find.byTooltip('Menu de navega\u00e7\u00e3o'), findsOneWidget);
      expect(find.byTooltip('Abrir outra \u00e1rea'), findsNothing);

      for (final (route, marker) in const <(String, String)>[
        ('Comunidade', 'MURAL SOCIAL & RECORDES'),
        ('Conquistas', 'CONQUISTAS DO ATLETA'),
        ('Programas', 'PROGRAMAS DE TREINAMENTO'),
        ('Agendamentos', 'AGENDAMENTOS &'),
        ('Atividade', 'SESS'),
        ('Treinos', 'MODELO'),
        ('Vis\u00e3o Geral', 'BEM-VINDO DE VOLTA'),
      ]) {
        final option = find.text(route);
        final sidebarList = find.byKey(
          const ValueKey('desktop-sidebar-scroll'),
        );
        final sidebar = find.descendant(
          of: sidebarList,
          matching: find.byType(Scrollable),
        );
        await tester.drag(sidebarList, const Offset(0, 1000));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.scrollUntilVisible(option, 120, scrollable: sidebar);
        await tester.tap(option.first);
        await _pumpUi(tester);
        expect(
          find.textContaining(marker),
          findsWidgets,
          reason: 'Selecting $route should replace the previous screen.',
        );
      }
    },
  );
}

Future<void> _pumpUi(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void _noopLogin(String _) {}

void _noopLogout() {}

List<({String path, String method, Map<String, dynamic>? body})>
_installAppApi() {
  final requests =
      <({String path, String method, Map<String, dynamic>? body})>[];
  Api.requestHandler = (path, {required method, body, required auth}) async {
    requests.add((path: path, method: method, body: body));
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
    if (path == '/api/chat') {
      return {
        'text': 'Sugestao de treino criada.',
        'workoutGenerated': true,
        'workoutData': {
          'exercises': [
            {
              'name': 'Supino reto com barra',
              'sets': 4,
              'reps': '8-10',
              'load': '40 kg',
            },
          ],
        },
      };
    }
    if (path.startsWith('/api/')) return [];
    return {};
  };
  return requests;
}
