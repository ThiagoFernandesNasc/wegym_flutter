import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/figma_modules.dart';

void main() {
  testWidgets(
    'demo community shows hypothetical participants and records participation',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      Api.requestHandler = null;
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Comunidade')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.text('PARTICIPANTES DE DEMONSTRA\u00c7\u00c3O'),
        findsWidgets,
      );
      expect(find.text('Camila Duarte'), findsWidgets);
      expect(find.text('Marcos Silva'), findsWidgets);
      expect(
        find.text('Nomes fict\u00edcios para a apresenta\u00e7\u00e3o.'),
        findsWidgets,
      );

      final join = find.text('PARTICIPAR').first;
      await tester.ensureVisible(join);
      await tester.tap(join);
      await tester.pumpAndSettle();

      expect(find.text('PARTICIPANDO'), findsOneWidget);
      expect(find.text('Voc\u00ea'), findsOneWidget);
      expect(
        find.textContaining(
          'Participa\u00e7\u00e3o registrada nesta pr\u00e9via',
        ),
        findsOneWidget,
      );
      final openRanking = find.text('VER RANKING').first;
      await tester.ensureVisible(openRanking);
      await tester.tap(openRanking);
      await tester.pumpAndSettle();
      expect(find.text('RANKING'), findsOneWidget);
      expect(find.text('2450 pontos'), findsOneWidget);
      expect(
        find.text(
          'PR\u00c9VIA \u00b7 PARTICIPANTES FICT\u00cdCIOS \u00b7 a\u00e7\u00f5es n\u00e3o s\u00e3o salvas.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Voltar aos desafios'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo community publishes posts and toggles likes locally',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var requestCount = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requestCount++;
            throw StateError('Demo social actions must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Comunidade')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(find.text('PUBLICAR'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Treino concluído!');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Treino concluído!'), findsOneWidget);
      expect(find.text('Publicação criada nesta prévia.'), findsOneWidget);

      final like = find.byTooltip('Curtir').first;
      await tester.ensureVisible(like);
      await tester.tap(like);
      await tester.pumpAndSettle();
      expect(find.text('Curtida registrada nesta prévia.'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byTooltip('Comentar').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Boa sessão!');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Comentário adicionado nesta prévia.'), findsOneWidget);
      expect(requestCount, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo program detail uses local data without requesting the backend',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var requestCount = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requestCount++;
            throw StateError('The demo program must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Programas')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final details = find.text('DETALHES').first;
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();

      expect(find.text('HIPERTROFIA EM 8 SEMANAS'), findsOneWidget);
      expect(
        find.text(
          'PR\u00c9VIA \u00b7 DADOS DE DEMONSTRA\u00c7\u00c3O \u00b7 a\u00e7\u00f5es n\u00e3o s\u00e3o salvas.',
        ),
        findsOneWidget,
      );
      expect(requestCount, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo athlete creates a diet plan locally without calling the backend',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var requestCount = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requestCount++;
            throw StateError('Demo plan creation must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Nutrição')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final create = find.text('CRIAR PLANO');
      for (
        var i = 0;
        i < 8 &&
            !tester
                .getRect(create)
                .overlaps(Offset.zero & tester.view.physicalSize);
        i++
      ) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(create);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'Plano de demonstração',
      );
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '2200');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();

      expect(find.text('Plano de demonstração'), findsOneWidget);
      expect(find.text('2200 kcal por dia'), findsOneWidget);
      expect(find.text('Plano alimentar criado nesta prévia.'), findsOneWidget);
      expect(requestCount, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo athlete records a meal locally without calling the backend',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var requestCount = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requestCount++;
            throw StateError('Demo meal creation must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Nutrição')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final initialDinners = find.text('Jantar').evaluate().length;
      final register = find.text('REGISTRAR REFEIÇÃO');
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jantar'));
      await tester.pumpAndSettle();

      expect(find.text('Jantar'), findsOneWidget);
      expect(find.text('Refeição registrada nesta prévia.'), findsOneWidget);
      expect(
        find.text('Jantar').evaluate().length,
        greaterThan(initialDinners),
      );
      final addFood = find.text('ADICIONAR ALIMENTO').first;
      await tester.ensureVisible(addFood);
      await tester.tap(addFood);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'frango');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peito de frango grelhado • 165 kcal'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '1.5');
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();

      expect(find.text('Alimento adicionado nesta prévia.'), findsOneWidget);
      final addedFood = find.textContaining('Peito de frango grelhado × 1.5');
      await tester.ensureVisible(addedFood);
      expect(addedFood, findsOneWidget);
      expect(find.textContaining('248 kcal'), findsOneWidget);
      expect(find.textContaining('47 g de proteína'), findsOneWidget);
      expect(requestCount, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );

  testWidgets(
    'demo athlete books then cancels an appointment locally',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      var requestCount = 0;
      Api.requestHandler =
          (path, {required method, body, required auth}) async {
            requestCount++;
            throw StateError('Demo appointments must remain local.');
          };
      addTearDown(() => Api.requestHandler = null);
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FigmaModulePage(module: 'Agendamentos')),
        ),
      );
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final reserve = find.text('RESERVAR').first;
      await tester.ensureVisible(reserve);
      await tester.tap(reserve);
      await tester.pumpAndSettle();
      expect(find.text('Carlos Personal'), findsOneWidget);
      expect(find.text('Agendamento solicitado nesta prévia.'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancelar agendamento').first);
      await tester.pumpAndSettle();
      expect(find.text('Agendamento cancelado nesta prévia.'), findsOneWidget);
      expect(find.textContaining('cancelled'), findsOneWidget);
      expect(requestCount, 0);
      expect(tester.takeException(), isNull);
    },
    skip: !const bool.fromEnvironment('PREVIEW_DASHBOARD'),
  );
}
