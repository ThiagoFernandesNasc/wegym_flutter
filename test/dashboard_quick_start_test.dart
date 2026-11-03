import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/dashboard.dart';

void main() {
  test(
    'navigation state persists the selected modality across reloads',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      await Api.saveNavigationState(
        21,
        [0],
        modality: 'combat',
        gpsActivity: 'Ciclismo',
      );

      final saved = await Api.navigationState();
      expect(saved?['index'], 21);
      expect(saved?['modality'], 'combat');
      expect(saved?['gpsActivity'], 'Ciclismo');
    },
  );

  testWidgets('dashboard shows history-based favorite and quick modalities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final selectedModalities = <String>[];
    final sessions = [
      {'modality': 'ciclismo', 'durationSec': 3600},
      {'modality': 'ciclismo', 'durationSec': 2700},
      {'modality': 'corrida', 'durationSec': 1800},
    ];
    final data = <dynamic>[
      {
        'role': 'atleta',
        'athlete': {'name': 'Joao Silva'},
      },
      {
        'totalSessions': 3,
        'totalVolume': 8100,
        'totalLiftedVolumeKg': 38450,
        'totalDistance': 14.2,
      },
      {'totalSessions': 3, 'totalCalories': 920},
      sessions,
      <dynamic>[],
      {'posts': <dynamic>[]},
      [
        {
          'id': 'goal-1',
          'title': 'Treinar 12 vezes no mês',
          'category': 'workout',
          'metric': 'sessions',
          'targetValue': 12,
          'currentValue': 9,
          'status': 'active',
        },
      ],
    ];

    final destinations = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FigmaDashboard(
            data: Future.value(data),
            onReload: () async {},
            onStart: () {},
            onStartModality: selectedModalities.add,
            onNavigate: destinations.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SUA MODALIDADE FAVORITA'), findsOneWidget);
    expect(find.text('Ciclismo'), findsNWidgets(3));
    expect(find.text('INÍCIO RÁPIDO'), findsOneWidget);
    expect(find.text('38.450 kg'), findsOneWidget);
    expect(find.text('META ATIVA'), findsOneWidget);
    expect(find.text('Treinar 12 vezes no mês'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('3 / 22'), findsNothing);

    final manageGoals = find.byKey(const ValueKey('dashboard-manage-goals'));
    await tester.scrollUntilVisible(manageGoals, 250);
    await tester.pumpAndSettle();
    await tester.tap(manageGoals);
    expect(destinations.last, 8);

    final favoriteButton = find.text('TREINAR AGORA');
    await tester.scrollUntilVisible(favoriteButton, 250);
    await tester.pumpAndSettle();
    await tester.tap(favoriteButton);
    expect(selectedModalities.last, 'cycling');

    final aerobicButton = find.widgetWithText(OutlinedButton, 'Aeróbico');
    await tester.scrollUntilVisible(aerobicButton, 250);
    await tester.pumpAndSettle();
    await tester.tap(aerobicButton);
    expect(selectedModalities.last, 'aerobic');
    expect(tester.takeException(), isNull);
  });
}
