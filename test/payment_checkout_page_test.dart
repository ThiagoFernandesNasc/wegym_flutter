import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegym_flutter/api.dart';
import 'package:wegym_flutter/payment_checkout_page.dart';

void main() {
  const isPreview = bool.fromEnvironment('PREVIEW_DASHBOARD');
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    Api.requestHandler = null;
  });
  tearDown(() => Api.requestHandler = null);

  testWidgets('annual plan creates and opens the secure Mercado Pago checkout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls =
        <({String path, String method, Map<String, dynamic>? body})>[];
    Uri? openedUri;
    Api.requestHandler = (path, {required method, body, required auth}) async {
      calls.add((path: path, method: method, body: body));
      if (path == '/api/payment-preference') {
        return {
          'url':
              'https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=test',
          'planId': 'anual',
          'amount': 399.9,
          'webhookConfigured': true,
        };
      }
      if (path == '/api/subscriptions/me') return {'data': null};
      return {};
    };

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentCheckoutPage(
          planId: 'anual',
          launchCheckout: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 399,90'), findsOneWidget);
    await tester.tap(find.text('CONTINUAR PARA O MERCADO PAGO'));
    await tester.pumpAndSettle();
    expect(
      calls.any(
        (call) =>
            call.path == '/api/payment-preference' &&
            call.method == 'POST' &&
            call.body?['planId'] == 'anual' &&
            call.body?['platform'] == 'native',
      ),
      isTrue,
    );

    await tester.ensureVisible(find.text('ABRIR CHECKOUT SEGURO'));
    await tester.tap(find.text('ABRIR CHECKOUT SEGURO'));
    await tester.pumpAndSettle();
    expect(openedUri?.host, 'www.mercadopago.com.br');
    expect(find.textContaining('Conclua o pagamento'), findsOneWidget);

    await tester.ensureVisible(find.text('VERIFICAR ASSINATURA'));
    await tester.tap(find.text('VERIFICAR ASSINATURA'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ainda não há uma assinatura ativa'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, skip: isPreview);
}
