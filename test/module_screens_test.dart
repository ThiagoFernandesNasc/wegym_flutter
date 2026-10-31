import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/figma_modules.dart';

void main() {
  var role = 'atleta';
  var seedGoal = false;
  var seedSlot = false;
  var seedMeal = false;
  var seedProgram = false;
  final calls = <({String path, String method, Map<String, dynamic>? body})>[];

  setUp(() {
    role = 'atleta';
    seedGoal = false;
    seedSlot = false;
    seedMeal = false;
    seedProgram = false;
    calls.clear();
    Api.requestHandler = (path, {required method, body, required auth}) async {
      calls.add((path: path, method: method, body: body));
      if (path == '/api/user/profile') {
        return {
          'id': 'user-1',
          'role': role,
          'name': 'Pessoa de teste',
          'email': 'teste@example.com',
          'athlete': {'name': 'Pessoa de teste'},
          'personal': {'name': 'Pessoa de teste'},
        };
      }
      if (path.startsWith('/api/workout-stats')) {
        return {
          'data': {
            'totalSessions': 2,
            'totalVolume': 1200,
            'totalDistance': 3.2,
            'avgHeartRate': 120,
          },
        };
      }
      if (path.startsWith('/api/workout-sessions')) return {'data': []};
      if (path == '/api/social?feed=friends') return {'posts': []};
      if (path == '/api/challenges' && method == 'POST') return {'id': 'participant-1'};
      if (path == '/api/challenges') {
        return [
          {
            'id': 'challenge-1',
            'name': 'Desafio de teste',
            'description': 'Desafio usado no teste de tela.',
            'participants': [],
          },
        ];
      }
      if (path == '/api/achievements') return {'userAchievements': []};
      if (path == '/api/appointments/slots') {
        return seedSlot
            ? [
                {
                  'id': 'slot-1',
                  'date': '2026-11-02',
                  'startTime': '17:00',
                  'endTime': '18:00',
                },
              ]
            : [];
      }
      if (path == '/api/appointments' && method == 'POST') return {'id': 'appointment-1'};
      if (path == '/api/appointments') return [];
      if (path == '/api/nutrition/meals' && method == 'POST') return {'id': 'meal-food-1'};
      if (path == '/api/nutrition/meals') {
        return seedMeal
            ? [
                {
                  'id': 'meal-1',
                  'type': 'lunch',
                  'foods': [],
                  'totals': {'calories': 0, 'proteinG': 0},
                },
              ]
            : [];
      }
      if (path.startsWith('/api/nutrition/foods?q=')) {
        return [
          {'id': 'food-1', 'name': 'Aveia', 'calories': 150},
        ];
      }
      if (path.startsWith('/api/nutrition/')) return [];
      if (path == '/api/body-measurements' ||
          path.startsWith('/api/nutrition/') ||
          path == '/api/checkin?history=true&days=30' ||
          path == '/api/classes' ||
          path == '/api/friends') {
        return [];
      }
      if (path == '/api/nutrition/foods') return [];
      if (path == '/api/personal-stats') {
        return {'athleteCount': 1, 'activeAthletes': 1};
      }
      if (path.startsWith('/api/athletes')) {
        return {
          'data': [
            {'id': 'athlete-1', 'name': 'Atleta de teste'},
          ],
        };
      }
      if (path == '/api/goals' && method == 'POST') return {'id': 'goal-new'};
      if (path == '/api/goals' && method == 'PATCH') return {'id': 'goal-1'};
      if (path == '/api/goals' && method == 'DELETE') return {'success': true};
      if (path == '/api/goals') {
        return seedGoal
            ? [
                {
                  'id': 'goal-1',
                  'title': 'Meta de teste',
                  'metric': 'sessões',
                  'targetValue': 4,
                  'currentValue': 1,
                  'status': 'active',
                },
              ]
            : [];
      }
      if (path.startsWith('/api/programs')) {
        if (path == '/api/programs/prog-1') {
          return {'id': 'prog-1', 'title': 'Programa teste', 'description': 'Detalhes carregados', 'durationWeeks': 4, 'daysPerWeek': 3, 'exercises': []};
        }
        return seedProgram
            ? [
                {'id': 'prog-1', 'title': 'Programa teste', 'description': 'Resumo', 'durationWeeks': 4, 'daysPerWeek': 3},
              ]
            : [];
      }
      if (path == '/api/messages') {
        return {
          'conversations': {
            'sent': [
              {
                'receiver': {'id': 'contact-1', 'displayName': 'Coach teste'},
              },
            ],
            'received': [],
          },
          'unreadCount': 0,
        };
      }
      if (path == '/api/messages/contact-1') {
        return [
          {
            'id': 'message-1',
            'senderId': 'contact-1',
            'receiverId': 'user-1',
            'text': 'Mensagem de teste',
          },
        ];
      }
      if (path == '/api/integrations' || path == '/api/subscriptions') {
        return [];
      }
      if (path == '/api/subscriptions/me') return {'data': null};
      if (path == '/api/checkin') return {'today': null, 'streak': 0};
      if (path == '/api/medidas') return [];
      return {};
    };
  });

  tearDown(() => Api.requestHandler = null);

  testWidgets('all remaining modules render at mobile and desktop widths', (
    tester,
  ) async {
    const modules = <(String, String)>[
      ('Comunidade', 'COMUNIDADE'),
      ('Analytics & Performance', 'ANALYTICS'),
      ('Agendamentos', 'AGENDAMENTOS'),
      ('Nutrição', 'NUTRI'),
      ('Alunos & Personal', 'GESTÃO DE ALUNOS'),
      ('Metas & Desafios', 'METAS'),
      ('Programas', 'PROGRAMAS'),
      ('Chat', 'CANAL ATLETA'),
      ('Perfil & Configurações', 'PERFIL'),
      ('Planos PRO', 'PLANOS WEGYM'),
      ('Medidas', 'AVALIAÇÃO CORPORAL'),
      ('Check-in', 'CHECK-IN'),
      ('Amigos', 'AMIGOS'),
      ('Aulas', 'AULAS'),
    ];

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final (module, marker) in modules) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: FigmaModulePage(module: module)),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining(marker),
          findsWidgets,
          reason: '$module should render at ${size.width}px.',
        );
        expect(tester.takeException(), isNull, reason: '$module at $size');
      }
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('chat opens a conversation and sends a message to its contact', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Chat')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
    expect(find.text('Mensagem de teste'), findsOneWidget);
    expect(calls.any((call) => call.path == '/api/messages/contact-1'), isTrue);
    await tester.enterText(find.byType(TextField).last, 'Olá, coach');
    await tester.tap(find.text('ENVIAR'));
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (call) =>
            call.path == '/api/messages' &&
            call.method == 'POST' &&
            call.body?['text'] == 'Olá, coach' &&
            call.body?['receiverId'] == 'contact-1',
      ),
      isTrue,
    );
  });

  testWidgets('athlete cannot load the Personal-only management data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Alunos & Personal')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('exclusiva'), findsOneWidget);
    expect(calls.any((call) => call.path.startsWith('/api/athletes')), isFalse);
  });
}
