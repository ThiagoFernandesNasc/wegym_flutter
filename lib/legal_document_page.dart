import 'package:flutter/material.dart';

import 'stitch_design_system.dart';

enum LegalDocumentKind { terms, privacy }

/// Reusable link that opens a legal document inside the app navigation stack.
class LegalDocumentLink extends StatelessWidget {
  const LegalDocumentLink({
    super.key,
    required this.kind,
    required this.label,
    this.buttonKey,
    this.compact = false,
  });

  final LegalDocumentKind kind;
  final String label;
  final Key? buttonKey;
  final bool compact;

  @override
  Widget build(BuildContext context) => TextButton(
    key: buttonKey,
    style: TextButton.styleFrom(
      foregroundColor: compact ? stitchMuted : stitchOrange,
      minimumSize: const Size(0, 32),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    ),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LegalDocumentPage(kind: kind)),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: compact ? 9 : 11, fontWeight: FontWeight.w800),
    ),
  );
}

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.kind});

  final LegalDocumentKind kind;

  String get _title => switch (kind) {
    LegalDocumentKind.terms => "Termos de Uso",
    LegalDocumentKind.privacy => "Pol\u00edtica de Privacidade",
  };

  String get _lastUpdated => switch (kind) {
    LegalDocumentKind.terms =>
      "\u00daltima atualiza\u00e7\u00e3o: Janeiro de 2025",
    LegalDocumentKind.privacy =>
      "\u00daltima atualiza\u00e7\u00e3o: Junho de 2026",
  };

  List<_LegalSectionData> get _sections => switch (kind) {
    LegalDocumentKind.terms => _termsSections,
    LegalDocumentKind.privacy => _privacySections,
  };

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final muted = stitchMuted;
    return Scaffold(
      backgroundColor: stitchCanvas,
      appBar: AppBar(
        backgroundColor: stitchCanvas,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
        titleSpacing: 4,
        title: Row(
          children: [
            Icon(
              kind == LegalDocumentKind.terms
                  ? Icons.description_outlined
                  : Icons.shield_outlined,
              color: stitchOrange,
              size: 19,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                _title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: MediaQuery.sizeOf(context).width >= 600 ? 20 : 18,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -.55,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width >= 600 ? 24 : 16,
            32,
            MediaQuery.sizeOf(context).width >= 600 ? 24 : 16,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind == LegalDocumentKind.terms) ...[
                    Text(
                      _lastUpdated,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  for (final section in _sections)
                    _LegalSection(
                      section: section,
                      kind: kind,
                      textColor: textColor,
                      muted: muted,
                    ),
                  if (kind == LegalDocumentKind.privacy)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(top: 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Text(
                        _lastUpdated,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSectionData {
  const _LegalSectionData(
    this.title, {
    this.paragraphs = const [],
    this.bullets = const [],
  });

  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
}

class _LegalSection extends StatelessWidget {
  const _LegalSection({
    required this.section,
    required this.kind,
    required this.textColor,
    required this.muted,
  });

  final _LegalSectionData section;
  final LegalDocumentKind kind;
  final Color textColor;
  final Color muted;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: kind == LegalDocumentKind.terms ? 24 : 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: TextStyle(
            color: kind == LegalDocumentKind.terms ? textColor : stitchOrange,
            fontSize: kind == LegalDocumentKind.terms ? 16 : 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 9),
        for (final paragraph in section.paragraphs) ...[
          Text(
            paragraph,
            style: TextStyle(color: muted, fontSize: 14, height: 1.65),
          ),
          if (paragraph != section.paragraphs.last ||
              section.bullets.isNotEmpty)
            const SizedBox(height: 8),
        ],
        for (final bullet in section.bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 10),
                  child: Icon(Icons.circle, size: 5, color: stitchOrange),
                ),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(color: muted, fontSize: 14, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

const _termsSections = <_LegalSectionData>[
  _LegalSectionData(
    "1. Aceita\u00e7\u00e3o dos Termos",
    paragraphs: [
      "Ao acessar e utilizar a plataforma WEGYM, voc\u00ea concorda com estes Termos de Uso. Se n\u00e3o concordar com algum dos termos, n\u00e3o utilize o servi\u00e7o.",
    ],
  ),
  _LegalSectionData(
    "2. Descri\u00e7\u00e3o do Servi\u00e7o",
    paragraphs: [
      "A WEGYM \u00e9 uma plataforma digital que oferece ferramentas de gest\u00e3o de treinos, acompanhamento de evolu\u00e7\u00e3o f\u00edsica, integra\u00e7\u00e3o com dispositivos de wearable e comunica\u00e7\u00e3o entre atletas e personal trainers.",
    ],
  ),
  _LegalSectionData(
    "3. Conta de Usu\u00e1rio",
    paragraphs: [
      "Voc\u00ea \u00e9 respons\u00e1vel por manter a confidencialidade de sua senha e por todas as atividades que ocorrem em sua conta. Voc\u00ea concorda em notificar imediatamente qualquer uso n\u00e3o autorizado de sua conta.",
    ],
  ),
  _LegalSectionData(
    "4. Responsabilidades do Usu\u00e1rio",
    paragraphs: [
      "O usu\u00e1rio se compromete a: (a) fornecer informa\u00e7\u00f5es verdadeiras e atualizadas; (b) n\u00e3o utilizar o servi\u00e7o para fins ilegais ou n\u00e3o autorizados; (c) n\u00e3o interferir no funcionamento do servi\u00e7o; (d) respeitar os direitos de outros usu\u00e1rios.",
    ],
  ),
  _LegalSectionData(
    "5. Propriedade Intelectual",
    paragraphs: [
      "Todo o conte\u00fado, marcas, logotipos e materiais disponibilizados na plataforma WEGYM s\u00e3o de propriedade exclusiva da empresa e s\u00e3o protegidos pelas leis de propriedade intelectual.",
    ],
  ),
  _LegalSectionData(
    "6. Limita\u00e7\u00e3o de Responsabilidade",
    paragraphs: [
      "A WEGYM n\u00e3o se responsabiliza por danos diretos, indiretos, incidentais ou consequenciais decorrentes do uso da plataforma. O servi\u00e7o \u00e9 fornecido 'como est\u00e1', sem garantias de qualquer tipo.",
    ],
  ),
  _LegalSectionData(
    "7. Altera\u00e7\u00f5es nos Termos",
    paragraphs: [
      "A WEGYM reserva-se o direito de alterar estes Termos a qualquer momento. As altera\u00e7\u00f5es ser\u00e3o publicadas na plataforma e o uso continuado do servi\u00e7o ap\u00f3s as altera\u00e7\u00f5es constitui aceita\u00e7\u00e3o dos novos termos.",
    ],
  ),
  _LegalSectionData(
    "8. Contato",
    paragraphs: [
      "Em caso de d\u00favidas sobre estes Termos de Uso, entre em contato conosco atrav\u00e9s do e-mail: suporte@wegym.app",
    ],
  ),
];

const _privacySections = <_LegalSectionData>[
  _LegalSectionData(
    "1. Introdu\u00e7\u00e3o",
    paragraphs: [
      "A WEGYM respeita sua privacidade. Esta pol\u00edtica descreve como coletamos, usamos, armazenamos e protegemos seus dados pessoais em conformidade com a Lei Geral de Prote\u00e7\u00e3o de Dados (LGPD - Lei n\u00ba 13.709/2018).",
      "Ao criar uma conta e utilizar a plataforma WEGYM, voc\u00ea consente com as pr\u00e1ticas descritas nesta pol\u00edtica.",
    ],
  ),
  _LegalSectionData(
    "2. Dados Coletados",
    paragraphs: [
      "Coletamos os seguintes dados pessoais fornecidos voluntariamente por voc\u00ea:",
    ],
    bullets: [
      "Nome completo, CPF, e-mail, data de nascimento, sexo, endere\u00e7o (CEP, cidade, UF)",
      "Dados f\u00edsicos: peso, altura, idade, n\u00edvel de experi\u00eancia, les\u00f5es, problemas de sa\u00fade, medicamentos",
      "Dados de uso: sess\u00f5es de treino, modalidades praticadas, desempenho, frequ\u00eancia card\u00edaca, calorias",
      "Para Personais: n\u00famero do CREF, registro profissional",
      "Dados de pagamento processados exclusivamente pelo Mercado Pago (n\u00e3o armazenamos dados de cart\u00e3o)",
    ],
  ),
  _LegalSectionData(
    "3. Finalidade do Tratamento",
    paragraphs: ["Seus dados s\u00e3o utilizados para:"],
    bullets: [
      "Criar e gerenciar sua conta na plataforma WEGYM",
      "Personalizar planos de treino com base no seu perfil e objetivos",
      "Gerar estat\u00edsticas de desempenho e evolu\u00e7\u00e3o",
      "Processar pagamentos de planos premium (via Mercado Pago)",
      "Enviar comunica\u00e7\u00f5es sobre a plataforma (mediante seu consentimento)",
      "Cumprir obriga\u00e7\u00f5es legais e regulat\u00f3rias",
    ],
  ),
  _LegalSectionData(
    "4. Compartilhamento de Dados",
    paragraphs: [
      "Compartilhamos seus dados apenas com: Mercado Pago (processamento de pagamentos), prestadores de servi\u00e7os de infraestrutura (hospedagem, banco de dados, CDN). N\u00e3o vendemos seus dados pessoais a terceiros.",
    ],
    bullets: [
      "Quando necess\u00e1rio para cumprir obriga\u00e7\u00e3o legal ou regulat\u00f3ria",
      "Com seu consentimento expl\u00edcito",
      "Com personal trainers vinculados (apenas dados de treino dos atletas)",
      "Processadores de pagamento (Mercado Pago) para transa\u00e7\u00f5es",
    ],
  ),
  _LegalSectionData(
    "5. Armazenamento e Seguran\u00e7a",
    paragraphs: [
      "Seus dados s\u00e3o armazenados em servidores seguros com criptografia em repouso e em tr\u00e2nsito (TLS 1.3). Implementamos controles de acesso rigorosos e monitoramento cont\u00ednuo para proteger suas informa\u00e7\u00f5es contra acesso n\u00e3o autorizado.",
    ],
  ),
  _LegalSectionData(
    "6. Seus Direitos (LGPD)",
    paragraphs: [
      "Voc\u00ea tem direito a: confirmar a exist\u00eancia de tratamento; acessar seus dados; corrigir dados incompletos ou desatualizados; anonimizar ou excluir dados desnecess\u00e1rios; solicitar portabilidade dos dados a outro fornecedor; revogar consentimento a qualquer tempo.",
      "Para exercer seus direitos, acesse as op\u00e7\u00f5es dispon\u00edveis no seu perfil ou entre em contato pelo e-mail: privacidade@wegym.com.br",
    ],
    bullets: [
      "Confirmar a exist\u00eancia de tratamento de dados",
      "Acessar seus dados pessoais",
      "Corrigir dados incompletos, inexatos ou desatualizados",
      "Solicitar a anonimiza\u00e7\u00e3o, bloqueio ou elimina\u00e7\u00e3o de dados",
      "Solicitar a portabilidade dos dados",
      "Eliminar os dados tratados com seu consentimento",
      "Revogar o consentimento a qualquer momento",
    ],
  ),
  _LegalSectionData(
    "7. Cookies",
    paragraphs: [
      "Utilizamos cookies essenciais para o funcionamento da plataforma (autentica\u00e7\u00e3o, sess\u00e3o, prefer\u00eancias). N\u00e3o utilizamos cookies de rastreamento ou publicidade sem seu consentimento expl\u00edcito.",
    ],
  ),
  _LegalSectionData(
    "8. Exclus\u00e3o de Conta",
    paragraphs: [
      "Voc\u00ea pode solicitar a exclus\u00e3o da sua conta a qualquer momento nas configura\u00e7\u00f5es do perfil. Ap\u00f3s a exclus\u00e3o, seus dados pessoais ser\u00e3o anonimizados em at\u00e9 30 dias. Dados necess\u00e1rios para obriga\u00e7\u00f5es legais (como registros de pagamento) ser\u00e3o retidos conforme exigido por lei.",
    ],
  ),
  _LegalSectionData(
    "9. Contato",
    paragraphs: [
      "Para exercer seus direitos, esclarecer d\u00favidas ou reportar incidentes, entre em contato pelo e-mail: privacidade@wegym.com.br ou pelo formul\u00e1rio na se\u00e7\u00e3o de privacidade do app.",
      "E-mail: privacidade@wegym.com.br\nEncarregado (DPO): dpo@wegym.com.br",
    ],
  ),
  _LegalSectionData(
    "10. Altera\u00e7\u00f5es nesta Pol\u00edtica",
    paragraphs: [
      "Esta pol\u00edtica pode ser atualizada periodicamente. Notificaremos voc\u00ea sobre altera\u00e7\u00f5es significativas por e-mail ou no pr\u00f3prio aplicativo. Recomendamos revisar esta p\u00e1gina regularmente.",
    ],
  ),
];
