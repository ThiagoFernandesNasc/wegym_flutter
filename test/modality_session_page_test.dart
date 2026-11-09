import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/modality_session_page.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Api.requestHandler = null;
  });

  tearDown(() => Api.requestHandler = null);

  testWidgets('activity session adapts to compact and wide screens', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        const MaterialApp(home: ModalitySessionPage(preview: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('NATAÇÃO'), findsOneWidget);
      expect(find.text('ESCOLHA A MODALIDADE'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'layout at $size');
    }
  });

  testWidgets('swimming session records laps and saves through the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final requests =
        <({String path, String method, Map<String, dynamic>? body})>[];
    Api.requestHandler = (path, {required method, body, required auth}) async {
      requests.add((path: path, method: method, body: body));
      return {'id': 'session-1'};
    };

    await tester.pumpWidget(const MaterialApp(home: ModalitySessionPage()));
    await tester.pumpAndSettle();
    final startButton = find.text('INICIAR / RETOMAR');
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    await tester.tap(startButton);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
    );
    await tester.pump(const Duration(milliseconds: 250));
    final lapButton = find.text('REGISTRAR VOLTA');
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(lapButton);
    final finishButton = find.text('CONCLUIR E SALVAR');
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 300));
    // The session ticker keeps scheduling frames until completion.
    await tester.pump();
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    expect(
      requests.any(
        (request) =>
            request.path == '/api/workout-sessions' &&
            request.method == 'POST' &&
            request.body?['modality'] == 'swimming' &&
            request.body?['durationSec'] is int &&
            (request.body?['durationSec'] as int) >= 1 &&
            request.body?['distanceKm'] == 0.025,
      ),
      isTrue,
    );
    expect(find.text('Sessão salva no histórico.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
