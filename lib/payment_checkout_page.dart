import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'stitch_design_system.dart';

typedef CheckoutUrlLauncher = Future<bool> Function(Uri uri);

class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({
    super.key,
    required this.planId,
    this.launchCheckout,
  });

  final String planId;
  final CheckoutUrlLauncher? launchCheckout;

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  bool _creatingCheckout = false;
  bool _openingCheckout = false;
  bool _checkingSubscription = false;
  Uri? _checkoutUri;
  String? _message;
  bool _messageIsError = false;
  bool _returnUrlMissing = false;

  bool get _isPreview => const bool.fromEnvironment('PREVIEW_DASHBOARD');
  bool get _isAnnual => widget.planId == 'anual';
  String get _planName => _isAnnual ? 'WEGYM PRO ANUAL' : 'WEGYM PRO MENSAL';
  String get _price => _isAnnual ? 'R\$ 399,90' : 'R\$ 49,90';
  String get _billing => _isAnnual ? 'cobrança anual' : 'cobrança mensal';

  Future<void> _createCheckout() async {
    if (_isPreview) {
      setState(() {
        _message =
            'A prévia é demonstrativa. O checkout exige uma conta autenticada e configuração do Mercado Pago.';
        _messageIsError = false;
      });
      return;
    }
    setState(() {
      _creatingCheckout = true;
      _checkoutUri = null;
      _message = null;
    });
    try {
      final response = Map<String, dynamic>.from(
        await Api.post('/api/payment-preference', {
              'planId': widget.planId,
              'platform': kIsWeb ? 'web' : 'native',
            })
            as Map,
      );
      final uri = Uri.tryParse(response['url']?.toString() ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          !_isMercadoPagoHost(uri.host)) {
        throw const FormatException(
          'O backend retornou um link de checkout inválido.',
        );
      }
      if (!mounted) return;
      setState(() {
        _checkoutUri = uri;
        _returnUrlMissing = response['returnUrlConfigured'] == false && kIsWeb;
        _message = response['webhookConfigured'] == false
            ? 'Checkout pronto. A confirmação automática da assinatura depende de um webhook público HTTPS no backend.'
            : 'Checkout pronto. Abra o ambiente seguro do Mercado Pago para concluir.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _creatingCheckout = false);
    }
  }

  bool _isMercadoPagoHost(String host) =>
      host == 'mercadopago.com.br' ||
      host.endsWith('.mercadopago.com.br') ||
      host == 'mercadopago.com' ||
      host.endsWith('.mercadopago.com');

  Future<void> _openCheckout() async {
    final uri = _checkoutUri;
    if (uri == null) return;
    setState(() => _openingCheckout = true);
    try {
      final opened = await (widget.launchCheckout ?? _launchExternal)(uri);
      if (!opened) throw StateError('Não foi possível abrir o Mercado Pago.');
      if (!mounted) return;
      setState(() {
        _message =
            'Conclua o pagamento no Mercado Pago e retorne para verificar sua assinatura.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '$error Link: $uri';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _openingCheckout = false);
    }
  }

  Future<bool> _launchExternal(Uri uri) => launchUrl(
    uri,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );

  Future<void> _checkSubscription() async {
    setState(() {
      _checkingSubscription = true;
      _message = null;
    });
    try {
      final response = Map<String, dynamic>.from(
        await Api.get('/api/subscriptions/me') as Map,
      );
      final subscription = response['data'];
      if (!mounted) return;
      setState(() {
        _message = subscription is Map && subscription['status'] == 'active'
            ? 'Assinatura ativa: ${subscription['plan'] ?? 'WeGYM PRO'}.'
            : 'Ainda não há uma assinatura ativa. Se o pagamento foi aprovado agora, aguarde a notificação do Mercado Pago e verifique novamente.';
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = error.toString();
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checkingSubscription = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('CHECKOUT WEGYM PRO'),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.shield_outlined, color: stitchOrange),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StitchPageHeading(
                    eyebrow: 'PAGAMENTO SEGURO',
                    title: _planName,
                    subtitle:
                        'Finalize sua assinatura pelo Checkout Pro do Mercado Pago.',
                  ),
                  const SizedBox(height: 14),
                  StitchSection(
                    title: 'PLANO SELECIONADO',
                    icon: Icons.workspace_premium,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.bolt, color: stitchOrange, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _planName,
                                  style: const TextStyle(
                                    color: stitchText,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  _billing,
                                  style: const TextStyle(
                                    color: stitchMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _price,
                            style: const TextStyle(
                              color: stitchText,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StitchSection(
                    title: 'PAGAMENTO PROTEGIDO',
                    icon: Icons.lock_outline,
                    child: const Text(
                      'Os dados do cartão são informados diretamente no ambiente do Mercado Pago. O WeGYM não recebe nem armazena o número do cartão ou o código de segurança.',
                      style: TextStyle(color: stitchMuted, height: 1.45),
                    ),
                  ),
                  if (_returnUrlMissing) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Configure FLUTTER_APP_URL com a URL HTTPS publicada do app para habilitar o retorno automático à web.',
                      style: TextStyle(color: stitchMuted, fontSize: 11),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color:
                            (_messageIsError ? Colors.redAccent : stitchOrange)
                                .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              (_messageIsError
                                      ? Colors.redAccent
                                      : stitchOrange)
                                  .withValues(alpha: .28),
                        ),
                      ),
                      child: SelectableText(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError
                              ? Colors.redAccent.shade100
                              : stitchPeach,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_checkoutUri == null)
                    FilledButton.icon(
                      onPressed: _creatingCheckout ? null : _createCheckout,
                      icon: _creatingCheckout
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.lock),
                      label: Text(
                        _creatingCheckout
                            ? 'PREPARANDO CHECKOUT...'
                            : 'CONTINUAR PARA O MERCADO PAGO',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: stitchOrange,
                        foregroundColor: stitchOnPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: _openingCheckout ? null : _openCheckout,
                      icon: _openingCheckout
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.open_in_new),
                      label: const Text('ABRIR CHECKOUT SEGURO'),
                      style: FilledButton.styleFrom(
                        backgroundColor: stitchOrange,
                        foregroundColor: stitchOnPrimaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _checkingSubscription
                          ? null
                          : _checkSubscription,
                      icon: _checkingSubscription
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('VERIFICAR ASSINATURA'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'A assinatura só será ativada pelo backend após confirmação do pagamento pelo Mercado Pago.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: stitchMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
