import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/challenge_leaderboard_page.dart';
import 'package:wegym_flutter/figma_modules.dart';
import 'package:wegym_flutter/program_detail_page.dart';
import 'package:wegym_flutter/profile_data_export.dart';
import 'package:wegym_flutter/pwa_install_card.dart';
import 'package:wegym_flutter/integration_return_link.dart';
import 'package:wegym_flutter/personal_copilot_sheet.dart';

const _isPreview = bool.fromEnvironment('PREVIEW_DASHBOARD');

Future<void> _pumpUi(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  var role = 'atleta';
  var seedGoal = false;
  var seedSlot = false;
  var seedMeal = false;
  var seedProgram = false;
  var seedSocialFeed = false;
  var seedAthletePagination = false;
  var friendRequestAnswered = false;
  var challengeJoined = false;
  var profileWeight = 76.2;
  var profileHeight = 175;
  var activeSubscription = false;
  var athletePersonalUserId = 'personal-user-1';
  final calls = <({String path, String method, Map<String, dynamic>? body})>[];

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ProfileDataExport.saveHandler = null;
    integrationReturnLink.value = null;
    role = 'atleta';
    seedGoal = false;
    seedSlot = false;
    seedMeal = false;
    seedProgram = false;
    seedSocialFeed = false;
    seedAthletePagination = false;
    friendRequestAnswered = false;
    challengeJoined = false;
    profileWeight = 76.2;
    profileHeight = 175;
    activeSubscription = false;
    athletePersonalUserId = 'personal-user-1';
    calls.clear();
    Api.requestHandler = (path, {required method, body, required auth}) async {
      calls.add((path: path, method: method, body: body));
      if (path == '/api/user/profile' && method == 'PATCH') {
        if (body?['weightKg'] is num) {
          profileWeight = (body!['weightKg'] as num).toDouble();
        }
        if (body?['heightCm'] is num) {
          profileHeight = (body!['heightCm'] as num).toInt();
        }
        return {'message': 'Perfil atualizado'};
      }
      if (path == '/api/user/profile') {
        return {
          'id': 'user-1',
          'role': role,
          'name': 'Pessoa de teste',
          'email': 'teste@example.com',
          'athlete': {
            'name': 'Pessoa de teste',
            'personalUserId': athletePersonalUserId,
            'weightKg': profileWeight,
            'heightCm': profileHeight,
            'city': 'Jardins',
            'state': 'SP',
            'experienceLevel': 'intermediario',
          },
          'personal': {'name': 'Pessoa de teste', 'cref': '123456-G/SP'},
        };
      }
      if (path.startsWith('/api/workout-stats')) {
        return {
          'data': {
            'totalSessions': 2,
            'totalVolume': 1200,
            'totalCalories': 480,
            'totalDistance': 3.2,
            'avgHeartRate': 120,
            'chartData': {
              DateTime.now().toIso8601String().substring(0, 10): 600,
              DateTime.now()
                      .subtract(const Duration(days: 1))
                      .toIso8601String()
                      .substring(0, 10):
                  600,
            },
          },
        };
      }
      if (path.startsWith('/api/workout-sessions')) return {'data': []};
      if (path == '/api/social?feed=friends') {
        return seedSocialFeed
            ? [
                {
                  'id': 'post-1',
                  'user': {'id': 'user-2', 'displayName': 'Atleta da rede'},
                  'text': 'Treino compartilhado da rede',
                  '_count': {'likes': 3, 'comments': 1},
                },
              ]
            : {'posts': []};
      }
      if (path == '/api/challenges' && method == 'POST') {
        challengeJoined = true;
        return {'id': 'participant-1'};
      }
      if (path == '/api/friends?includeRequests=1' && method == 'GET') {
        return {
          'friends': [
            {'id': 'friend-1', 'displayName': 'Amiga existente'},
          ],
          'incomingRequests': friendRequestAnswered
              ? []
              : [
                  {
                    'id': 'friendship-1',
                    'displayName': 'Lucas Mendes',
                    'status': 'pending',
                  },
                ],
          'outgoingRequests': [],
        };
      }
      if (path == '/api/friends' && method == 'POST') {
        if (body?['action'] == 'respond') friendRequestAnswered = true;
        return {'id': body?['friendshipId'] ?? 'friendship-outgoing'};
      }
      if (path == '/api/challenges') {
        return [
          {
            'id': 'challenge-1',
            'name': 'Desafio de teste',
            'description': 'Desafio usado no teste de tela.',
            'participants': challengeJoined
                ? [
                    {'userId': 'user-1', 'displayName': 'Atleta teste'},
                  ]
                : [],
          },
        ];
      }
      if (path == '/api/challenges/challenge-1/leaderboard') {
        return [
          {
            'userId': 'user-2',
            'user': {'displayName': 'Camila Duarte'},
            'currentValue': 120,
          },
        ];
      }
      if (path == '/api/achievements') {
        return {
          'achievements': [
            {
              'id': 'achievement-1',
              'title': 'Primeira semana',
              'description': 'Complete sete dias de treino.',
              'icon': '🏋️',
              'xpReward': 100,
            },
            {
              'id': 'achievement-2',
              'title': 'Novo recorde',
              'description': 'Supere sua melhor marca.',
              'icon': '🏆',
              'xpReward': 150,
            },
          ],
          'userAchievements': [
            {
              'id': 'earned-1',
              'achievementId': 'achievement-1',
              'earnedAt': '2026-10-30T12:00:00.000Z',
            },
          ],
        };
      }
      if (path.startsWith('/api/appointments/slots')) {
        if (method == 'POST') return {'id': 'slot-created'};
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
      if (path == '/api/appointments' && method == 'POST') {
        return {'id': 'appointment-1'};
      }
      if (path == '/api/appointments') return [];
      if (path.startsWith('/api/nutrition/meals') && method == 'POST') {
        return {'id': 'meal-food-1'};
      }
      if (path.startsWith('/api/nutrition/meals')) {
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
      if (path == '/api/chat') {
        return {
          'text': 'Sugestão de progressão gradual para o atleta.',
          'workoutData': {
            'exercises': [
              {'name': 'Agachamento', 'sets': 3, 'reps': '8-10'},
            ],
          },
        };
      }
      if (path == '/api/personal-stats') {
        return {'athleteCount': 1, 'activeAthletes': 1};
      }
      if (path == '/api/athletes/athlete-1') {
        return {
          'id': 'athlete-1',
          'name': 'Atleta de teste',
          'objective': 'Forca',
          'experienceLevel': 'iniciante',
        };
      }
      if (path == '/api/progress?athleteId=athlete-1') {
        return {
          'data': [
            {
              'id': 'progress-1',
              'date': '2026-11-01T12:00:00.000Z',
              'weight': 80,
              'muscleMass': 32,
              'bodyFat': 18,
              'note': 'Avalia\u00e7\u00e3o inicial',
            },
          ],
        };
      }
      if (path == '/api/progress' && method == 'POST') {
        return {'id': 'progress-2'};
      }
      if (path.startsWith('/api/athletes')) {
        if (seedAthletePagination && method == 'GET') {
          if (path.contains('cursor=athlete-1')) {
            return {
              'data': [
                {'id': 'athlete-2', 'name': 'Segunda página'},
              ],
              'nextCursor': null,
              'hasMore': false,
            };
          }
          return {
            'data': [
              {'id': 'athlete-1', 'name': 'Atleta de teste'},
            ],
            'nextCursor': 'athlete-1',
            'hasMore': true,
          };
        }
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
                  'metric': 'sess\u00f5es',
                  'targetValue': 4,
                  'currentValue': 1,
                  'status': 'active',
                },
              ]
            : [];
      }
      if (path.startsWith('/api/programs')) {
        if (path == '/api/programs/prog-1') {
          return {
            'id': 'prog-1',
            'title': 'Programa teste',
            'description': 'Detalhes carregados',
            'durationWeeks': 4,
            'daysPerWeek': 3,
            'level': 'Intermedi?rio',
            'exercises': [
              {
                'week': 1,
                'day': 1,
                'name': 'Supino reto',
                'sets': 3,
                'reps': '8-10',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Crossover',
                'sets': 2,
                'reps': '12',
              },
            ],
          };
        }
        return seedProgram
            ? [
                {
                  'id': 'prog-1',
                  'title': 'Programa teste',
                  'description': 'Resumo',
                  'durationWeeks': 4,
                  'daysPerWeek': 3,
                },
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
            'createdAt': '2026-11-01T14:05:00',
          },
        ];
      }
      if (path == '/api/integrations' && method == 'POST') {
        return {'url': 'https://auth.example.com/authorize'};
      }
      if (path == '/api/integrations' || path == '/api/subscriptions') {
        return [];
      }
      if (path == '/api/subscriptions/me') {
        return {
          'data': activeSubscription
              ? {'plan': 'WeGYM PRO Athlete', 'status': 'active'}
              : null,
        };
      }
      if (path == '/api/user/export') {
        return {
          'user': {'id': 'user-1', 'email': 'teste@example.com'},
        };
      }
      if (path == '/api/checkin') return {'today': null, 'streak': 0};
      if (path == '/api/medidas') return [];
      return {};
    };
  });

  tearDown(() {
    Api.requestHandler = null;
    ProfileDataExport.saveHandler = null;
    integrationReturnLink.value = null;
  });

  testWidgets('all remaining modules render at mobile and desktop widths', (
    tester,
  ) async {
    const modules = <(String, String)>[
      ('Comunidade', 'COMUNIDADE'),
      ('Conquistas', 'CONQUISTAS DO ATLETA'),
      ('Analytics & Performance', 'ANALYTICS'),
      ('Agendamentos', 'AGENDAMENTOS'),
      ('Nutri\u00e7\u00e3o', 'NUTRI'),
      ('Alunos & Personal', 'GEST'),
      ('Metas & Desafios', 'METAS'),
      ('Programas', 'PROGRAMAS'),
      ('Chat', 'CANAL ATLETA'),
      ('Perfil & Configura\u00e7\u00f5es', 'PERFIL'),
      ('Planos PRO', 'PLANOS WEGYM'),
      ('Medidas', 'AVALIA'),
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
        await _pumpUi(tester);
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

  testWidgets('analytics shows real metrics, chart, and period controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Analytics & Performance'),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('7 DIAS'), findsOneWidget);
    expect(find.text('30 DIAS'), findsOneWidget);
    expect(find.text('12 MESES'), findsOneWidget);
    expect(find.text('TEMPO DE TREINO'), findsOneWidget);
    expect(find.text('Calorias'), findsOneWidget);
    expect(find.text('Distancia'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('30 DIAS'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('12 MESES'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('athlete loads and books slots from their linked personal', (
    tester,
  ) async {
    seedSlot = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Agendamentos')),
      ),
    );
    await _pumpUi(tester);

    expect(
      calls.any(
        (call) =>
            call.path == '/api/appointments/slots?personalId=personal-user-1',
      ),
      isTrue,
    );
    final reserve = find.text('RESERVAR');
    await tester.ensureVisible(reserve);
    await tester.tap(reserve);
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/appointments' &&
            call.method == 'POST' &&
            call.body?['slotId'] == 'slot-1',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('Personal creates available appointment slots', (tester) async {
    role = 'personal';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Agendamentos')),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('NOVO HORÁRIO'), findsOneWidget);
    expect(find.text('RESERVAR'), findsNothing);
    await tester.tap(find.text('NOVO HORÁRIO'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await _pumpUi(tester);

    final createCall = calls.where(
      (call) => call.path == '/api/appointments/slots' && call.method == 'POST',
    );
    expect(createCall, hasLength(1));
    expect(createCall.single.body?['date'], isNotEmpty);
    expect(createCall.single.body?['startTime'], '09:00');
    expect(createCall.single.body?['endTime'], '10:00');
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('nutrition selects a date and creates a localized meal type', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Nutri\u00e7\u00e3o')),
      ),
    );
    await _pumpUi(tester);

    expect(
      calls.any((call) => call.path.startsWith('/api/nutrition/meals?date=')),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('nutrition-select-date')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('15').first);
    await tester.tap(find.text('OK'));
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) =>
            call.path.startsWith('/api/nutrition/meals?date=') &&
            call.path.endsWith('-15'),
      ),
      isTrue,
    );

    final createMeal = find.text('REGISTRAR REFEI\u00c7\u00c3O');
    await tester.ensureVisible(createMeal);
    await tester.pumpAndSettle();
    await tester.tap(createMeal);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Caf\u00e9 da manh\u00e3'));
    await _pumpUi(tester);

    expect(
      calls.any(
        (call) =>
            call.path == '/api/nutrition/meals' &&
            call.method == 'POST' &&
            call.body?['type'] == 'breakfast' &&
            call.body?['date'] is String &&
            (call.body?['date'] as String).endsWith('-15'),
      ),
      isTrue,
    );
  }, skip: _isPreview);

  testWidgets(
    'achievement catalog distinguishes earned and locked rewards',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Conquistas')),
        ),
      );
      await _pumpUi(tester);

      expect(find.text('Primeira semana'), findsOneWidget);
      expect(find.text('Novo recorde'), findsOneWidget);
      expect(find.text('CONQUISTADAS'), findsOneWidget);
      expect(find.text('BLOQUEADA'), findsWidgets);
      expect(find.text('EM 30/10/2026'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    skip: _isPreview,
  );

  testWidgets('profile exports backend data as a JSON file', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? savedName;
    String? savedJson;
    ProfileDataExport.saveHandler = (name, bytes) async {
      savedName = name;
      savedJson = utf8.decode(bytes);
      return 'saved-file.json';
    };
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);
    final exportButton = find.text('EXPORTAR MEUS DADOS');
    for (
      var i = 0;
      i < 6 &&
          !tester
              .getRect(exportButton)
              .overlaps(Offset.zero & tester.view.physicalSize);
      i++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(exportButton);
    await tester.tap(exportButton);
    await _pumpUi(tester);

    expect(
      calls.any(
        (call) => call.path == '/api/user/export' && call.method == 'GET',
      ),
      isTrue,
    );
    expect(savedName, 'dados-pessoais');
    expect(jsonDecode(savedJson!)['user']['email'], 'teste@example.com');
    expect(
      find.text('Arquivo de dados exportado com sucesso.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('account deletion requires typing EXCLUIR and ends session', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(
            module: 'Perfil & Configura\u00e7\u00f5es',
            onLogout: () => loggedOut = true,
          ),
        ),
      ),
    );
    await _pumpUi(tester);

    final deleteButton = find.text('EXCLUIR CONTA');
    for (
      var i = 0;
      i < 6 &&
          !tester
              .getRect(deleteButton)
              .overlaps(Offset.zero & tester.view.physicalSize);
      i++
    ) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await _pumpUi(tester);
    expect(
      find.byKey(const ValueKey('account-delete-confirmation')),
      findsOneWidget,
    );
    expect(find.text('EXCLUIR'), findsOneWidget);

    final confirmField = find.byKey(
      const ValueKey('account-delete-confirmation'),
    );
    await tester.enterText(confirmField, 'APAGAR');
    await _pumpUi(tester);
    expect(calls.any((call) => call.path == '/api/user/account'), isFalse);

    await tester.enterText(confirmField, 'EXCLUIR');
    await _pumpUi(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'EXCLUIR'));
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) => call.path == '/api/user/account' && call.method == 'DELETE',
      ),
      isTrue,
    );
    expect(loggedOut, isTrue);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('profile opens the provider OAuth authorization link', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);
    await tester.ensureVisible(find.text('CONECTAR STRAVA'));
    await tester.tap(find.text('CONECTAR STRAVA'));
    await _pumpUi(tester);

    expect(
      calls.any(
        (call) =>
            call.path == '/api/integrations' &&
            call.method == 'POST' &&
            call.body?['provider'] == 'strava' &&
            call.body?['platform'] == 'flutter_native',
      ),
      isTrue,
    );
    expect(find.text('ABRIR NO NAVEGADOR'), findsOneWidget);
    expect(find.text('https://auth.example.com/authorize'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('OAuth return refreshes integrations and reports the result', (
    tester,
  ) async {
    integrationReturnLink.value = Uri.parse(
      'wegym://integration-return?integration=strava&integration_result=success',
    );
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(
      find.text(
        'Strava conectado. As integra\u00e7\u00f5es foram atualizadas.',
      ),
      findsOneWidget,
    );
    expect(
      calls.where((call) => call.path == '/api/integrations').length,
      greaterThanOrEqualTo(2),
    );
    expect(integrationReturnLink.value, isNull);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('athlete profile edits measurements using the profile API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('76.2 kg'), findsOneWidget);
    expect(find.text('175 cm'), findsOneWidget);
    expect(find.textContaining('24.9'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar peso'));
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField).last, '80,5');
    await tester.tap(find.text('CONTINUAR'));
    await _pumpUi(tester);

    expect(find.text('80.5 kg'), findsOneWidget);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/user/profile' &&
            call.method == 'PATCH' &&
            call.body?['weightKg'] == 80.5,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('profile resource shortcuts and plan use main navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var navigatedTo = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(
            module: 'Perfil & Configura\u00e7\u00f5es',
            onNavigate: (page) => navigatedTo = page,
          ),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Plano gratuito'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-resource-8-0')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-resource-8-0')));
    expect(navigatedTo, 8);

    await tester.ensureVisible(find.text('CONHECER PLANOS'));
    await tester.tap(find.text('CONHECER PLANOS'));
    expect(navigatedTo, 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile displays active plan returned by backend', (
    tester,
  ) async {
    activeSubscription = true;
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('WeGYM PRO Athlete'), findsOneWidget);
    expect(find.text('VER ASSINATURA'), findsOneWidget);
    expect(calls.any((call) => call.path == '/api/subscriptions/me'), isTrue);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets(
    'profile shows account identity and explains avatar limitation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
          ),
        ),
      );
      await _pumpUi(tester);

      expect(find.text('IDENTIDADE'), findsOneWidget);
      expect(find.text('Pessoa de teste'), findsOneWidget);
      expect(find.text('Atleta'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-avatar-fallback')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Alterar foto (em breve)'));
      await tester.pump();
      expect(
        find.text('A troca da foto de perfil ainda não está disponível.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
    skip: _isPreview,
  );

  testWidgets('PWA install fallback explains browser menu steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PwaInstallCard())),
    );
    await tester.pumpAndSettle();

    expect(find.text('INSTALAR O WEGYM'), findsOneWidget);
    await tester.tap(find.text('INSTALAR O WEGYM'));
    await tester.pump();
    expect(find.textContaining('No menu do navegador'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Personal profile shows CREF and hides athlete measurements', (
    tester,
  ) async {
    role = 'personal';
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FigmaModulePage(module: 'Perfil & Configura\u00e7\u00f5es'),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('123456-G/SP'), findsOneWidget);
    expect(find.byTooltip('Editar peso'), findsNothing);
    expect(find.byTooltip('Editar altura'), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets(
    'chat opens a conversation and sends a message to its contact',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Chat')),
        ),
      );
      await _pumpUi(tester);
      await tester.tap(find.text('ABRIR'));
      await _pumpUi(tester);
      expect(find.text('Mensagem de teste'), findsOneWidget);
      expect(find.text('14:05'), findsOneWidget);
      expect(
        calls.any((call) => call.path == '/api/messages/contact-1'),
        isTrue,
      );
      await tester.enterText(find.byType(TextField).last, 'Olá, coach');
      await tester.tap(find.text('ENVIAR'));
      await _pumpUi(tester);
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
    },
    skip: _isPreview,
  );

  testWidgets('program detail adapts to mobile and desktop widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: ProgramDetailPage(programId: 'prog-1')),
      );
      await _pumpUi(tester);
      expect(find.text('SEMANA 1'), findsOneWidget);
      expect(find.text('Supino reto'), findsOneWidget);
      expect(find.text('Crossover'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Program detail at $size');
    }
  }, skip: _isPreview);

  testWidgets('program catalog opens a detail page and returns', (
    tester,
  ) async {
    seedProgram = true;
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Programas')),
      ),
    );
    await _pumpUi(tester);
    final details = find.text('DETALHES').first;
    await tester.ensureVisible(details);
    await tester.tap(details);
    await _pumpUi(tester);

    expect(find.text('PROGRAMA TESTE'), findsOneWidget);
    expect(find.text('SEMANA 1'), findsOneWidget);
    expect(find.text('Supino reto'), findsOneWidget);
    expect(calls.any((call) => call.path == '/api/programs/prog-1'), isTrue);

    await tester.tap(find.byTooltip('Voltar aos programas'));
    await _pumpUi(tester);
    expect(find.textContaining('PROGRAMAS DE TREINAMENTO'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('challenge ranking adapts to mobile and desktop widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: ChallengeLeaderboardPage(challengeId: 'challenge-1'),
        ),
      );
      await _pumpUi(tester);
      expect(find.text('RANKING'), findsOneWidget);
      expect(find.text('Camila Duarte'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Ranking at $size');
    }
  }, skip: _isPreview);

  testWidgets('community challenge ranking opens a page and returns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Comunidade')),
      ),
    );
    await _pumpUi(tester);

    final openRanking = find.text('VER RANKING').first;
    await tester.ensureVisible(openRanking);
    await tester.tap(openRanking);
    await _pumpUi(tester);

    expect(find.text('RANKING'), findsOneWidget);
    expect(find.text('Camila Duarte'), findsOneWidget);
    expect(find.text('120 pontos'), findsOneWidget);
    expect(
      calls.any(
        (call) => call.path == '/api/challenges/challenge-1/leaderboard',
      ),
      isTrue,
    );

    await tester.tap(find.byTooltip('Voltar aos desafios'));
    await _pumpUi(tester);
    expect(find.textContaining('COMUNIDADE'), findsWidgets);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('athlete joins a community challenge through the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Comunidade')),
      ),
    );
    await _pumpUi(tester);

    final join = find.text('PARTICIPAR').first;
    await tester.ensureVisible(join);
    await tester.tap(join);
    await _pumpUi(tester);

    expect(find.text('PARTICIPANDO'), findsOneWidget);
    expect(find.text('Atleta teste'), findsWidgets);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/challenges' &&
            call.method == 'POST' &&
            call.body?['challengeId'] == 'challenge-1',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('community feed accepts the original list response', (
    tester,
  ) async {
    seedSocialFeed = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Comunidade')),
      ),
    );
    await _pumpUi(tester);

    expect(find.textContaining('Treino compartilhado da rede'), findsOneWidget);
    expect(
      calls.any((call) => call.path == '/api/social?feed=friends'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('goal progress is presented in separate readable sections', (
    tester,
  ) async {
    seedGoal = true;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Metas & Desafios')),
        ),
      );
      await _pumpUi(tester);

      expect(find.text('Meta de teste'), findsOneWidget);
      expect(find.text('1 de 4 sess\u00f5es'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Em andamento'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Goal card at $size');
    }
  }, skip: _isPreview);

  testWidgets('goal create, progress, completion and delete use the API', (
    tester,
  ) async {
    seedGoal = true;
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Metas & Desafios')),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('NOVA META'));
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField).last, 'Treinar 5 vezes');
    await tester.tap(find.text('CONTINUAR'));
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.tap(find.text('CONTINUAR'));
    await _pumpUi(tester);

    expect(
      calls.any(
        (call) =>
            call.path == '/api/goals' &&
            call.method == 'POST' &&
            call.body?['title'] == 'Treinar 5 vezes' &&
            call.body?['targetValue'] == 5 &&
            call.body?['metric'] == 'sessions',
      ),
      isTrue,
    );

    final update = find.byTooltip('Atualizar progresso');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await _pumpUi(tester);
    await tester.enterText(find.byType(TextField).last, '2');
    await tester.tap(find.text('CONTINUAR'));
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/goals' &&
            call.method == 'PATCH' &&
            call.body?['id'] == 'goal-1' &&
            call.body?['currentValue'] == 2.0,
      ),
      isTrue,
    );

    final complete = find.text('CONCLUIR');
    await tester.ensureVisible(complete);
    await tester.tap(complete);
    await _pumpUi(tester);
    await tester.tap(find.text('CONFIRMAR'));
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/goals' &&
            call.method == 'PATCH' &&
            call.body?['id'] == 'goal-1' &&
            call.body?['currentValue'] == 4,
      ),
      isTrue,
    );

    final delete = find.byTooltip('Excluir meta');
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await _pumpUi(tester);
    await tester.tap(find.text('EXCLUIR'));
    await _pumpUi(tester);
    expect(
      calls.any(
        (call) =>
            call.path == '/api/goals' &&
            call.method == 'DELETE' &&
            call.body?['id'] == 'goal-1',
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets(
    'Personal can create, edit and unlink students through the API',
    (tester) async {
      role = 'personal';
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Alunos & Personal')),
        ),
      );
      await _pumpUi(tester);

      Future<void> fill(String field, String value) async {
        final input = find.byKey(ValueKey('student-$field'));
        await tester.ensureVisible(input);
        await tester.enterText(input, value);
      }

      await tester.tap(find.text('NOVO ALUNO'));
      await _pumpUi(tester);
      await fill('name', 'Novo Atleta');
      await fill('email', 'novo.atleta@example.com');
      await fill('cpf', '52998224725');
      await fill('height', '180');
      await fill('weight', '82');
      await fill('cep', '01001000');
      await fill('city', 'Sao Paulo');
      await fill('state', 'SP');
      await tester.ensureVisible(find.text('CRIAR ALUNO'));
      await tester.tap(find.text('CRIAR ALUNO'));
      await _pumpUi(tester);

      expect(
        calls.any(
          (call) =>
              call.path == '/api/athletes/register' &&
              call.method == 'POST' &&
              call.body?['name'] == 'Novo Atleta' &&
              call.body?['sex'] == 'masculino' &&
              call.body?['experienceLevel'] == 'iniciante',
        ),
        isTrue,
      );

      await tester.tap(find.text('Atleta de teste').last);
      await _pumpUi(tester);
      await tester.tap(find.text('VER EVOLU\u00c7\u00c3O'));
      await _pumpUi(tester);
      expect(
        find.textContaining('Avalia\u00e7\u00e3o inicial'),
        findsOneWidget,
      );
      expect(
        calls.any((call) => call.path == '/api/progress?athleteId=athlete-1'),
        isTrue,
      );

      await tester.tap(find.text('REGISTRAR AVALIA\u00c7\u00c3O'));
      await _pumpUi(tester);
      await fill('progress-weight', '81.5');
      await fill('progress-muscle', '33');
      await fill('progress-body-fat', '17.5');
      await fill('progress-note', 'Nova avaliacao');
      await tester.ensureVisible(find.text('SALVAR AVALIA\u00c7\u00c3O'));
      await tester.tap(find.text('SALVAR AVALIA\u00c7\u00c3O'));
      await _pumpUi(tester);
      expect(
        calls.any(
          (call) =>
              call.path == '/api/progress' &&
              call.method == 'POST' &&
              call.body?['athleteId'] == 'athlete-1' &&
              call.body?['weight'] == 81.5 &&
              call.body?['muscleMass'] == 33.0 &&
              call.body?['bodyFat'] == 17.5 &&
              call.body?['note'] == 'Nova avaliacao' &&
              call.body?['date'] != null,
        ),
        isTrue,
      );
      await tester.tap(find.text('FECHAR'));
      await _pumpUi(tester);

      final studentActions = find.byTooltip(
        'A\u00e7\u00f5es de Atleta de teste',
      );
      await tester.ensureVisible(studentActions);
      await tester.tap(studentActions);
      await _pumpUi(tester);
      await tester.tap(find.text('Editar dados'));
      await _pumpUi(tester);
      await fill('objective', 'Forca e condicionamento');
      await tester.ensureVisible(find.text('SALVAR ALTERA\u00c7\u00d5ES'));
      await tester.tap(find.text('SALVAR ALTERA\u00c7\u00d5ES'));
      await _pumpUi(tester);

      expect(
        calls.any(
          (call) =>
              call.path == '/api/athletes/athlete-1' &&
              call.method == 'PATCH' &&
              call.body?['objective'] == 'Forca e condicionamento',
        ),
        isTrue,
      );

      await tester.ensureVisible(studentActions);
      await tester.tap(studentActions);
      await _pumpUi(tester);
      await tester.tap(find.text('Desvincular do Personal'));
      await _pumpUi(tester);
      await tester.tap(find.text('DESVINCULAR'));
      await _pumpUi(tester);

      expect(
        calls.any(
          (call) =>
              call.path == '/api/athletes/athlete-1' && call.method == 'DELETE',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
    skip: _isPreview,
  );

  testWidgets('Personal list loads the next athlete page from its cursor', (
    tester,
  ) async {
    role = 'personal';
    seedAthletePagination = true;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Alunos & Personal')),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('Atleta de teste'), findsOneWidget);
    expect(find.byKey(const ValueKey('load-more-athletes')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('load-more-athletes')));
    await _pumpUi(tester);

    expect(find.text('Segunda página'), findsOneWidget);
    expect(
      calls.any(
        (call) =>
            call.path.contains('/api/athletes?take=20') &&
            call.path.contains('cursor=athlete-1'),
      ),
      isTrue,
    );
    expect(find.byKey(const ValueKey('load-more-athletes')), findsNothing);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets('athlete cannot load the Personal-only management data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Alunos & Personal')),
      ),
    );
    await _pumpUi(tester);
    expect(find.textContaining('exclusiva'), findsOneWidget);
    expect(
      find.text(
        'Área exclusiva para contas Personal. Seu perfil está cadastrado como Atleta.',
      ),
      findsOneWidget,
    );
    expect(calls.any((call) => call.path.startsWith('/api/athletes')), isFalse);
  }, skip: _isPreview);

  testWidgets('Personal Gemini sends preview questions to the backend', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PersonalCopilotSheet(
            student: {
              'name': 'Atleta Demo',
              'experienceLevel': 'intermediario',
            },
          ),
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.enterText(
      find.byKey(const ValueKey('personal-copilot-input')),
      'Como organizar a semana?',
    );
    await tester.tap(find.byKey(const ValueKey('personal-copilot-send')));
    await _pumpUi(tester);

    expect(find.text('Gemini conectado ao backend'), findsOneWidget);
    expect(find.textContaining('gradual para o atleta.'), findsOneWidget);
    expect(calls.any((call) => call.path == '/api/chat'), isTrue);
    expect(tester.takeException(), isNull);
  }, skip: !_isPreview);
  testWidgets('Personal Gemini uses the selected athlete context', (
    tester,
  ) async {
    role = 'personal';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FigmaModulePage(module: 'Alunos & Personal')),
      ),
    );
    await _pumpUi(tester);

    final athlete = find.text('Atleta de teste').first;
    await tester.ensureVisible(athlete);
    await tester.tap(athlete);
    await _pumpUi(tester);
    await tester.tap(find.byKey(const ValueKey('personal-copilot-student')));
    await _pumpUi(tester);

    expect(find.text('Gemini IA · Atleta de teste'), findsOneWidget);
    final input = find.byKey(const ValueKey('personal-copilot-input'));
    await tester.enterText(input, 'Sugira uma progressão de força');
    await tester.tap(find.byKey(const ValueKey('personal-copilot-send')));
    await _pumpUi(tester);

    final request = calls.firstWhere((call) => call.path == '/api/chat');
    expect(
      request.body?['message'],
      '[Personal Coach] Sugira uma progressão de força (aluno: Atleta de teste)',
    );
    expect(request.body?['level'], 'Iniciante');
    expect(
      find.text('Sugestão de progressão gradual para o atleta.'),
      findsOneWidget,
    );
    expect(find.textContaining('Agachamento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: _isPreview);

  testWidgets(
    'friends screen sends email invites and responds to requests',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Amigos')),
        ),
      );
      await _pumpUi(tester);

      expect(find.text('Lucas Mendes'), findsOneWidget);
      expect(find.text('Amiga existente'), findsOneWidget);
      await tester.tap(find.byTooltip('Aceitar solicitação de Lucas Mendes'));
      await _pumpUi(tester);
      expect(
        calls.any(
          (call) =>
              call.path == '/api/friends' &&
              call.method == 'POST' &&
              call.body?['action'] == 'respond' &&
              call.body?['friendshipId'] == 'friendship-1' &&
              call.body?['response'] == 'accept',
        ),
        isTrue,
      );
      expect(find.text('Nenhuma solicitação pendente.'), findsOneWidget);

      await tester.tap(find.text('ADICIONAR AMIGO'));
      await _pumpUi(tester);
      await tester.enterText(find.byType(TextField).last, 'novo@example.com');
      await tester.tap(find.text('CONTINUAR'));
      await _pumpUi(tester);
      expect(
        calls.any(
          (call) =>
              call.path == '/api/friends' &&
              call.method == 'POST' &&
              call.body?['addresseeEmail'] == 'novo@example.com',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
    skip: _isPreview,
  );
}
