import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/ai_coach_sheet.dart';
import 'package:wegym_flutter/api.dart';

void main() {
  const isPreview = bool.fromEnvironment('PREVIEW_DASHBOARD');

  tearDown(() {
    Api.requestHandler = null;
  });

  testWidgets('generated workout can start an athlete session', (tester) async {
    List<Map<String, dynamic>>? startedExercises;
    Api.requestHandler = (path, {required method, body, required auth}) async {
      expect(path, '/api/chat');
      expect(method, 'POST');
      expect(body?['message'], 'Monte um treino de peito');
      return {
        'text': 'Treino de peito gerado.',
        'workoutGenerated': true,
        'workoutData': {
          'exercises': [
            {'name': 'Supino reto', 'sets': 4, 'reps': '8-10', 'load': '40'},
          ],
        },
      };
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showAiCoachSheet(
                  context,
                  onStartWorkout: (exercises) => startedExercises = exercises,
                ),
                child: const Text('Abrir assistente'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir assistente'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Monte um treino de peito');
    await tester.tap(find.byTooltip('Enviar mensagem'));
    await tester.pumpAndSettle();

    expect(find.text('Treino de peito gerado.'), findsOneWidget);
    expect(find.text('Supino reto'), findsOneWidget);
    expect(find.text('INICIAR TREINO SUGERIDO'), findsOneWidget);

    await tester.tap(find.text('INICIAR TREINO SUGERIDO'));
    await tester.pumpAndSettle();

    expect(startedExercises, [
      {'name': 'Supino reto', 'sets': '4', 'reps': '8-10', 'load': '40'},
    ]);
  }, skip: isPreview);

  testWidgets('preview AI suggestion uses Gemini and starts a workout', (
    tester,
  ) async {
    var requestCalled = false;
    List<Map<String, dynamic>>? startedExercises;
    Api.requestHandler = (path, {required method, body, required auth}) async {
      requestCalled = true;
      expect(path, '/api/chat');
      expect(method, 'POST');
      expect(auth, isFalse);
      expect(
        body?['message'].toString(),
        startsWith('Monte um treino de peito e'),
      );
      return {
        'text': 'Treino gerado pelo Gemini.',
        'workoutGenerated': true,
        'workoutData': {
          'exercises': [
            {'name': 'Supino reto com barra', 'sets': 3, 'reps': '8-12'},
            {'name': 'Triceps corda', 'sets': 3, 'reps': '10-15'},
            {'name': 'Crossover na polia', 'sets': 3, 'reps': '12-15'},
            {
              'name': 'Supino inclinado com halteres',
              'sets': 3,
              'reps': '8-12',
            },
          ],
        },
      };
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showAiCoachSheet(
                  context,
                  onStartWorkout: (exercises) => startedExercises = exercises,
                ),
                child: const Text('Abrir assistente'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir assistente'));
    await tester.pumpAndSettle();
    expect(find.text('GEMINI \u2022 SUGEST\u00d5ES DE TREINO'), findsOneWidget);
    await tester.tap(find.textContaining('Monte um treino de peito e'));
    await tester.pumpAndSettle();

    expect(find.text('Treino gerado pelo Gemini.'), findsOneWidget);
    expect(find.text('Supino reto com barra'), findsOneWidget);
    expect(requestCalled, isTrue);
    await tester.tap(find.text('INICIAR TREINO SUGERIDO'));
    await tester.pumpAndSettle();
    expect(startedExercises, isNotNull);
    expect(startedExercises, hasLength(4));
  }, skip: !isPreview);
}
