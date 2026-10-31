import 'package:flutter/material.dart';
import 'api.dart';
import 'stitch_design_system.dart';

const _mCard = stitchSurface,
    _mRaised = stitchSurfaceLow,
    _mOrange = stitchOrange,
    _mText = stitchText,
    _mMuted = stitchMuted;

class FigmaModulePage extends StatefulWidget {
  const FigmaModulePage({super.key, required this.module, this.onLogout});
  final String module;
  final VoidCallback? onLogout;
  @override
  State<FigmaModulePage> createState() => _FigmaModulePageState();
}

class _FigmaModulePageState extends State<FigmaModulePage> {
  late Future<List<dynamic>> _data = _load();
  bool _busy = false;
  String _notice = '';
  String _currentUserId = '';
  String _currentRole = 'atleta';
  final Set<String> _joinedChallengeIds = {};
  final _search = TextEditingController();
  final _message = TextEditingController();
  final _receiver = TextEditingController();
  final _title = TextEditingController();
  final _value = TextEditingController();
  String? _activeChatUserId;
  String _activeChatName = '';
  List<dynamic> _activeChatMessages = [];

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      Api.previewChallengeIds().then((ids) {
        if (mounted) setState(() => _joinedChallengeIds.addAll(ids));
      });
    }
  }

  List<String> get _paths => switch (widget.module) {
    'Comunidade' => [
      '/api/social?feed=friends',
      '/api/challenges',
      '/api/achievements',
    ],
    'Analytics & Performance' => [
      '/api/workout-stats?period=week',
      '/api/workout-stats?period=month',
      '/api/workout-stats?period=year',
      '/api/workout-sessions?limit=30',
      '/api/body-measurements',
    ],
    'Agendamentos' => ['/api/appointments', '/api/appointments/slots'],
    'Nutrição' => [
      '/api/nutrition/meals',
      '/api/nutrition/diet-plans',
      '/api/nutrition/foods',
    ],
    'Alunos & Personal' => [
      '/api/personal-stats',
      '/api/athletes?take=20&plans=1&progress=1',
    ],
    'Metas & Desafios' => [
      '/api/goals',
      '/api/challenges',
      '/api/achievements',
    ],
    'Programas' => ['/api/programs?featured=true', '/api/programs'],
    'Chat' => ['/api/messages'],
    'Perfil & Configurações' => [
      '/api/user/profile',
      '/api/integrations',
      '/api/subscriptions/me',
    ],
    'Planos PRO' => ['/api/subscriptions/me', '/api/subscriptions'],
    'Medidas' => [
      '/api/body-measurements',
      '/api/body-measurements?metric=weight',
      '/api/body-measurements?metric=bodyFat',
    ],
    'Check-in' => ['/api/checkin', '/api/checkin?history=true&days=30'],
    'Amigos' => ['/api/friends'],
    'Aulas' => ['/api/classes'],
    _ => [],
  };

  Future<List<dynamic>> _load() async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _currentRole = await Api.previewRole() ?? 'atleta';
      return _preview();
    }
    final profile = await Api.profile();
    _currentUserId = profile['id']?.toString() ?? '';
    final role = profile['role']?.toString();
    _currentRole = role ?? 'atleta';
    if (widget.module == 'Alunos & Personal' && role != 'personal') {
      return [
        {
          '__info':
              'Área exclusiva para contas Personal. Seu perfil está cadastrado como Atleta.',
        },
      ];
    }
    if (role == 'personal' &&
        (widget.module == 'Analytics & Performance' ||
            widget.module == 'Medidas')) {
      return [
        {
          '__info':
              'M\u00e9tricas vinculadas ao perfil individual de Atleta. Acesse Alunos & Personal para consultar seus alunos.',
        },
      ];
    }
    return Future.wait(
      _paths.map((path) async {
        try {
          return await Api.get(path);
        } catch (e) {
          return {'_error': '$path: $e'};
        }
      }),
    );
  }

  List<dynamic> _preview() {
    final now = DateTime.now().toIso8601String();
    return switch (widget.module) {
      'Comunidade' => [
        {
          'posts': [
            {
              'id': 'p1',
              'text':
                  'Novo recorde no agachamento: 140 kg! Consist\u00eancia pagando.',
              'createdAt': now,
              'user': {'displayName': 'Camila Duarte'},
              '_count': {'likes': 34, 'comments': 8},
            },
            {
              'id': 'p2',
              'text': 'Treino de pernas conclu\u00eddo. Bora manter o ritmo!',
              'createdAt': now,
              'user': {'displayName': 'Marcos Silva'},
              '_count': {'likes': 19, 'comments': 3},
            },
            {
              'id': 'p3',
              'text': 'Mais uma semana de foco e disciplina.',
              'createdAt': now,
              'user': {'displayName': 'Ana Souza'},
              '_count': {'likes': 12, 'comments': 2},
            },
          ],
        },
        [
          {
            'id': 'c1',
            'name': '100 toneladas em 30 dias',
            'description': 'Acumule volume bruto no m\u00eas corrente.',
            'progress': 76.4,
          },
          {
            'id': 'c2',
            'name': 'Desafio da consist\u00eancia',
            'description': 'Treine por 21 dias sem interrup\u00e7\u00f5es.',
            'progress': 66.7,
          },
        ],
        {
          'achievements': [],
          'userAchievements': [
            {
              'id': 'a1',
              'name': 'Primeira semana',
              'description': 'Sete dias de treino conclu\u00eddos',
            },
            {
              'id': 'a2',
              'name': 'Novo recorde',
              'description': 'Carga pessoal superada no agachamento',
            },
          ],
        },
      ],
      'Analytics & Performance' => [
        {
          'totalSessions': 4,
          'totalVolume': 14280,
          'totalDistance': 8.4,
          'totalCalories': 2140,
          'avgHeartRate': 142,
        },
        {
          'totalSessions': 18,
          'totalVolume': 57000,
          'totalDistance': 32.6,
          'totalCalories': 14200,
          'avgHeartRate': 139,
        },
        {
          'totalSessions': 146,
          'totalVolume': 422000,
          'totalDistance': 286.4,
          'totalCalories': 94000,
          'avgHeartRate': 138,
        },
        List.generate(
          6,
          (i) => {
            'id': 's$i',
            'name': 'Treino de muscula\u00e7\u00e3o',
            'modality': 'musculacao',
            'durationSec': 2700 + i * 180,
            'completedAt': now,
          },
        ),
        [
          {'name': 'Peso', 'value': '78,4 kg', 'date': now},
        ],
      ],
      'Agendamentos' => [
        [
          {
            'id': 'ap1',
            'name': 'Avalia\u00e7\u00e3o f\u00edsica',
            'date': 'Hoje, 18:30',
            'coach': 'Carlos Personal',
            'status': 'Confirmado',
          },
          {
            'id': 'ap2',
            'name': 'Treino acompanhado',
            'date': 'Amanh\u00e3, 07:00',
            'coach': 'Carlos Personal',
            'status': 'Confirmado',
          },
        ],
        [
          {
            'id': 'slot1',
            'name': 'Hor\u00e1rio dispon\u00edvel',
            'date': 'Quinta-feira, 17:00',
          },
        ],
      ],
      'Nutri\u00e7\u00e3o' => [
        [
          {
            'id': 'meal1',
            'name': 'Caf\u00e9 da manh\u00e3',
            'type': 'breakfast',
            'calorias': '420 kcal',
            'prote\u00ednas': '28 g',
          },
          {
            'id': 'meal2',
            'name': 'Almo\u00e7o',
            'type': 'lunch',
            'calorias': '680 kcal',
            'prote\u00ednas': '42 g',
          },
          {
            'id': 'meal3',
            'name': 'Lanche da tarde',
            'type': 'snack',
            'calorias': '260 kcal',
            'prote\u00ednas': '18 g',
          },
        ],
        [
          {
            'id': 'diet1',
            'name': 'Plano de hipertrofia',
            'calorias': '2.400 kcal',
            'prote\u00ednas': '160 g',
            'carboidratos': '280 g',
            'gorduras': '70 g',
          },
        ],
        [
          {'id': 'food1', 'name': 'Alimentos favoritos'},
        ],
      ],
      'Alunos & Personal' => [
        {'athleteCount': 28, 'activeAthletes': 24},
        [
          {
            'id': 'at1',
            'name': 'Mariana Costa',
            'status': 'Ativa',
            'ades\u00e3o': '92%',
            'progresso': '+8%',
          },
          {
            'id': 'at2',
            'name': 'Pedro Almeida',
            'status': 'Ativo',
            'ades\u00e3o': '85%',
            'progresso': '+5%',
          },
          {
            'id': 'at3',
            'name': 'Julia Santos',
            'status': 'Aten\u00e7\u00e3o',
            'ades\u00e3o': '61%',
            'progresso': '+2%',
          },
        ],
      ],
      'Metas & Desafios' => [
        [
          {
            'id': 'g1',
            'title': 'Treinar 4 vezes por semana',
            'metric': 'sessões',
            'targetValue': 4,
            'currentValue': 3,
            'name': 'Treinar 4 vezes por semana',
            'progresso': '3 de 4 sess\u00f5es',
            'status': 'Em andamento',
          },
          {
            'id': 'g2',
            'title': 'Correr 20 km no mês',
            'metric': 'km',
            'targetValue': 20,
            'currentValue': 12.4,
            'name': 'Correr 20 km no m\u00eas',
            'progresso': '12,4 de 20 km',
            'status': 'Em andamento',
          },
        ],
        [
          {
            'id': 'c1',
            'name': 'Desafio da consist\u00eancia',
            'description': 'Complete 21 dias ativos neste m\u00eas.',
            'participants': [
              {'displayName': 'Camila Duarte'},
              {'displayName': 'Marcos Silva'},
              {'displayName': 'Ana Souza'},
            ],
          },
          {
            'id': 'c2',
            'name': '100 toneladas em 30 dias',
            'description': 'Some o volume dos seus treinos.',
            'participants': [
              {'displayName': 'Marcos Silva'},
              {'displayName': 'Camila Duarte'},
            ],
          },
        ],
        {
          'achievements': [],
          'userAchievements': [
            {
              'id': 'a1',
              'name': 'Disciplina de ferro',
              'description': 'Treinos conclu\u00eddos por uma semana.',
            },
          ],
        },
      ],
      'Programas' => [
        [
          {
            'id': 'pr1',
            'name': 'Hipertrofia em 8 semanas',
            'level': 'Intermedi\u00e1rio',
            'duration': '8 semanas',
            'category': 'For\u00e7a',
          },
          {
            'id': 'pr2',
            'name': 'Condicionamento total',
            'level': 'Iniciante',
            'duration': '6 semanas',
            'category': 'Cardio',
          },
        ],
        [
          {
            'id': 'pr1',
            'name': 'Hipertrofia em 8 semanas',
            'level': 'Intermedi\u00e1rio',
            'duration': '8 semanas',
            'category': 'For\u00e7a',
          },
          {
            'id': 'pr2',
            'name': 'Condicionamento total',
            'level': 'Iniciante',
            'duration': '6 semanas',
            'category': 'Cardio',
          },
        ],
      ],
      'Chat' => [
        {
          'conversations': [
            {
              'receiver': {
                'id': 'preview-coach',
                'displayName': 'Carlos Personal',
              },
            },
            {
              'receiver': {
                'id': 'preview-friend',
                'displayName': 'Mariana Costa',
              },
            },
          ],
          'unreadCount': 1,
        },
      ],
      'Perfil & Configura\u00e7\u00f5es' => [
        {
          'name': 'Rafael Costa',
          'email': 'rafael@wegym.demo',
          'role': 'atleta',
          'athlete': {
            'name': 'Rafael Costa',
            'experienceLevel': 'Intermedi\u00e1rio',
          },
        },
        [
          {
            'id': 'i1',
            'name': 'Google Fit',
            'status': 'Aguardando configura\u00e7\u00e3o de OAuth',
          },
          {
            'id': 'i2',
            'name': 'Strava',
            'status': 'Aguardando configura\u00e7\u00e3o de OAuth',
          },
        ],
        {'data': null},
      ],
      'Planos PRO' => [
        {
          'data': {'plan': 'WeGYM PRO Athlete', 'status': 'active'},
        },
        [
          {
            'id': 'plan1',
            'name': 'WeGYM Essential',
            'price': 'R\$ 89 / m\u00eas',
            'features': 'Treinos e hist\u00f3rico b\u00e1sico',
          },
          {
            'id': 'plan2',
            'name': 'WeGYM Pro Athlete',
            'price': 'R\$ 169 / m\u00eas',
            'features': 'Treinos, telemetria e analytics',
          },
        ],
      ],
      'Medidas' => [
        [
          {'id': 'm1', 'name': 'Peso', 'value': '78,4 kg', 'date': 'Hoje'},
          {
            'id': 'm2',
            'name': 'Percentual de gordura',
            'value': '18,2%',
            'date': 'Hoje',
          },
          {
            'id': 'm3',
            'name': 'Circunfer\u00eancia abdominal',
            'value': '84 cm',
            'date': 'Hoje',
          },
        ],
        [
          {
            'id': 'm4',
            'name': 'Peso anterior',
            'value': '79,1 kg',
            'date': 'H\u00e1 30 dias',
          },
        ],
        [
          {
            'id': 'm5',
            'name': 'Gordura corporal',
            'value': '19,0%',
            'date': 'H\u00e1 30 dias',
          },
        ],
      ],
      'Check-in' => [
        {'today': null, 'streak': 4},
        {
          'checkIns': [
            {'date': '2026-10-30', 'mood': 4, 'energy': 4, 'sleepHours': 7.5},
          ],
          'streak': 4,
        },
      ],
      'Amigos' => [
        [
          {
            'id': 'preview-friend',
            'name': 'Mariana Costa',
            'status': 'accepted',
          },
        ],
      ],
      'Aulas' => [
        [
          {
            'id': 'class-1',
            'date': '2026-11-03',
            'time': '18:00',
            'type': 'Musculação',
            'status': 'scheduled',
          },
        ],
      ],
      _ => [],
    };
  }

  Future<void> _refresh() async {
    setState(() {
      _data = _load();
      _notice = '';
    });
    await _data;
  }

  Future<void> _run(Future<dynamic> Function() call, String success) async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      setState(
        () => _notice =
            'Pr\u00e9via: a a\u00e7\u00e3o n\u00e3o foi enviada ao servidor.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _notice = '';
    });
    try {
      await call();
      if (mounted) {
        setState(() => _notice = success);
        await _refresh();
      }
    } catch (e) {
      if (mounted) setState(() => _notice = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _message.dispose();
    _receiver.dispose();
    _title.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _data,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: _mOrange));
      }
      final data = snap.data ?? [];
      _snapshotData = data;
      return RefreshIndicator(
        color: _mOrange,
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, box) {
            final wide = box.maxWidth > 920;
            final config = _config(widget.module);
            final primary = data.isNotEmpty ? data[0] : null;
            final info = data
                .whereType<Map>()
                .map((item) => item['__info'])
                .whereType<String>()
                .firstOrNull;
            final apiError = data
                .whereType<Map>()
                .map((item) => item['_error'])
                .whereType<String>()
                .firstOrNull;
            if (info != null) {
              return ListView(
                padding: EdgeInsets.all(wide ? 24 : 14),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _heading(config.$1, config.$2, config.$3),
                          const SizedBox(height: 14),
                          _noticeBox(info),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: EdgeInsets.all(wide ? 24 : 14),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (const bool.fromEnvironment('PREVIEW_DASHBOARD'))
                          _noticeBox(
                            'PR\u00c9VIA \u2022 DADOS DE DEMONSTRA\u00c7\u00c3O \u2022 As a\u00e7\u00f5es n\u00e3o s\u00e3o salvas.',
                          ),
                        _heading(config.$1, config.$2, config.$3),
                        const SizedBox(height: 14),
                        if (apiError != null) _noticeBox(apiError),
                        _summaryCards(widget.module, data, wide),
                        const SizedBox(height: 14),
                        if (_notice.isNotEmpty) _noticeBox(_notice),
                        if (widget.module == 'Comunidade')
                          _community(data, wide)
                        else if (widget.module == 'Analytics & Performance')
                          _analytics(data)
                        else if (widget.module == 'Agendamentos')
                          _appointmentManager(data)
                        else if (widget.module == 'Nutrição')
                          _nutritionManager(data)
                        else if (widget.module == 'Alunos & Personal')
                          _students(data)
                        else if (widget.module == 'Metas & Desafios')
                          _goals(data)
                        else if (widget.module == 'Programas')
                          _programCatalog(data)
                        else if (widget.module == 'Chat')
                          _chatInbox(primary)
                        else if (widget.module == 'Perfil & Configurações')
                          _profile(primary)
                        else if (widget.module == 'Planos PRO')
                          _pro(data)
                        else if (widget.module == 'Medidas')
                          _measurements(data)
                        else if (widget.module == 'Check-in')
                          _checkin(data)
                        else if (widget.module == 'Amigos')
                          _friends(data)
                        else if (widget.module == 'Aulas')
                          _classes(data),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );

  (String, String, String) _config(String module) => switch (module) {
    'Comunidade' => (
      'COMUNIDADE & LEADERBOARD',
      'Conecte-se à comunidade, acompanhe desafios e celebre recordes.',
      'Pódio, feed social e conquistas',
    ),
    'Analytics & Performance' => (
      'ANALYTICS & PERFORMANCE',
      'Acompanhe suas métricas de treino e evolução corporal.',
      'Estatísticas reais por período',
    ),
    'Agendamentos' => (
      'AGENDAMENTOS & AVALIAÇÕES',
      'Consulte sessões presenciais e horários disponíveis.',
      'Agenda e check-ins',
    ),
    'Nutrição' => (
      'NUTRIÇÃO & MACRONUTRIENTES',
      'Acompanhe refeições e planos alimentares.',
      'Diário de refeições',
    ),
    'Alunos & Personal' => (
      'GESTÃO DE ALUNOS & COACHING',
      'Acompanhe adesão, progresso e avaliações dos atletas.',
      'Área do personal trainer',
    ),
    'Metas & Desafios' => (
      'METAS, DESAFIOS & CONQUISTAS',
      'Transforme consistência em progresso mensurável.',
      'Metas pessoais e desafios oficiais',
    ),
    'Programas' => (
      'PROGRAMAS DE TREINAMENTO',
      'Explore programas e protocolos disponíveis.',
      'Programas oficiais',
    ),
    'Chat' => (
      'CANAL ATLETA & COACH',
      'Consulte conversas e envie mensagens ao seu treinador.',
      'Comunicação com resposta em tempo real',
    ),
    'Perfil & Configurações' => (
      'PERFIL & CONFIGURAÇÕES',
      'Gerencie seu perfil, consentimentos e integrações conectadas.',
      'Dados e privacidade da conta',
    ),
    'Planos PRO' => (
      'PLANOS WEGYM & ASSINATURA PRO',
      'Consulte sua assinatura e recursos disponíveis.',
      'Cobrança protegida pelo provedor',
    ),
    'Check-in' => (
      'CHECK-IN DIÁRIO',
      'Registre bem-estar e acompanhe sua consistência.',
      'Humor, energia, sono e treino',
    ),
    'Amigos' => (
      'AMIGOS & CONEXÕES',
      'Encontre e acompanhe pessoas da comunidade.',
      'Rede social WeGYM',
    ),
    'Aulas' => (
      'AULAS & SESSÕES',
      'Consulte as aulas associadas à sua conta.',
      'Agenda de atividades',
    ),
    _ => (
      'AVALIAÇÃO CORPORAL & MEDIDAS',
      'Registre e acompanhe suas medidas corporais.',
      'Histórico de avaliações',
    ),
  };

  Widget _heading(String title, String desc, String sub) => StitchCard(
    gradient: true,
    padding: const EdgeInsets.all(20),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.module == 'Programas' && _currentRole == 'personal')
              _button('CRIAR PROGRAMA', Icons.add, _createProgram),
            if (widget.module == 'Comunidade')
              _button('PUBLICAR', Icons.add, _composePost),
            if (widget.module == 'Metas & Desafios')
              _button('NOVA META', Icons.flag, _createGoal),
            if (widget.module == 'Medidas')
              _button('NOVA AVALIAÇÃO', Icons.add, _createMeasurement),
            if (widget.module == 'Nutrição')
              _button('REGISTRAR REFEIÇÃO', Icons.restaurant, _createMeal),
            if (widget.module == 'Agendamentos')
              _button('NOVO AGENDAMENTO', Icons.event, _bookSlot),
            if (widget.module == 'Perfil & Configurações')
              _button(
                'SAIR',
                Icons.logout,
                () async => widget.onLogout?.call(),
              ),
            if (widget.module == 'Planos PRO')
              _button('ATUALIZAR', Icons.refresh, _refresh),
            if (widget.module == 'Check-in')
              _button('FAZER CHECK-IN', Icons.check_circle, _saveCheckin),
            if (widget.module == 'Amigos')
              _button('ADICIONAR AMIGO', Icons.person_add, _addFriend),
          ],
        );
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StitchKicker('WEGYM PERFORMANCE OS  •  $sub', color: stitchOrange),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: stitchText,
                fontSize: 22,
                height: 1.12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              desc,
              style: const TextStyle(
                color: stitchMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 660) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              intro,
              if (actions.children.isNotEmpty) ...[
                const SizedBox(height: 12),
                actions,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: intro),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    ),
  );
  Widget _button(String label, IconData icon, VoidCallback? onPressed) =>
      FilledButton.icon(
        onPressed: _busy ? null : onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _mOrange,
          foregroundColor: stitchOnPrimaryContainer,
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
        ),
      );
  Widget _summaryCards(String module, List<dynamic> data, bool wide) {
    final rawStats = _map(data.isNotEmpty ? data[0] : null);
    final stats = _payload(rawStats);
    final cards = switch (module) {
      'Analytics & Performance' => [
        (
          'SESSÕES NA SEMANA',
          _n(stats['totalSessions']).round().toString(),
          Icons.fitness_center,
        ),
        ('TEMPO ATIVO', _duration(_n(stats['totalVolume'])), Icons.timer),
        (
          'DISTÂNCIA',
          '${_n(stats['totalDistance']).toStringAsFixed(1)} km',
          Icons.route,
        ),
        (
          'FC MÉDIA',
          '${_n(stats['avgHeartRate']).round()} bpm',
          Icons.favorite,
        ),
      ],
      'Comunidade' => [
        ('ATLETAS NO RANKING', '—', Icons.groups),
        (
          'DESAFIOS ATIVOS',
          _list(data.length > 1 ? data[1] : null).length.toString(),
          Icons.flag,
        ),
        (
          'CONQUISTAS',
          _list(
            _map(data.length > 2 ? data[2] : null)['userAchievements'],
          ).length.toString(),
          Icons.emoji_events,
        ),
      ],
      'Agendamentos' => [
        (
          'SESSÕES',
          _list(data.isNotEmpty ? data[0] : null).length.toString(),
          Icons.event,
        ),
        ('VISÃO', 'SEMANA', Icons.calendar_view_week),
        ('CHECK-IN', 'DISPONÍVEL', Icons.qr_code),
      ],
      'Nutrição' => [
        (
          'REFEIÇÕES HOJE',
          _list(data.isNotEmpty ? data[0] : null).length.toString(),
          Icons.restaurant,
        ),
        (
          'PLANO ALIMENTAR',
          data.length > 1 && _list(data[1]).isNotEmpty ? 'ATIVO' : '—',
          Icons.menu_book,
        ),
        ('META CALÓRICA', 'Defina no plano', Icons.local_fire_department),
      ],
      'Alunos & Personal' => [
        (
          'ALUNOS',
          _n(
            stats['athleteCount'] ?? stats['totalAthletes'],
          ).round().toString(),
          Icons.groups,
        ),
        (
          'ATIVOS',
          _n(stats['activeAthletes']).round().toString(),
          Icons.check_circle,
        ),
        ('ALERTAS', 'Consulte fichas', Icons.warning_amber),
      ],
      'Metas & Desafios' => [
        (
          'METAS',
          _list(data.isNotEmpty ? data[0] : null).length.toString(),
          Icons.flag,
        ),
        (
          'DESAFIOS',
          data.length > 1 ? _list(data[1]).length.toString() : '0',
          Icons.emoji_events,
        ),
        ('CONQUISTAS', 'Acompanhe seu progresso', Icons.military_tech),
      ],
      'Programas' => [
        (
          'PROGRAMAS EM DESTAQUE',
          _list(data.isNotEmpty ? data[0] : null).length.toString(),
          Icons.fitness_center,
        ),
        ('CATEGORIAS', 'Força • cardio • mobilidade', Icons.category),
      ],
      'Chat' => [
        (
          'CONVERSAS',
          _list(_map(stats)['conversations']).length.toString(),
          Icons.forum,
        ),
        (
          'NÃO LIDAS',
          _n(_map(stats)['unreadCount']).round().toString(),
          Icons.mark_chat_unread,
        ),
      ],
      'Planos PRO' => [
        (
          'ASSINATURA',
          _map(_map(stats)['data'])['plan']?.toString() ?? 'Consulte planos',
          Icons.workspace_premium,
        ),
        (
          'STATUS',
          _map(_map(stats)['data'])['status']?.toString() ?? '—',
          Icons.verified,
        ),
      ],
      _ => [
        ('AVALIAÇÕES', _list(stats).length.toString(), Icons.monitor_weight),
        ('PERÍODO', 'Histórico completo', Icons.show_chart),
      ],
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 520
            ? (constraints.maxWidth - 10) / 2
            : 220.0;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: StitchMetric(
                    label: card.$1,
                    value: card.$2,
                    icon: card.$3,
                    tint: stitchOrange,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _community(List<dynamic> d, bool wide) {
    final feed = _map(d.isNotEmpty ? d[0] : null),
        posts = _list(feed['posts']),
        challenges = _list(d.length > 1 ? d[1] : null);
    return Column(
      children: [
        _section(
          'RANKING POR DESAFIO',
          Icons.emoji_events,
          challenges.isEmpty
              ? _empty(
                  'O backend n\u00e3o retornou desafios para consultar o ranking.',
                )
              : Column(
                  children: challenges
                      .take(4)
                      .map(
                        (challenge) => _rowCard(
                          _text(challenge['name'] ?? challenge['title']),
                          _text(challenge['description']),
                          Icons.military_tech,
                          tail: _button(
                            'VER RANKING',
                            Icons.leaderboard,
                            () => _showChallengeLeaderboard(
                              _text(challenge['id']),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _section(
                  'MURAL SOCIAL & RECORDES',
                  Icons.dynamic_feed,
                  _postList(posts),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _section(
                  'DESAFIOS ATIVOS',
                  Icons.flag,
                  _challengeCards(challenges),
                ),
              ),
            ],
          )
        else ...[
          _section('DESAFIOS ATIVOS', Icons.flag, _challengeCards(challenges)),
          const SizedBox(height: 12),
          _section(
            'MURAL SOCIAL & RECORDES',
            Icons.dynamic_feed,
            _postList(posts),
          ),
        ],
      ],
    );
  }

  Widget _postList(List<dynamic> rows) => rows.isEmpty
      ? _empty('Seu mural aparecerá quando houver publicações.')
      : Column(
          children: rows
              .map(
                (p) => _rowCard(
                  _userName(p),
                  _text(p['text'] ?? p['content']),
                  Icons.groups,
                  tail: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Curtir',
                        onPressed: () => _run(
                          () => Api.post(
                            '/api/social/${_text(p['id'])}/like',
                            {},
                          ),
                          'Curtida registrada.',
                        ),
                        icon: const Icon(
                          Icons.favorite_border,
                          color: _mOrange,
                        ),
                      ),
                      Text(_text(_map(p['_count'])['likes'])),
                      IconButton(
                        tooltip: 'Comentar',
                        onPressed: () => _commentPost(_text(p['id'])),
                        icon: const Icon(
                          Icons.comment_outlined,
                          color: _mOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        );
  bool _isParticipating(Map challenge) {
    final id = _text(challenge['id']);
    if (id.isEmpty) return false;
    if (_joinedChallengeIds.contains(id)) return true;
    return _currentUserId.isNotEmpty &&
        _list(
          challenge['participants'],
        ).any((p) => _text(_map(p)['userId']) == _currentUserId);
  }

  Future<void> _joinChallenge(Map challenge) async {
    final id = _text(challenge['id']);
    if (id.isEmpty || _isParticipating(challenge) || _busy) return;
    final demo = const bool.fromEnvironment('PREVIEW_DASHBOARD');
    setState(() {
      _busy = true;
      _notice = '';
    });
    try {
      if (demo) {
        _joinedChallengeIds.add(id);
        await Api.savePreviewChallengeIds(_joinedChallengeIds.toList());
        if (mounted) {
          setState(
            () => _notice =
                'Participação registrada nesta prévia de demonstração.',
          );
        }
      } else {
        await Api.post('/api/challenges', {'challengeId': id});
        if (mounted) {
          setState(() {
            _joinedChallengeIds.add(id);
            _notice = 'Participação confirmada no desafio.';
          });
          await _refresh();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _notice = 'Não foi possível participar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _challengeCards(List<dynamic> rows) => rows.isEmpty
      ? _empty('Nenhum desafio ativo foi encontrado.')
      : Column(
          children: rows.map((row) {
            final c = _map(row);
            final joined = _isParticipating(c);
            final demo = const bool.fromEnvironment('PREVIEW_DASHBOARD');
            final people = _list(c['participants']);
            final names = people
                .map((p) => _text(_map(p)['displayName'] ?? _map(p)['name']))
                .where((n) => n.isNotEmpty)
                .toList();
            if (demo && joined && !names.contains('Você')) names.add('Você');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _section(
                _text(c['name'] ?? c['title']),
                Icons.local_fire_department,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(c['description']),
                      style: const TextStyle(color: _mMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${people.length + (demo && joined ? 1 : 0)} participantes',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        _button(
                          joined ? 'PARTICIPANDO' : 'PARTICIPAR',
                          joined ? Icons.check : Icons.add,
                          joined || _busy ? null : () => _joinChallenge(c),
                        ),
                      ],
                    ),
                    if (names.isNotEmpty) ...[
                      const Divider(height: 20),
                      Text(
                        demo
                            ? 'PARTICIPANTES DE DEMONSTRAÇÃO'
                            : 'PARTICIPANTES',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _mMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: names
                            .map(
                              (n) => Chip(
                                avatar: const Icon(Icons.person, size: 15),
                                label: Text(n),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                      if (demo)
                        const Text(
                          'Nomes fictícios para a apresentação.',
                          style: TextStyle(fontSize: 11, color: _mMuted),
                        ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );

  Widget _analytics(List<dynamic> d) {
    final week = _payload(d.isNotEmpty ? d[0] : null),
        month = _payload(d.length > 1 ? d[1] : null),
        year = _payload(d.length > 2 ? d[2] : null),
        sessions = _list(d.length > 3 ? d[3] : null),
        measures = _list(d.length > 4 ? d[4] : null);
    return Column(
      children: [
        _section(
          'EVOLUÇÃO DE CARGAS E PERFORMANCE',
          Icons.show_chart,
          Column(
            children: [
              _metricLine('Esta semana', week),
              _metricLine('Este mês', month),
              _metricLine('Este ano', year),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _section(
                'SESSÕES RECENTES',
                Icons.fitness_center,
                _sessionList(sessions),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _section(
                'COMPOSIÇÃO CORPORAL',
                Icons.monitor_weight,
                _genericList(measures),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _appointmentManager(List<dynamic> d) {
    final appointments = _list(d.isNotEmpty ? d[0] : null);
    final slots = _list(d.length > 1 ? d[1] : null);
    return Column(
      children: [
        _section(
          'PRÓXIMAS SESSÕES',
          Icons.calendar_month,
          appointments.isEmpty
              ? _empty('Nenhum agendamento listado.')
              : Column(
                  children: appointments.map((item) {
                    final a = _map(item);
                    final id = _text(a['id']);
                    final status = _text(a['status']);
                    final otherPerson =
                        _map(a['athlete'])['displayName'] ??
                        _map(a['personal'])['displayName'];
                    final date = _text(a['date']);
                    return _rowCard(
                      _text(otherPerson).isEmpty
                          ? 'Sessão'
                          : _text(otherPerson),
                      '$date • ${status.isEmpty ? 'Pendente' : status}',
                      Icons.event,
                      tail: Wrap(
                        children: [
                          if (status == 'pending')
                            IconButton(
                              tooltip: 'Cancelar agendamento',
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => Api.patch('/api/appointments', {
                                        'id': id,
                                        'action': 'cancel',
                                      }),
                                      'Agendamento cancelado.',
                                    ),
                              icon: const Icon(
                                Icons.event_busy,
                                color: _mOrange,
                              ),
                            ),
                          if (status == 'pending' && _currentRole == 'personal')
                            IconButton(
                              tooltip: 'Confirmar agendamento',
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                      () => Api.patch('/api/appointments', {
                                        'id': id,
                                        'action': 'confirm',
                                      }),
                                      'Agendamento confirmado.',
                                    ),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        _section(
          'HORÁRIOS DISPONÍVEIS',
          Icons.schedule,
          slots.isEmpty
              ? _empty('Nenhum horário disponível no momento.')
              : Column(
                  children: slots.map((raw) {
                    final slot = _map(raw);
                    return _rowCard(
                      _text(slot['date']),
                      '${_text(slot['startTime'])} – ${_text(slot['endTime'])}',
                      Icons.access_time,
                      tail: _button(
                        'RESERVAR',
                        Icons.add,
                        _busy ? null : () => _bookSlotFor(slot),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _nutritionManager(List<dynamic> d) {
    final meals = _list(d.isNotEmpty ? d[0] : null);
    final plans = _list(d.length > 1 ? d[1] : null);
    final foods = _list(d.length > 2 ? d[2] : null);
    return Column(
      children: [
        _section(
          'REFEIÇÕES DO DIA',
          Icons.restaurant,
          meals.isEmpty
              ? _empty('Nenhuma refeição registrada para hoje.')
              : Column(
                  children: meals.map((raw) {
                    final meal = _map(raw);
                    final id = _text(meal['id']);
                    final foodsInMeal = _list(meal['foods']);
                    final totals = _map(meal['totals']);
                    final details = foodsInMeal
                        .map((item) {
                          final row = _map(item);
                          final food = _map(row['food']);
                          return '${_text(food['name'])} × ${_text(row['amount'])}';
                        })
                        .where((name) => name.trim().isNotEmpty)
                        .join(' • ');
                    final type = switch (_text(meal['type'])) {
                      'breakfast' => 'Café da manhã',
                      'lunch' => 'Almoço',
                      'dinner' => 'Jantar',
                      'snack' => 'Lanche',
                      _ =>
                        _text(meal['name']).isEmpty
                            ? 'Refeição'
                            : _text(meal['name']),
                    };
                    final summary = [
                      if (details.isNotEmpty) details,
                      if (totals['calories'] != null)
                        '${_n(totals['calories']).round()} kcal',
                      if (totals['proteinG'] != null)
                        '${_n(totals['proteinG']).round()} g de proteína',
                    ].join(' • ');
                    return _rowCard(
                      type,
                      summary.isEmpty ? 'Nenhum alimento adicionado.' : summary,
                      Icons.restaurant_menu,
                      tail: _button(
                        'ADICIONAR ALIMENTO',
                        Icons.add,
                        id.isEmpty ||
                                const bool.fromEnvironment('PREVIEW_DASHBOARD')
                            ? null
                            : () => _addFoodToMeal(id),
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 12),
        _section(
          'PLANOS ALIMENTARES',
          Icons.menu_book,
          Column(
            children: [
              ...plans.map((plan) {
                final p = _map(plan);
                return _rowCard(
                  _text(p['title'] ?? p['name']),
                  _text(p['description'] ?? p['dailyCalories']),
                  Icons.restaurant,
                );
              }),
              if (plans.isEmpty) _empty('Nenhum plano alimentar cadastrado.'),
              Align(
                alignment: Alignment.centerRight,
                child: _button('CRIAR PLANO', Icons.add, _createDietPlan),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'ALIMENTOS DISPONÍVEIS',
          Icons.search,
          _genericList(foods, empty: 'Nenhum alimento encontrado.'),
        ),
      ],
    );
  }

  Future<void> _addFoodToMeal(String mealId) async {
    final query = await _prompt(
      'Buscar alimento',
      'Digite parte do nome do alimento',
    );
    if (query == null || query.trim().isEmpty) return;
    try {
      final results = _list(
        await Api.get(
          '/api/nutrition/foods?q=${Uri.encodeQueryComponent(query.trim())}',
        ),
      );
      if (!mounted) return;
      if (results.isEmpty) {
        _showInfo('Nenhum alimento encontrado.');
        return;
      }
      final foodId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          backgroundColor: _mCard,
          title: const Text('Selecionar alimento'),
          children: results.map((item) {
            final food = _map(item);
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, _text(food['id'])),
              child: Text(
                '${_text(food['name'])} • ${_n(food['calories']).round()} kcal',
              ),
            );
          }).toList(),
        ),
      );
      if (foodId == null || foodId.isEmpty) return;
      final amountText = await _prompt('Quantidade', 'Porções (padrão: 1)');
      if (amountText == null) return;
      final amount = double.tryParse(amountText.replaceAll(',', '.')) ?? 1;
      if (amount <= 0) {
        _showInfo('A quantidade deve ser maior que zero.');
        return;
      }
      await _run(
        () => Api.post('/api/nutrition/meals', {
          'mealId': mealId,
          'foodId': foodId,
          'amount': amount,
        }),
        'Alimento adicionado à refeição.',
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _notice = 'Não foi possível buscar/adicionar o alimento: $e',
        );
      }
    }
  }

  Widget _students(List<dynamic> d) => Column(
    children: [
      _section(
        'ALUNOS E ADESÃO',
        Icons.groups,
        _genericList(
          _list(d.length > 1 ? d[1] : null),
          empty: 'Esta área exige uma conta com perfil Personal Trainer.',
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'AÇÕES DO COACH',
        Icons.bolt,
        Wrap(
          spacing: 8,
          children: [
            _button('AGENDAR AVALIAÇÃO', Icons.event, () => _bookSlot()),
            _button('ATUALIZAR LISTA', Icons.refresh, _refresh),
          ],
        ),
      ),
    ],
  );
  Widget _goals(List<dynamic> d) => Column(
    children: [
      _section(
        'METAS ATIVAS',
        Icons.flag,
        _goalList(
          _list(d.isNotEmpty ? d[0] : null),
          empty: 'Crie sua primeira meta.',
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'DESAFIOS DA COMUNIDADE',
        Icons.emoji_events,
        _challengeCards(_list(d.length > 1 ? d[1] : null)),
      ),
      const SizedBox(height: 12),
      _section(
        'MURAL DE CONQUISTAS',
        Icons.military_tech,
        _genericList(
          _list(_map(d.length > 2 ? d[2] : null)['userAchievements']),
        ),
      ),
    ],
  );
  Widget _goalList(
    List<dynamic> rows, {
    String empty = 'Crie sua primeira meta.',
  }) => rows.isEmpty
      ? _empty(empty)
      : Column(
          children: rows.map((row) {
            final goal = _map(row);
            final target = _n(goal['targetValue']);
            final current = _n(goal['currentValue']);
            final metric = _text(goal['metric']);
            final progress = target <= 0
                ? 0.0
                : (current / target).clamp(0.0, 1.0);
            final status = _text(goal['status']).toLowerCase();
            final completed = status == 'completed';
            final progressText = target > 0
                ? '${current.toStringAsFixed(0)} de ${target.toStringAsFixed(0)} $metric'
                : 'Sem valor-alvo definido';
            return _rowCard(
              _text(goal['title'] ?? 'Meta'),
              'Progresso: $progressText • ${(progress * 100).round()}% • ${completed ? 'Concluída' : 'Em andamento'}',
              completed ? Icons.check_circle : Icons.flag_outlined,
              tail: Wrap(
                spacing: 2,
                children: [
                  if (!completed)
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _confirmGoalCompletion(goal),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('CONCLUIR'),
                    ),
                  IconButton(
                    tooltip: 'Atualizar progresso',
                    onPressed: _busy ? null : () => _updateGoalProgress(goal),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _mOrange,
                      size: 19,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Excluir meta',
                    onPressed: _busy ? null : () => _deleteGoal(goal),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: _mMuted,
                      size: 19,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

  Future<void> _confirmGoalCompletion(Map<String, dynamic> goal) async {
    final id = goal['id']?.toString();
    if (id == null || id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Confirmar conclusão da meta?'),
        content: Text(
          'Deseja marcar "${_text(goal['title'] ?? 'Meta')}" como concluída?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _mutatePreviewGoal(id, {
        'currentValue': _n(goal['targetValue']),
        'status': 'completed',
      }, 'Meta concluída nesta prévia.');
      return;
    }
    await _run(
      () => Api.patch('/api/goals', {
        'id': id,
        'currentValue': _n(goal['targetValue']),
      }),
      'Meta marcada como concluída.',
    );
  }

  Future<void> _updateGoalProgress(Map<String, dynamic> goal) async {
    final id = _text(goal['id']);
    if (id.isEmpty) return;
    final value = await _prompt('Atualizar progresso', 'Valor atual da meta');
    if (value == null) return;
    final currentValue = double.tryParse(value.replaceAll(',', '.'));
    if (currentValue == null || currentValue < 0) {
      _showInfo('Informe um número válido maior ou igual a zero.');
      return;
    }
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final target = _n(goal['targetValue']);
      _mutatePreviewGoal(id, {
        'currentValue': currentValue,
        'status': currentValue >= target ? 'completed' : 'active',
      }, 'Progresso atualizado nesta prévia.');
      return;
    }
    await _run(
      () => Api.patch('/api/goals', {'id': id, 'currentValue': currentValue}),
      'Progresso atualizado.',
    );
  }

  Future<void> _deleteGoal(Map<String, dynamic> goal) async {
    final id = _text(goal['id']);
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Excluir meta?'),
        content: Text('Deseja excluir "${_text(goal['title'] ?? 'Meta')}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _mutatePreviewGoal(id, null, 'Meta removida desta prévia.', remove: true);
      return;
    }
    await _run(() => Api.delete('/api/goals', {'id': id}), 'Meta excluída.');
  }

  void _mutatePreviewGoal(
    String id,
    Map<String, dynamic>? changes,
    String notice, {
    bool remove = false,
    Map<String, dynamic>? create,
  }) {
    final next = List<dynamic>.from(_snapshotData);
    if (next.isEmpty) return;
    final goals = _list(
      next[0],
    ).map((goal) => Map<String, dynamic>.from(_map(goal))).toList();
    if (create != null) {
      goals.add(create);
    } else {
      final index = goals.indexWhere((goal) => _text(goal['id']) == id);
      if (index < 0) return;
      if (remove) {
        goals.removeAt(index);
      } else if (changes != null) {
        goals[index].addAll(changes);
      }
    }
    next[0] = goals;
    setState(() {
      _snapshotData = next;
      _data = Future.value(next);
      _notice = notice;
    });
  }

  Widget _programCatalog(List<dynamic> data) {
    final rows = _list(
      data.length > 1 ? data[1] : (data.isNotEmpty ? data[0] : null),
    );
    return _section(
      'PROGRAMAS E PERIODIZAÇÕES',
      Icons.fitness_center,
      rows.isEmpty
          ? _empty('Não há programas publicados no backend.')
          : Column(
              children: rows.map((raw) {
                final p = _map(raw);
                final title = _text(p['title'] ?? p['name']);
                final subtitle =
                    '${_text(p['category'])} • ${_text(p['level'])} • ${_text(p['durationWeeks'] ?? p['duration'])} semanas';
                return _rowCard(
                  title,
                  _text(p['description']).isEmpty
                      ? subtitle
                      : '${_text(p['description'])}\n$subtitle',
                  Icons.fitness_center,
                  tail: _button(
                    'DETALHES',
                    Icons.open_in_new,
                    () => _showProgramDetails(p),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Future<void> _showProgramDetails(Map<String, dynamic> program) async {
    var details = program;
    final id = _text(program['id']);
    if (!const bool.fromEnvironment('PREVIEW_DASHBOARD') && id.isNotEmpty) {
      try {
        details = _map(await Api.get('/api/programs/$id'));
      } catch (e) {
        if (mounted) {
          setState(() => _notice = 'Não foi possível abrir o programa: $e');
        }
        return;
      }
    }
    if (!mounted) return;
    final exercises = _list(details['exercises']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: Text(_text(details['title'] ?? details['name'])),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_text(details['description'])),
                const SizedBox(height: 10),
                Text(
                  '${_text(details['durationWeeks'] ?? details['duration'])} semanas • ${_text(details['daysPerWeek'])} dias por semana',
                ),
                const SizedBox(height: 12),
                if (exercises.isEmpty)
                  const Text(
                    'O programa não possui exercícios detalhados nesta resposta.',
                  )
                else
                  ...exercises.map((raw) {
                    final exercise = _map(raw);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.fitness_center,
                        color: _mOrange,
                      ),
                      title: Text(_text(exercise['name'])),
                      subtitle: Text(
                        'Semana ${_text(exercise['week'])} • Dia ${_text(exercise['day'])} • ${_text(exercise['sets'])} séries • ${_text(exercise['reps'])}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(String userId, String name) async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      setState(() {
        _activeChatUserId = userId;
        _activeChatName = name;
        _activeChatMessages = [
          {
            'id': 'preview-history-$userId',
            'senderId': userId,
            'receiverId': _currentUserId.isEmpty
                ? 'preview-athlete'
                : _currentUserId,
            'text': 'Olá! Esta é uma conversa de demonstração.',
          },
        ];
        _notice = 'Conversa aberta na prévia.';
      });
      return;
    }
    setState(() {
      _activeChatUserId = userId;
      _activeChatName = name;
      _activeChatMessages = [];
      _busy = true;
    });
    try {
      final result = await Api.get('/api/messages/$userId');
      if (mounted) setState(() => _activeChatMessages = _list(result));
    } catch (e) {
      if (mounted) {
        setState(() => _notice = 'Não foi possível abrir a conversa: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendChatMessage() async {
    final receiverId = _activeChatUserId;
    final text = _message.text.trim();
    if (receiverId == null || receiverId.isEmpty || text.isEmpty || _busy) {
      return;
    }
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final next = List<dynamic>.from(_activeChatMessages)
        ..add({
          'id': 'preview-message-${DateTime.now().microsecondsSinceEpoch}',
          'senderId': _currentUserId.isEmpty
              ? 'preview-athlete'
              : _currentUserId,
          'receiverId': receiverId,
          'text': text,
        });
      setState(() {
        _activeChatMessages = next;
        _message.clear();
        _notice = 'Mensagem adicionada nesta prévia.';
      });
      return;
    }
    setState(() => _busy = true);
    try {
      await Api.post('/api/messages', {'receiverId': receiverId, 'text': text});
      _message.clear();
      final result = await Api.get('/api/messages/$receiverId');
      if (mounted) {
        setState(() {
          _activeChatMessages = _list(result);
          _notice = 'Mensagem enviada.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notice = 'Não foi possível enviar a mensagem: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _chatInbox(dynamic raw) {
    final root = _map(raw);
    final source = _map(root['conversations']);
    final contacts = <String, Map<String, dynamic>>{};
    for (final row in _list(source['sent'])) {
      final user = _map(_map(row)['receiver']);
      final id = _text(user['id']);
      if (id.isNotEmpty) contacts[id] = user;
    }
    for (final row in _list(source['received'])) {
      final user = _map(_map(row)['sender']);
      final id = _text(user['id']);
      if (id.isNotEmpty) contacts[id] = user;
    }
    return Column(
      children: [
        _section(
          'CONVERSAS',
          Icons.forum,
          contacts.isEmpty
              ? _empty('Nenhuma conversa disponível.')
              : Column(
                  children: contacts.entries.map((entry) {
                    final name = _text(entry.value['displayName']).isEmpty
                        ? 'Atleta'
                        : _text(entry.value['displayName']);
                    return _rowCard(
                      name,
                      'Toque para abrir o histórico de mensagens.',
                      Icons.person,
                      tail: _button(
                        _activeChatUserId == entry.key ? 'ABERTA' : 'ABRIR',
                        Icons.chat,
                        _busy ? null : () => _openChat(entry.key, name),
                      ),
                    );
                  }).toList(),
                ),
        ),
        if (_activeChatUserId != null) ...[
          const SizedBox(height: 12),
          _section(
            'CONVERSA COM $_activeChatName',
            Icons.chat_bubble_outline,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeChatMessages.isEmpty)
                  _empty('Ainda não há mensagens nesta conversa.')
                else
                  ..._activeChatMessages.map((item) {
                    final message = _map(item);
                    final mine = _text(message['senderId']) == _currentUserId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(maxWidth: 560),
                        decoration: BoxDecoration(
                          color: mine
                              ? _mOrange.withValues(alpha: .18)
                              : _mRaised,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_text(message['text'])),
                      ),
                    );
                  }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _input(_message, 'Escreva uma mensagem')),
                    const SizedBox(width: 8),
                    _button(
                      'ENVIAR',
                      Icons.send,
                      _busy ? null : _sendChatMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _profile(dynamic raw) {
    final p = _map(raw),
        athlete = _map(p['athlete']),
        integrations = _dataOrEmpty(1),
        personal = _map(p['personal']);
    return Column(
      children: [
        _section(
          'DADOS DA CONTA',
          Icons.person,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _rowCard(
                'Tipo de conta',
                _text(p['role'] == 'personal' ? 'Personal Trainer' : 'Atleta'),
                Icons.badge,
              ),
              _rowCard(
                'Nome',
                _text(p['name'] ?? athlete['name'] ?? personal['name']),
                Icons.person,
              ),
              _rowCard('E-mail', _text(p['email']), Icons.email),
              if (p['role'] != 'personal')
                _rowCard(
                  'Nível',
                  _text(athlete['experienceLevel']),
                  Icons.trending_up,
                ),
              _button('EDITAR NOME', Icons.edit, () => _editProfile(p)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'INTEGRAÇÕES',
          Icons.bluetooth,
          Column(
            children: [
              _genericList(
                _list(integrations),
                empty: 'Nenhuma integração conectada.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  _button(
                    'CONECTAR STRAVA',
                    Icons.link,
                    () => _connectIntegration('strava'),
                  ),
                  _button(
                    'CONECTAR GOOGLE FIT',
                    Icons.link,
                    () => _connectIntegration('google_fit'),
                  ),
                  ..._list(integrations).map((item) {
                    final m = _map(item),
                        provider = _text(
                          m['provider'] ?? m['name'],
                        ).toLowerCase();
                    return _button(
                      'DESCONECTAR ${provider.toUpperCase()}',
                      Icons.link_off,
                      () => _run(
                        () => Api.delete('/api/integrations', {
                          'provider': provider,
                        }),
                        'Integração desconectada.',
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'PRIVACIDADE & LGPD',
          Icons.privacy_tip,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _button(
                'EXPORTAR MEUS DADOS',
                Icons.download,
                () => _run(
                  () => Api.get('/api/user/export'),
                  'Exportação de dados solicitada.',
                ),
              ),
              _button(
                'ACEITAR TERMOS E PRIVACIDADE',
                Icons.verified_user,
                () => _run(
                  () => Api.post('/api/user/consent', {
                    'termsAccepted': true,
                    'privacyAccepted': true,
                    'dataConsent': true,
                  }),
                  'Consentimentos registrados.',
                ),
              ),
              _button('EXCLUIR CONTA', Icons.delete_forever, _deleteAccount),
              _button('SAIR DA CONTA', Icons.logout, widget.onLogout),
            ],
          ),
        ),
      ],
    );
  }

  List<dynamic> _dataOrEmpty(int i) => _dataValue(i);
  List<dynamic> _dataValue(int i) =>
      _currentData.length > i ? _list(_currentData[i]) : [];
  List<dynamic> get _currentData => _snapshotData;
  List<dynamic> _snapshotData = const [];
  Widget _pro(List<dynamic> d) => Column(
    children: [
      _section(
        'PLANOS DISPONÍVEIS',
        Icons.workspace_premium,
        Column(
          children: [
            _planCard(
              'WEGYM ESSENTIAL',
              'R\$ 89 / mês',
              'Treinos e histórico básico',
            ),
            _planCard(
              'WEGYM PRO ATHLETE',
              'R\$ 169 / mês',
              'Builder, telemetria e analytics',
            ),
            _planCard(
              'COACH STUDIO',
              'R\$ 349 / mês',
              'Gestão e consultoria individual',
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'ASSINATURA ATUAL',
        Icons.receipt_long,
        _genericList(
          _list(_map(d.isNotEmpty ? d[0] : null)['data']),
          empty: 'Nenhuma assinatura ativa retornada.',
        ),
      ),
    ],
  );
  Widget _planCard(String title, String price, String desc) => _rowCard(
    title,
    '$desc • $price',
    Icons.verified,
    tail: _button(
      'SELECIONAR',
      Icons.arrow_forward,
      () => _showInfo(
        'A cobrança requer configuração válida do Mercado Pago no backend.',
      ),
    ),
  );
  Widget _measurements(List<dynamic> d) => Column(
    children: [
      _section(
        'HISTÓRICO DE AVALIAÇÕES',
        Icons.monitor_weight,
        _genericList(
          _list(d.isNotEmpty ? d[0] : null),
          empty: 'Registre uma avaliação física para iniciar seu histórico.',
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'TENDÊNCIA DE PESO',
        Icons.show_chart,
        _genericList(_list(d.length > 1 ? d[1] : null)),
      ),
      const SizedBox(height: 12),
      _section(
        'GORDURA CORPORAL',
        Icons.analytics,
        _genericList(_list(d.length > 2 ? d[2] : null)),
      ),
    ],
  );
  Widget _checkin(List<dynamic> d) {
    final today = d.isNotEmpty ? _map(d[0]) : <String, dynamic>{};
    final history = d.length > 1 ? _map(d[1]) : <String, dynamic>{};
    final records = _list(history['checkIns'] ?? history['history']);
    return Column(
      children: [
        _section(
          'BEM-ESTAR DE HOJE',
          Icons.favorite,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (today.isNotEmpty)
                _rowCard(
                  'Check-in registrado',
                  'Humor ${_text(today['mood'])}/5 • Energia ${_text(today['energy'])}/5 • Sono ${_text(today['sleepHours'])} h',
                  Icons.check_circle,
                ),
              if (today.isEmpty)
                _empty('Ainda não há check-in registrado hoje.'),
              _button('REGISTRAR / ATUALIZAR', Icons.edit, _saveCheckin),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'CONSISTÊNCIA',
          Icons.local_fire_department,
          _rowCard(
            'Sequência atual',
            '${_text(history['streak'] ?? 0)} dias',
            Icons.bolt,
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'HISTÓRICO',
          Icons.history,
          _genericList(
            records,
            empty: 'Seus registros recentes aparecerão aqui.',
          ),
        ),
      ],
    );
  }

  Widget _friends(List<dynamic> d) => Column(
    children: [
      _section(
        'SUA REDE',
        Icons.people,
        _genericList(
          _list(d.isNotEmpty ? d[0] : null),
          empty: 'Ainda não há conexões para mostrar.',
        ),
      ),
      const SizedBox(height: 12),
      _section(
        'SOLICITAÇÕES',
        Icons.person_add_alt,
        _empty(
          'As solicitações pendentes são exibidas pelo serviço social quando disponíveis.',
        ),
      ),
    ],
  );
  Widget _classes(List<dynamic> d) => _section(
    'AULAS AGENDADAS',
    Icons.calendar_month,
    _genericList(
      _list(d.isNotEmpty ? d[0] : null),
      empty: 'Nenhuma aula foi encontrada para esta conta.',
    ),
  );
  Widget _section(String title, IconData icon, Widget child) =>
      StitchSection(title: title, icon: icon, child: child);
  Widget _rowCard(
    String title,
    String subtitle,
    IconData icon, {
    Widget? tail,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _mRaised,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        Icon(icon, color: _mOrange, size: 17),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _mText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
        ?tail,
      ],
    ),
  );
  Widget _genericList(
    List<dynamic> rows, {
    String empty = 'Nenhum dado encontrado.',
  }) => rows.isEmpty
      ? _empty(empty)
      : Column(
          children: rows.map((row) {
            final m = _map(row);
            final title = _text(
              m['name'] ??
                  m['title'] ??
                  m['type'] ??
                  m['date'] ??
                  m['id'] ??
                  'Registro',
            );
            final details = m.entries
                .where(
                  (e) =>
                      !['id', 'name', 'title'].contains(e.key) &&
                      e.value != null &&
                      e.value is! Map &&
                      e.value is! List,
                )
                .take(3)
                .map((e) => '${e.key}: ${e.value}')
                .join(' • ');
            return _rowCard(title, details, Icons.circle_outlined);
          }).toList(),
        );
  String _sessionModality(dynamic value) =>
      switch ((value ?? '').toString().trim().toLowerCase()) {
        'musculacao' ||
        'muscula\u00e7\u00e3o' ||
        'strength' => 'Muscula\u00e7\u00e3o',
        'corrida' || 'running' => 'Corrida',
        'cycling' || 'ciclismo' => 'Ciclismo',
        'walking' || 'caminhada' => 'Caminhada',
        final modality when modality.isEmpty => 'Treino',
        final modality => modality[0].toUpperCase() + modality.substring(1),
      };

  String _sessionDate(dynamic value) {
    final raw = (value ?? '').toString();
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} às $hour:$minute';
  }

  Widget _sessionList(List<dynamic> rows) => rows.isEmpty
      ? _empty('Sem sessões no período.')
      : Column(
          children: rows
              .map(
                (r) => _rowCard(
                  _sessionModality(r['modality']),
                  '${_duration(_n(r['durationSec']))} • ${_sessionDate(r['completedAt'])}',
                  Icons.fitness_center,
                ),
              )
              .toList(),
        );
  Widget _metricLine(String label, Map<String, dynamic> d) => _rowCard(
    label,
    '${_n(d['totalSessions']).round()} sessões • ${_duration(_n(d['totalVolume']))} • ${_n(d['totalDistance']).toStringAsFixed(1)} km',
    Icons.insights,
  );
  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(text, style: const TextStyle(color: _mMuted, fontSize: 11)),
  );
  Widget _noticeBox(String text) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: _mOrange.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: const TextStyle(color: _mMuted, fontSize: 11)),
  );
  Widget _input(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Future<void> _showChallengeLeaderboard(String challengeId) async {
    if (challengeId.isEmpty) return;
    await _run(() async {
      final response = await Api.get(
        '/api/challenges/$challengeId/leaderboard',
      );
      final rows = _list(response);
      if (!mounted) return response;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Ranking do desafio'),
          content: SizedBox(
            width: 420,
            child: rows.isEmpty
                ? const Text(
                    'Ainda n\u00e3o h\u00e1 participantes neste desafio.',
                  )
                : ListView(
                    shrinkWrap: true,
                    children: rows.take(20).toList().asMap().entries.map((
                      entry,
                    ) {
                      final item = _map(entry.value);
                      final user = _map(item['user']);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _mOrange,
                          child: Text((entry.key + 1).toString()),
                        ),
                        title: Text(_text(user['displayName'] ?? 'Atleta')),
                        subtitle: Text(
                          'Progresso: ${_text(item['currentValue'] ?? '0')}',
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      );
      return response;
    }, 'Ranking atualizado.');
  }

  Future<void> _composePost() async {
    final text = await _prompt(
      'Nova publicação',
      'O que você quer compartilhar?',
    );
    if (text != null && text.trim().isNotEmpty) {
      await _run(
        () => Api.post('/api/social', {'text': text.trim()}),
        'Publicação enviada.',
      );
    }
  }

  Future<void> _commentPost(String id) async {
    final text = await _prompt('Comentar publicação', 'Escreva seu comentário');
    if (text != null && text.trim().isNotEmpty) {
      await _run(
        () => Api.post('/api/social/$id/comment', {'text': text.trim()}),
        'Comentário enviado.',
      );
    }
  }

  Future<void> _editProfile(Map<String, dynamic> profile) async {
    final name = await _prompt('Editar nome', 'Nome completo');
    if (name != null && name.trim().isNotEmpty) {
      await _run(
        () => Api.patch('/api/user/profile', {'name': name.trim()}),
        'Perfil atualizado.',
      );
    }
  }

  Future<void> _connectIntegration(String provider) async {
    await _run(() async {
      final result = _map(
        await Api.post('/api/integrations', {'provider': provider}),
      );
      if (!mounted) return null;
      final url = _text(result['url']);
      if (url.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _mCard,
            title: const Text('Autorização necessária'),
            content: SelectableText(
              'Abra este endereço para autorizar a integração:\n\n$url',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('FECHAR'),
              ),
            ],
          ),
        );
      }
      return result;
    }, 'Autorização da integração iniciada.');
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Excluir conta?'),
        content: const Text(
          'Esta ação é permanente e apaga os dados da conta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(() => Api.delete('/api/user/account', {}), 'Conta excluída.');
    }
  }

  Future<void> _saveCheckin() async {
    final mood = double.tryParse(
      (await _prompt('Humor (1 a 5)', 'Número de 1 a 5') ?? '').replaceAll(
        ',',
        '.',
      ),
    );
    if (mood == null || mood < 1 || mood > 5) {
      _showInfo('Informe um humor entre 1 e 5.');
      return;
    }
    final energy = double.tryParse(
      (await _prompt('Energia (1 a 5)', 'Número de 1 a 5') ?? '').replaceAll(
        ',',
        '.',
      ),
    );
    if (energy == null || energy < 1 || energy > 5) {
      _showInfo('Informe energia entre 1 e 5.');
      return;
    }
    final sleep = double.tryParse(
      (await _prompt('Sono', 'Horas dormidas, por exemplo 7.5') ?? '')
          .replaceAll(',', '.'),
    );
    if (sleep == null || sleep < 0 || sleep > 24) {
      _showInfo('Informe as horas de sono (0 a 24).');
      return;
    }
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final next = List<dynamic>.from(_snapshotData);
      final today = {
        'date': DateTime.now().toIso8601String(),
        'mood': mood.round(),
        'energy': energy.round(),
        'sleepHours': sleep,
      };
      final history = next.length > 1 && next[1] is Map
          ? Map<String, dynamic>.from(_map(next[1]))
          : <String, dynamic>{};
      final records = List<dynamic>.from(
        _list(history['checkIns'] ?? history['history']),
      )..insert(0, today);
      history['checkIns'] = records;
      history['streak'] = _text(history['streak']).isEmpty
          ? 1
          : (int.tryParse(_text(history['streak'])) ?? 0) + 1;
      while (next.length < 2) {
        next.add({});
      }
      next[0] = today;
      next[1] = history;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Check-in salvo nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/checkin', {
        'mood': mood.round(),
        'energy': energy.round(),
        'sleepHours': sleep,
        'trained': false,
        'note': '',
      }),
      'Check-in salvo.',
    );
  }

  Future<void> _addFriend() async {
    final id = await _prompt('Adicionar amigo', 'ID da pessoa');
    if (id != null && id.trim().isNotEmpty) {
      if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
        final next = List<dynamic>.from(_snapshotData);
        final friends = List<dynamic>.from(
          _list(next.isNotEmpty ? next[0] : const []),
        );
        friends.add({
          'id': id.trim(),
          'name': 'Conexão de demonstração',
          'status': 'pending',
        });
        if (next.isEmpty) {
          next.add(friends);
        } else {
          next[0] = friends;
        }
        setState(() {
          _snapshotData = next;
          _data = Future.value(next);
          _notice = 'Solicitação adicionada nesta prévia.';
        });
        return;
      }
      await _run(
        () => Api.post('/api/friends', {'addresseeId': id.trim()}),
        'Solicitação enviada.',
      );
    }
  }

  Future<void> _createGoal() async {
    final title = await _prompt('Criar meta', 'Nome da meta');
    if (title == null || title.trim().isEmpty) return;
    final target = await _prompt('Valor alvo', 'Número da meta (ex.: 20)');
    if (target == null) return;
    final n = double.tryParse(target);
    if (n == null) {
      _showInfo('Informe um valor numérico.');
      return;
    }
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _mutatePreviewGoal(
        '',
        null,
        'Meta criada nesta prévia.',
        create: {
          'id': 'demo-goal-${DateTime.now().microsecondsSinceEpoch}',
          'title': title.trim(),
          'category': 'workout',
          'metric': 'sessions',
          'targetValue': n,
          'currentValue': 0,
          'status': 'active',
        },
      );
      return;
    }
    await _run(
      () => Api.post('/api/goals', {
        'title': title.trim(),
        'category': 'workout',
        'metric': 'sessions',
        'targetValue': n,
        'endDate': DateTime.now()
            .add(const Duration(days: 30))
            .toIso8601String(),
      }),
      'Meta criada.',
    );
  }

  Future<void> _createProgram() async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final title = await _prompt('Novo programa', 'Título do programa');
      if (title == null || title.trim().isEmpty) return;
      final next = List<dynamic>.from(_snapshotData);
      final programs = List<dynamic>.from(
        _list(next.length > 1 ? next[1] : const []),
      );
      programs.add({
        'id': 'preview-program-${DateTime.now().microsecondsSinceEpoch}',
        'title': title.trim(),
        'description': 'Programa criado nesta prévia.',
        'category': 'gym',
        'level': 'iniciante',
        'durationWeeks': 4,
        'daysPerWeek': 3,
      });
      while (next.length < 2) {
        next.add([]);
      }
      next[1] = programs;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Programa criado nesta prévia.';
      });
      return;
    }
    final title = await _prompt('Novo programa', 'Título do programa');
    if (title == null || title.trim().isEmpty) return;
    final category = await _prompt('Categoria', 'gym, running ou weight_loss');
    if (category == null || category.trim().isEmpty) return;
    final level = await _prompt(
      'Nível',
      'iniciante, intermediario ou avancado',
    );
    if (level == null || level.trim().isEmpty) return;
    final weeksText = await _prompt('Duração', 'Quantidade de semanas');
    final weeks = int.tryParse(weeksText ?? '');
    final daysText = await _prompt(
      'Frequência',
      'Dias de treino por semana (1 a 7)',
    );
    final days = int.tryParse(daysText ?? '');
    if (weeks == null || weeks <= 0 || days == null || days < 1 || days > 7) {
      _showInfo('Informe uma duração e frequência válidas.');
      return;
    }
    final description = await _prompt(
      'Descrição',
      'Resumo do programa (opcional)',
    );
    await _run(
      () => Api.post('/api/programs', {
        'title': title.trim(),
        'category': category.trim(),
        'level': level.trim(),
        'durationWeeks': weeks,
        'daysPerWeek': days,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      }),
      'Programa criado.',
    );
  }

  Future<void> _createMeasurement() async {
    final weight = await _prompt('Nova avaliação', 'Peso em kg');
    if (weight == null) return;
    final n = double.tryParse(weight.replaceAll(',', '.'));
    if (n == null) {
      _showInfo('Informe o peso em kg.');
      return;
    }
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final next = List<dynamic>.from(_snapshotData);
      final measurements = List<dynamic>.from(
        _list(next.isNotEmpty ? next[0] : const []),
      );
      measurements.insert(0, {
        'id': 'preview-measurement-${DateTime.now().microsecondsSinceEpoch}',
        'name': 'Peso',
        'value': '${n.toStringAsFixed(1)} kg',
        'date': 'Agora',
      });
      while (next.length < 3) {
        next.add([]);
      }
      next[0] = measurements;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Avaliação registrada nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/body-measurements', {
        'weight': n,
        'date': DateTime.now().toIso8601String(),
      }),
      'Avaliação registrada.',
    );
  }

  Future<void> _createDietPlan() async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _showInfo(
        'A criação de plano exige conexão com o backend para salvar os dados.',
      );
      return;
    }
    final title = await _prompt('Novo plano alimentar', 'Nome do plano');
    if (title == null || title.trim().isEmpty) return;
    final caloriesText = await _prompt(
      'Meta calórica diária',
      'Calorias por dia (opcional)',
    );
    final calories = caloriesText == null || caloriesText.trim().isEmpty
        ? null
        : double.tryParse(caloriesText.replaceAll(',', '.'));
    if (caloriesText != null &&
        caloriesText.trim().isNotEmpty &&
        (calories == null || calories <= 0)) {
      _showInfo('Informe um valor de calorias válido.');
      return;
    }
    await _run(
      () => Api.post('/api/nutrition/diet-plans', {
        'title': title.trim(),
        'dailyCalories': ?calories,
      }),
      'Plano alimentar criado.',
    );
  }

  Future<void> _createMeal() async {
    final type = await _prompt(
      'Registrar refeição',
      'Tipo: breakfast, lunch, dinner ou snack',
    );
    if (type == null) return;
    final normalized = type.trim().toLowerCase();
    if (!['breakfast', 'lunch', 'dinner', 'snack'].contains(normalized)) {
      _showInfo('Use breakfast, lunch, dinner ou snack.');
      return;
    }
    await _run(
      () => Api.post('/api/nutrition/meals', {
        'type': normalized,
        'date': DateTime.now().toIso8601String(),
      }),
      'Refeição registrada.',
    );
  }

  Future<void> _bookSlotFor(Map<String, dynamic> slot) async {
    final slotId = _text(slot['id']);
    if (slotId.isEmpty) {
      _showInfo('Este horário não possui um identificador válido.');
      return;
    }
    await _run(
      () => Api.post('/api/appointments', {'slotId': slotId, 'type': 'treino'}),
      'Agendamento solicitado.',
    );
  }

  Future<void> _bookSlot() async {
    final slot = await _prompt('Novo agendamento', 'ID do horário disponível');
    if (slot == null || slot.trim().isEmpty) return;
    await _run(
      () => Api.post('/api/appointments', {
        'slotId': slot.trim(),
        'type': 'treino',
      }),
      'Agendamento solicitado.',
    );
  }

  Future<String?> _prompt(String title, String hint) async {
    final c = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _mCard,
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  void _showInfo(String text) => showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: _mCard,
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  String _userName(dynamic row) =>
      _text(_map(_map(row)['user'])['displayName'] ?? 'Atleta');
  String _text(dynamic v) => v == null ? '' : v.toString();
  Map<String, dynamic> _payload(dynamic value) {
    final root = _map(value);
    return root['data'] is Map ? _map(root['data']) : root;
  }

  Map<String, dynamic> _map(dynamic v) => v is Map<String, dynamic>
      ? v
      : v is Map
      ? v.map((k, v) => MapEntry(k.toString(), v))
      : <String, dynamic>{};
  List<dynamic> _list(dynamic v) => v is List
      ? v
      : v is Map && v['data'] is List
      ? v['data'] as List
      : [];
  double _n(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
  String _duration(double v) {
    final sec = v.round().clamp(0, 9999999);
    return (sec ~/ 3600) > 0
        ? '${sec ~/ 3600}h${((sec % 3600) ~/ 60).toString().padLeft(2, '0')}'
        : '${(sec % 3600) ~/ 60} min';
  }
}
