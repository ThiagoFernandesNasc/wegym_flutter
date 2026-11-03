import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/workout_builder.dart';

void main() {
  testWidgets('records completed set weight and reps in the saved session', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    Map<String, dynamic>? savedBody;
    Api.requestHandler = (path, {required method, body, required auth}) async {
      if (path != '/api/workout-sessions' || method != 'POST') {
        throw StateError('Unexpected API call: $method $path');
      }
      savedBody = Map<String, dynamic>.from(body as Map);
      return {'id': 'session-1'};
    };
    addTearDown(() => Api.requestHandler = null);

    final controller = WorkoutSessionController(
      plannedExercises: const [
        {'name': 'Supino reto', 'sets': '2', 'reps': '8-10', 'load': '80 kg'},
      ],
    )..elapsed.value = 1;
    controller.running = false;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkoutSessionPage(
            preview: false,
            controller: controller,
            onExit: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final setButton = find.byKey(const ValueKey('workout-set-0-1'));
    await tester.scrollUntilVisible(setButton, 220);
    await tester.pumpAndSettle();
    await tester.tap(setButton);
    await tester.pumpAndSettle();
    expect(find.text('Registrar série 1'), findsOneWidget);
    await tester.tap(find.text('CONFIRMAR SÉRIE'));
    await tester.pumpAndSettle();
    expect(find.text('80 kg × 9'), findsOneWidget);

    final finishButton = find.text('FINALIZAR E SALVAR');
    await tester.scrollUntilVisible(finishButton, 220);
    await tester.pumpAndSettle();
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(find.text('Treino registrado com sucesso.'), findsOneWidget);
    final exercise = (savedBody!['exercises'] as List).single as Map;
    final performed = (exercise['performedSets'] as List).single as Map;
    expect(performed['completed'], isTrue);
    expect(performed['weightKg'], 80);
    expect(performed['reps'], 9);
    expect(performed['setNumber'], 1);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets(
    'athlete preview opens on a scheduled day with the correct PPL workout',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await Api.setPreviewRole('atleta');
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutBuilderPage(onStartSession: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TREINO A  •  SEGUNDA'), findsOneWidget);
      expect(find.text('Supino reto com barra'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'TREINO QUA'));
      await tester.pumpAndSettle();
      expect(find.text('TREINO B  •  QUARTA'), findsOneWidget);
      expect(find.text('Puxada frontal'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'Personal preview selects an athlete and saves their weekly plan locally',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await Api.setPreviewRole('personal');
      var requests = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requests++;
            throw StateError('Personal demo plans must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutBuilderPage(onStartSession: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ATLETA'), findsOneWidget);
      expect(find.text('Mariana Costa'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pedro Almeida').last);
      await tester.pumpAndSettle();
      expect(find.text('Pedro Almeida'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upper/Lower').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR SEMANA'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Prévia: divisão semanal salva localmente para Pedro Almeida.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mariana Costa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pedro Almeida').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byType(DropdownButton<String>).first,
            )
            .value,
        'Upper/Lower',
      );
      expect(requests, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'Personal saves edited days for the selected athlete through the API',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final requests =
          <({String path, String method, Map<String, dynamic>? body})>[];
      var deleteAttempts = 0;
      Api.requestHandler = (path, {required method, body, required auth}) async {
        requests.add((path: path, method: method, body: body));
        if (path == '/api/user/profile') {
          return {'id': 'coach-1', 'role': 'personal'};
        }
        if (path == '/api/athletes?take=50') {
          return {
            'data': [
              {
                'id': '11111111-1111-4111-8111-111111111111',
                'name': 'Mariana Costa',
              },
            ],
          };
        }
        if (path ==
            '/api/training-plans?athleteId=11111111-1111-4111-8111-111111111111') {
          return {
            'data': [
              {
                'id': 'plan-monday',
                'day': 'Seg',
                'exercises': [
                  {'name': 'Supino reto com barra', 'sets': '4', 'reps': '8'},
                ],
              },
              {
                'id': 'plan-wednesday',
                'day': 'Qua',
                'exercises': [
                  {'name': 'Puxada frontal', 'sets': '3', 'reps': '10'},
                ],
              },
            ],
          };
        }
        if (path == '/api/training-plans' && method == 'POST') {
          return {'id': 'plan-monday'};
        }
        if (path == '/api/training-plans/plan-wednesday' &&
            method == 'DELETE') {
          deleteAttempts++;
          if (deleteAttempts == 1) {
            throw Exception('temporary network failure');
          }
          return {'success': true};
        }
        throw StateError('Unexpected API call: $method $path');
      };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: WorkoutBuilderPage(onStartSession: _noop)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mariana Costa'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'QUA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SALVAR SEMANA'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Não foi possível salvar a divisão'),
        findsOneWidget,
      );
      await tester.tap(find.text('SALVAR SEMANA'));
      await tester.pumpAndSettle();

      expect(deleteAttempts, 2);
      final saved = requests.singleWhere(
        (request) =>
            request.method == 'POST' && request.path == '/api/training-plans',
      );
      expect(saved.body?['athleteId'], '11111111-1111-4111-8111-111111111111');
      expect(saved.body?['day'], 'Seg');
      expect(
        find.text('Divisão semanal salva para Mariana Costa.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );
}

void _noop() {}
