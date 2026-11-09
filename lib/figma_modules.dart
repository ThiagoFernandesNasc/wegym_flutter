import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';
import 'nutrition_catalog.dart';
import 'nutrition_meal_builder.dart';
import 'stitch_design_system.dart';
import 'legal_document_page.dart';
import 'challenge_leaderboard_page.dart';
import 'program_detail_page.dart';
import 'payment_checkout_page.dart';
import 'profile_data_export.dart';
import 'profile_avatar.dart';
import 'personal_copilot_sheet.dart';
import 'pwa_install_card.dart';
import 'integration_return_link.dart';
import 'health_platform_integration.dart';
import 'workout_reminder_service.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

const _mCard = stitchSurface,
    _mRaised = stitchSurfaceLow,
    _mOrange = stitchOrange,
    _mText = stitchText,
    _mMuted = stitchMuted;

const _demoChallengeParticipants = <Map<String, String>>[
  {'displayName': 'Camila Duarte'},
  {'displayName': 'Marcos Silva'},
  {'displayName': 'Ana Souza'},
];

const _demoPersonalMedals = <Map<String, dynamic>>[
  {
    'id': 'preview-personal-first-athlete',
    'title': 'Primeiro Acompanhamento',
    'description': 'Vincule seu primeiro aluno ao perfil de personal.',
    'icon': '\u{1F91D}',
    'xpReward': 50,
  },
  {
    'id': 'preview-personal-five-athletes',
    'title': 'Equipe em Forma',
    'description': 'Acompanhe cinco alunos vinculados.',
    'icon': '\u{1F465}',
    'xpReward': 100,
  },
  {
    'id': 'preview-personal-ten-athletes',
    'title': 'Coach de Destaque',
    'description': 'Acompanhe dez alunos vinculados.',
    'icon': '\u{1F3C5}',
    'xpReward': 200,
  },
  {
    'id': 'preview-personal-twenty-five-athletes',
    'title': 'Refer\u00eancia em Treinamento',
    'description': 'Acompanhe 25 alunos vinculados.',
    'icon': '\u{1F3C6}',
    'xpReward': 350,
  },
  {
    'id': 'preview-personal-fifty-athletes',
    'title': 'Lideran\u00e7a de Elite',
    'description': 'Acompanhe 50 alunos vinculados.',
    'icon': '\u{1F451}',
    'xpReward': 500,
  },
  {
    'id': 'preview-personal-hundred-athletes',
    'title': 'Legado WeGYM',
    'description': 'Acompanhe 100 alunos vinculados.',
    'icon': '\u{1F31F}',
    'xpReward': 1000,
  },
];

const _demoAvailableMedals = <Map<String, dynamic>>[
  {
    'id': 'preview-medal-first-workout',
    'title': 'Primeiro Passo',
    'description': 'Complete seu primeiro treino registrado.',
    'icon': '\u{1F3C5}',
    'xpReward': 50,
  },
  {
    'id': 'preview-medal-consistency',
    'title': 'Ritmo Constante',
    'description': 'Treine quatro vezes na mesma semana.',
    'icon': '\u{1F525}',
    'xpReward': 100,
  },
  {
    'id': 'preview-medal-distance',
    'title': 'Desbravador',
    'description': 'Some 10 km em atividades registradas.',
    'icon': '\u{1F3C3}',
    'xpReward': 150,
  },
  {
    'id': 'preview-medal-personal-record',
    'title': 'Novo Recorde',
    'description': 'Supere uma marca pessoal em um exerc\u00EDcio.',
    'icon': '\u{1F3C6}',
    'xpReward': 200,
  },
];

class FigmaModulePage extends StatefulWidget {
  const FigmaModulePage({
    super.key,
    required this.module,
    this.onLogout,
    this.onNavigate,
  });
  final String module;
  final VoidCallback? onLogout;
  final ValueChanged<int>? onNavigate;
  @override
  State<FigmaModulePage> createState() => _FigmaModulePageState();
}

class _FigmaModulePageState extends State<FigmaModulePage> {
  late Future<List<dynamic>> _data = _load();
  bool _busy = false;
  String _analyticsPeriod = 'week';
  String _notice = '';
  String _currentUserId = '';
  String _currentUserName = '';
  String _currentRole = 'atleta';
  bool _hasAthleteProfile = false;
  String? _selectedMeasurementAthleteId;
  List<Map<String, dynamic>> _measurementAthletes = [];
  String? _selectedChallengeAthleteId;
  List<Map<String, dynamic>> _challengeAthletes = [];
  List<Map<String, dynamic>> get _previewAchievementCatalog =>
      _currentRole == 'personal' ? _demoPersonalMedals : _demoAvailableMedals;
  String? _athletesNextCursor;
  bool _athletesHasMore = false;
  bool _loadingMoreAthletes = false;
  final Set<String> _joinedChallengeIds = {};
  final _search = TextEditingController();
  final _message = TextEditingController();
  final _chatScroll = ScrollController();
  final _chatComposerKey = GlobalKey();
  final _receiver = TextEditingController();
  final _title = TextEditingController();
  final _value = TextEditingController();
  final _deleteConfirmation = TextEditingController();
  String? _activeChatUserId;
  String _activeChatName = '';
  Map<String, dynamic>? _chatPersonalContact;
  List<dynamic> _activeChatMessages = [];
  DateTime _nutritionDate = DateTime.now();
  final HealthPlatformIntegration _healthPlatform = HealthPlatformIntegration();
  final WorkoutReminderService _workoutReminders = WorkoutReminderService();
  HealthPlatformAvailability? _healthAvailability;
  NativeHealthSummary? _healthSummary;
  bool _healthBusy = false;
  bool _healthConnected = false;
  bool _workoutReminderEnabled = false;
  bool _workoutReminderBusy = false;
  String _workoutReminderNotice = '';
  String _healthNotice = '';

  @override
  void initState() {
    super.initState();
    integrationReturnLink.addListener(_handleIntegrationReturn);
    if (widget.module == 'Perfil & Configurações' &&
        HealthPlatformIntegration.isSupportedPlatform) {
      unawaited(_refreshHealthPlatform());
    }
    if (widget.module == 'Perfil & Configurações' &&
        _workoutReminders.isSupported) {
      unawaited(_refreshWorkoutReminder());
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleIntegrationReturn(),
    );
    if (Api.isDemoSession) {
      Api.previewChallengeIds().then((ids) {
        if (mounted) setState(() => _joinedChallengeIds.addAll(ids));
      });
    }
  }

  Future<void> _refreshHealthPlatform() async {
    try {
      final availability = await _healthPlatform.checkAvailability();
      if (!mounted) return;
      setState(() => _healthAvailability = availability);
      if (availability != HealthPlatformAvailability.available) return;
      final connected = await _healthPlatform.hasReadAccess();
      if (!mounted) return;
      setState(() => _healthConnected = connected);
      if (connected) await _syncHealthPlatform(showConfirmation: false);
    } catch (_) {
      if (mounted) {
        setState(
          () => _healthNotice = 'Não foi possível consultar a integração.',
        );
      }
    }
  }

  Future<void> _refreshWorkoutReminder() async {
    try {
      final enabled = await _workoutReminders.isScheduled();
      if (mounted) setState(() => _workoutReminderEnabled = enabled);
    } catch (_) {
      if (mounted) {
        setState(
          () => _workoutReminderNotice =
              'Não foi possível consultar o lembrete neste aparelho.',
        );
      }
    }
  }

  Future<void> _setWorkoutReminder(bool enabled) async {
    if (_workoutReminderBusy) return;
    setState(() {
      _workoutReminderBusy = true;
      _workoutReminderNotice = '';
    });
    try {
      if (enabled) {
        final scheduled = await _workoutReminders.enableDailyReminder();
        if (!scheduled) {
          setState(() {
            _workoutReminderEnabled = false;
            _workoutReminderNotice =
                'Permita notificações nas configurações do aparelho para ativar o lembrete.';
          });
        } else {
          setState(() {
            _workoutReminderEnabled = true;
            _workoutReminderNotice = 'Lembrete diário ativado para as 7h.';
          });
        }
      } else {
        await _workoutReminders.disableDailyReminder();
        setState(() {
          _workoutReminderEnabled = false;
          _workoutReminderNotice = 'Lembrete diário desativado.';
        });
      }
    } catch (_) {
      setState(() {
        _workoutReminderEnabled = false;
        _workoutReminderNotice =
            'Não foi possível atualizar o lembrete. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _workoutReminderBusy = false);
    }
  }

  Widget _workoutReminderCard() => _section(
    'LEMBRETES DE TREINO',
    Icons.notifications_active_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _workoutReminderEnabled,
            onChanged: _workoutReminderBusy ? null : _setWorkoutReminder,
            activeThumbColor: stitchOrange,
            title: const Text('Treinar todos os dias às 7h'),
            subtitle: const Text(
              'Receba um lembrete local no horário configurado.',
            ),
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: stitchOrange,
            ),
          ),
        ),
        if (_workoutReminderBusy) const LinearProgressIndicator(),
        if (_workoutReminderNotice.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _workoutReminderNotice,
            style: const TextStyle(color: _mMuted, fontSize: 11),
          ),
        ],
      ],
    ),
  );

  Future<void> _connectHealthPlatform() async {
    setState(() {
      _healthBusy = true;
      _healthNotice = '';
    });
    try {
      final availability = await _healthPlatform.checkAvailability();
      if (!mounted) return;
      setState(() => _healthAvailability = availability);
      if (availability == HealthPlatformAvailability.installRequired) {
        await _healthPlatform.installHealthConnect();
        return;
      }
      if (availability != HealthPlatformAvailability.available) {
        setState(
          () => _healthNotice =
              'Integração disponível somente no Android ou iOS.',
        );
        return;
      }
      final authorized = await _healthPlatform.requestAccess();
      if (!mounted) return;
      if (!authorized) {
        setState(
          () => _healthNotice =
              'A autorização não foi concedida. Confira as permissões do sistema.',
        );
        return;
      }
      setState(() => _healthConnected = true);
      await _syncHealthPlatform(showConfirmation: true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _healthNotice =
              'Não foi possível vincular. Verifique o app de saúde e as permissões do dispositivo.',
        );
      }
    } finally {
      if (mounted) setState(() => _healthBusy = false);
    }
  }

  Future<void> _syncHealthPlatform({required bool showConfirmation}) async {
    setState(() {
      _healthBusy = true;
      _healthNotice = '';
    });
    try {
      final summary = await _healthPlatform.readRecentSummary();
      if (!mounted) return;
      setState(() {
        _healthSummary = summary;
        _healthConnected = true;
        _healthNotice = showConfirmation
            ? 'Dados sincronizados dos últimos 7 dias.'
            : '';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _healthConnected = false;
          _healthNotice =
              'Sem acesso aos dados. Revise as permissões no app de saúde.';
        });
      }
    } finally {
      if (mounted) setState(() => _healthBusy = false);
    }
  }

  Widget _nativeHealthIntegrationCard() {
    final platformName = defaultTargetPlatform == TargetPlatform.iOS
        ? 'APPLE HEALTH'
        : 'HEALTH CONNECT';
    final availability = _healthAvailability;
    final installRequired =
        availability == HealthPlatformAvailability.installRequired;
    final status = availability == null
        ? 'VERIFICANDO DISPONIBILIDADE'
        : installRequired
        ? 'PRECISA SER INSTALADO'
        : _healthConnected
        ? 'CONECTADO'
        : 'NÃO VINCULADO';
    final summary = _healthSummary;
    return Container(
      key: const ValueKey('native-health-integration-card'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _mRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _mOrange.withValues(alpha: .24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? Icons.favorite
                    : Icons.health_and_safety,
                color: _mOrange,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platformName,
                      style: const TextStyle(
                        color: _mText,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: _healthConnected ? stitchGreen : _mMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (_healthBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_healthConnected)
                OutlinedButton.icon(
                  key: const ValueKey('native-health-sync'),
                  onPressed: () => _syncHealthPlatform(showConfirmation: true),
                  icon: const Icon(Icons.sync, size: 15),
                  label: const Text('SINCRONIZAR'),
                )
              else
                FilledButton.icon(
                  key: const ValueKey('native-health-connect'),
                  onPressed: availability == null
                      ? null
                      : _connectHealthPlatform,
                  icon: Icon(
                    installRequired ? Icons.download : Icons.link,
                    size: 15,
                  ),
                  label: Text(installRequired ? 'INSTALAR' : 'VINCULAR'),
                ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _healthMetric('${summary.steps} passos', Icons.directions_walk),
                _healthMetric(
                  summary.heartRateBpm == null
                      ? 'Sem batimentos'
                      : '${summary.heartRateBpm!.round()} bpm médios',
                  Icons.favorite_border,
                ),
                _healthMetric(
                  summary.restingHeartRateBpm == null
                      ? 'Sem FC em repouso'
                      : '${summary.restingHeartRateBpm!.round()} bpm em repouso',
                  Icons.monitor_heart_outlined,
                ),
                _healthMetric(
                  '${(summary.distanceMeters / 1000).toStringAsFixed(1)} km',
                  Icons.route,
                ),
                _healthMetric(
                  '${summary.activeCalories.round()} kcal',
                  Icons.local_fire_department,
                ),
                _healthMetric(
                  '${summary.sleepMinutes.round()} min de sono',
                  Icons.bedtime_outlined,
                ),
                _healthMetric(
                  '${summary.workouts} treinos',
                  Icons.fitness_center,
                ),
              ],
            ),
          ],
          if (_healthNotice.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              _healthNotice,
              style: const TextStyle(color: _mMuted, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _healthMetric(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: _mCard,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _mOrange),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: _mText, fontSize: 10)),
      ],
    ),
  );

  List<String> get _paths => switch (widget.module) {
    'Comunidade' => [
      '/api/social?feed=friends',
      '/api/challenges',
      '/api/achievements',
    ],
    'Conquistas' => ['/api/achievements'],
    'Analytics & Performance' => [
      '/api/workout-stats?period=week',
      '/api/workout-stats?period=month',
      '/api/workout-stats?period=year',
      '/api/workout-sessions?limit=30',
      '/api/body-measurements',
    ],
    'Agendamentos' => ['/api/appointments', '/api/appointments/slots'],
    'Nutrição' => [
      "/api/nutrition/meals?date=${_nutritionDateKey(_nutritionDate)}",
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
    'Amigos' => ['/api/friends?includeRequests=1'],
    'Aulas' => ['/api/classes'],
    _ => [],
  };

  Future<List<dynamic>> _load() async {
    if (Api.isDemoSession) {
      _currentRole = await Api.previewRole() ?? 'atleta';
      _hasAthleteProfile = false;
      _currentUserName = _currentRole == 'personal'
          ? 'Rafael Costa'
          : 'Jo\u00e3o Silva';
      final previewData = _preview();
      if (widget.module == 'Chat' && _currentRole == 'personal') {
        final inbox = _map(previewData.isNotEmpty ? previewData[0] : null);
        final rawConversations = inbox['conversations'];
        final conversations = Map<String, dynamic>.from(
          rawConversations is Map ? _map(rawConversations) : const {},
        );
        final sent = List<dynamic>.from(
          rawConversations is List
              ? rawConversations
              : _list(conversations['sent']),
        );
        sent.addAll([
          {
            'receiver': {
              'id': 'preview-student-1',
              'displayName': 'Mariana Costa',
            },
          },
          {
            'receiver': {
              'id': 'preview-student-2',
              'displayName': 'Pedro Almeida',
            },
          },
          {
            'receiver': {
              'id': 'preview-student-3',
              'displayName': 'Julia Santos',
            },
          },
        ]);
        conversations['sent'] = sent;
        inbox['conversations'] = conversations;
        while (previewData.isEmpty) {
          previewData.add(<dynamic>[]);
        }
        previewData[0] = inbox;
      }
      if (widget.module == 'Aulas' && _currentRole == 'personal') {
        final students = [
          {'id': 'preview-athlete-1', 'name': 'Mariana Costa'},
          {'id': 'preview-athlete-2', 'name': 'Pedro Almeida'},
          {'id': 'preview-athlete-3', 'name': 'Julia Santos'},
        ];
        final classes = List<Map<String, dynamic>>.from(
          _list(
            previewData.isNotEmpty ? previewData[0] : null,
          ).map((item) => Map<String, dynamic>.from(_map(item))),
        );
        classes.addAll(await Api.previewClasses());
        while (previewData.length < 2) {
          previewData.add(<dynamic>[]);
        }
        previewData[0] = classes;
        previewData[1] = students;
      }
      final challengeIndex = switch (widget.module) {
        'Comunidade' => 1,
        'Metas & Desafios' => 1,
        _ => -1,
      };
      if (challengeIndex >= 0 && previewData.length > challengeIndex) {
        _joinedChallengeIds.addAll(await Api.previewChallengeIds());
        final customChallenges = await Api.previewCustomChallenges();
        final existing = _list(previewData[challengeIndex]);
        previewData[challengeIndex] = [
          ...existing,
          ...customChallenges.where(
            (challenge) => !existing.any(
              (row) => _text(_map(row)['id']) == _text(challenge['id']),
            ),
          ),
        ];
      }
      await _restoreLocalAvatar(previewData);
      return previewData;
    }
    final profile = await Api.profile();
    _currentUserId = profile['id']?.toString() ?? '';
    _hasAthleteProfile = _map(profile['athlete']).isNotEmpty;
    final athleteName = _text(_map(profile['athlete'])['name']).trim();
    _chatPersonalContact = _map(_map(profile['athlete'])['personal']);
    final personalName = _text(_map(profile['personal'])['name']).trim();
    final displayName = _text(profile['displayName'] ?? profile['name']).trim();
    final emailName = _text(profile['email']).split('@').first.trim();
    _currentUserName = athleteName.isNotEmpty
        ? athleteName
        : personalName.isNotEmpty
        ? personalName
        : displayName.isNotEmpty
        ? displayName
        : emailName.isNotEmpty
        ? emailName
        : 'Usu\u00e1rio';
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
    if (role == 'personal' && widget.module == 'Medidas') {
      List<Map<String, dynamic>> athletes;
      try {
        athletes = await Api.athletes();
        _measurementAthletes = athletes;
      } catch (error) {
        return [
          {
            '_error':
                'N\u00e3o foi poss\u00edvel carregar os alunos vinculados: $error',
          },
          [],
          [],
          _measurementAthletes,
        ];
      }
      final availableIds = athletes
          .map((athlete) => _text(athlete['id']))
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!availableIds.contains(_selectedMeasurementAthleteId)) {
        _selectedMeasurementAthleteId = availableIds.isEmpty
            ? null
            : availableIds.first;
      }
      final athleteId = _selectedMeasurementAthleteId;
      if (athleteId == null) return [[], [], [], _measurementAthletes];
      final queryId = Uri.encodeQueryComponent(athleteId);
      try {
        final values = await Future.wait([
          Api.get('/api/body-measurements?athleteId=$queryId'),
          Api.get('/api/body-measurements?metric=weight&athleteId=$queryId'),
          Api.get('/api/body-measurements?metric=bodyFat&athleteId=$queryId'),
        ]);
        return [...values, _measurementAthletes];
      } catch (error) {
        return [
          {
            '_error':
                'N\u00e3o foi poss\u00edvel carregar as avalia\u00e7\u00f5es do aluno selecionado: $error',
          },
          [],
          [],
          _measurementAthletes,
        ];
      }
    }
    if (role == 'personal' && widget.module == 'Analytics & Performance') {
      return [
        {
          '__info':
              'M\u00e9tricas vinculadas ao perfil individual de Atleta. Acesse Alunos & Personal para consultar seus alunos.',
        },
      ];
    }
    final paths = _paths;
    if (widget.module == 'Chat' && _currentRole == 'personal') {
      paths.add('/api/athletes?take=50');
    }
    if (widget.module == 'Aulas' && _currentRole == 'personal') {
      paths.add('/api/athletes?take=50');
    }
    if (widget.module == 'Chat') {
      paths.add('/api/friends');
    }
    if (_currentRole == 'personal' &&
        (widget.module == 'Comunidade' ||
            widget.module == 'Metas & Desafios')) {
      paths.add('/api/athletes?take=50');
    }
    if (widget.module == 'Agendamentos') {
      final personalUserId = _currentRole == 'personal'
          ? _currentUserId
          : profile['athlete'] is Map
          ? (profile['athlete'] as Map)['personalUserId']?.toString() ?? ''
          : '';
      final slotsPath = Uri(
        path: '/api/appointments/slots',
        queryParameters: {'personalId': personalUserId},
      ).toString();
      paths[1] = slotsPath;
    }
    final result = await Future.wait(
      paths.map((path) async {
        try {
          return await Api.get(path);
        } catch (e) {
          return {'_error': '$path: $e'};
        }
      }),
    );
    if (_currentRole == 'personal' &&
        (widget.module == 'Comunidade' ||
            widget.module == 'Metas & Desafios') &&
        result.isNotEmpty) {
      final rows = _list(result.last);
      _challengeAthletes = rows
          .map((row) => Map<String, dynamic>.from(_map(row)))
          .toList();
      final validIds = _challengeAthletes
          .map((athlete) => _text(athlete['id']))
          .where((id) => id.isNotEmpty)
          .toSet();
      if (!validIds.contains(_selectedChallengeAthleteId)) {
        _selectedChallengeAthleteId = validIds.isEmpty ? null : validIds.first;
      }
    }
    if (widget.module == 'Comunidade' && result.isNotEmpty) {
      final response = result[0];
      final feed = _map(response);
      final posts = List<dynamic>.from(_list(feed['posts'] ?? response));
      final existingIds = posts.map((post) => _text(_map(post)['id'])).toSet();
      posts.addAll(
        _communityDemoPosts().where(
          (post) => !existingIds.contains(_text(post['id'])),
        ),
      );
      result[0] = {'posts': posts};
    }
    if (widget.module == 'Alunos & Personal' && result.length > 1) {
      final page = _map(result[1]);
      _athletesNextCursor = page['nextCursor']?.toString();
      _athletesHasMore =
          page['hasMore'] == true || (_athletesNextCursor?.isNotEmpty ?? false);
      if (page.containsKey('data')) result[1] = _list(page['data']);
    }
    await _restoreLocalAvatar(result);
    return result;
  }

  String _avatarStorageKey(Map profile) {
    final identity = _text(profile['id']).isNotEmpty
        ? _text(profile['id'])
        : _text(profile['email']);
    return 'wegym_profile_avatar_${identity.toLowerCase()}';
  }

  Future<void> _restoreLocalAvatar(List<dynamic> rows) async {
    if (widget.module != 'Perfil & Configurações' ||
        rows.isEmpty ||
        rows.first is! Map) {
      return;
    }
    final profile = Map<String, dynamic>.from(_map(rows.first));
    if (_text(profile['avatarUrl']).isNotEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final savedAvatar = preferences.getString(_avatarStorageKey(profile));
    if (savedAvatar == null || savedAvatar.isEmpty) return;
    profile['avatarUrl'] = savedAvatar;
    rows[0] = profile;
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
            'participants': _demoChallengeParticipants,
          },
          {
            'id': 'c2',
            'name': 'Desafio da consist\u00eancia',
            'description': 'Treine por 21 dias sem interrup\u00e7\u00f5es.',
            'progress': 66.7,
            'participants': _demoChallengeParticipants.take(2).toList(),
          },
        ],
        {
          'achievements': _previewAchievementCatalog,
          'userAchievements': [
            {
              'id': 'preview-earned-medal-1',
              'achievementId': 'preview-medal-first-workout',
              'earnedAt': now,
            },
          ],
        },
      ],
      'Conquistas' => [
        {
          'achievements': _previewAchievementCatalog,
          'userAchievements': [
            {
              'id': 'preview-earned-1',
              'achievementId': _currentRole == 'personal'
                  ? 'preview-personal-first-athlete'
                  : 'preview-medal-first-workout',
              'earnedAt': now,
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
            'foods': <dynamic>[],
            'totals': {'calories': 420, 'proteinG': 28},
            'calorias': '420 kcal',
            'prote\u00ednas': '28 g',
          },
          {
            'id': 'meal2',
            'name': 'Almo\u00e7o',
            'type': 'lunch',
            'foods': <dynamic>[],
            'totals': {'calories': 680, 'proteinG': 42},
            'calorias': '680 kcal',
            'prote\u00ednas': '42 g',
          },
          {
            'id': 'meal3',
            'name': 'Lanche da tarde',
            'type': 'snack',
            'foods': <dynamic>[],
            'totals': {'calories': 260, 'proteinG': 18},
            'calorias': '260 kcal',
            'prote\u00ednas': '18 g',
          },
        ],
        [
          {
            'id': 'diet1',
            'name': 'Plano de hipertrofia',
            'description': 'Plano alimentar demonstrativo',
            'dailyCalories': 2400,
            'proteinGoal': 160,
            'carbsGoal': 280,
            'fatGoal': 70,
            'calorias': '2.400 kcal',
            'prote\u00ednas': '160 g',
            'carboidratos': '280 g',
            'gorduras': '70 g',
          },
        ],
        nutritionDemoFoods,
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
          'achievements': _previewAchievementCatalog,
          'userAchievements': [
            {
              'id': 'preview-earned-medal-1',
              'achievementId': 'preview-medal-first-workout',
              'earnedAt': now,
            },
          ],
        },
      ],
      'Programas' => [
        [
          {
            'id': 'pr1',
            'name': 'Hipertrofia em 8 semanas',
            'description':
                'Divisão de quatro dias para trabalhar os principais grupos musculares com progressão gradual.',
            'level': 'Intermediário',
            'durationWeeks': 8,
            'daysPerWeek': 4,
            'category': 'Força',
            'exercises': [
              {
                'week': 1,
                'day': 1,
                'name': 'Supino reto com barra',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Supino inclinado com halteres',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Crossover na polia',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Tríceps na corda',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Puxada alta pela frente',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Remada baixa',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Face pull',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Rosca direta',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Agachamento livre',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Levantamento terra romeno',
                'sets': '3',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Cadeira extensora',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Mesa flexora',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Desenvolvimento com halteres',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Elevação lateral',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Tríceps testa',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Rosca martelo',
                'sets': '3',
                'reps': '10\u201312',
              },
            ],
          },
          {
            'id': 'pr2',
            'name': 'Condicionamento total',
            'description':
                'Plano inicial de cardio e exercícios funcionais para desenvolver resistência com segurança.',
            'level': 'Iniciante',
            'durationWeeks': 6,
            'daysPerWeek': 3,
            'category': 'Cardio',
            'exercises': [
              {
                'week': 1,
                'day': 1,
                'name': 'Caminhada rápida',
                'duration': '25 min',
                'notes': 'Mantenha um ritmo confortável.',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Agachamento com peso corporal',
                'sets': '3',
                'reps': '10',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Flexão inclinada',
                'sets': '3',
                'reps': '8',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Caminhada e trote leve',
                'duration': '20 min',
                'notes': 'Alterne 2 min caminhando e 1 min trotando.',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Ponte de glúteos',
                'sets': '3',
                'reps': '12',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Prancha',
                'sets': '3',
                'duration': '20 s',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Bicicleta ergométrica',
                'duration': '25 min',
                'notes': 'Intensidade leve a moderada.',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Avanço alternado',
                'sets': '3',
                'reps': '8 por perna',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Abdominal curto',
                'sets': '3',
                'reps': '12',
              },
            ],
          },
        ],
        [
          {
            'id': 'pr1',
            'name': 'Hipertrofia em 8 semanas',
            'description':
                'Divisão de quatro dias para trabalhar os principais grupos musculares com progressão gradual.',
            'level': 'Intermediário',
            'durationWeeks': 8,
            'daysPerWeek': 4,
            'category': 'Força',
            'exercises': [
              {
                'week': 1,
                'day': 1,
                'name': 'Supino reto com barra',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Supino inclinado com halteres',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Crossover na polia',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Tríceps na corda',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Puxada alta pela frente',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Remada baixa',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Face pull',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Rosca direta',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Agachamento livre',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Levantamento terra romeno',
                'sets': '3',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Cadeira extensora',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Mesa flexora',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Desenvolvimento com halteres',
                'sets': '4',
                'reps': '8\u201310',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Elevação lateral',
                'sets': '3',
                'reps': '12\u201315',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Tríceps testa',
                'sets': '3',
                'reps': '10\u201312',
              },
              {
                'week': 1,
                'day': 4,
                'name': 'Rosca martelo',
                'sets': '3',
                'reps': '10\u201312',
              },
            ],
          },
          {
            'id': 'pr2',
            'name': 'Condicionamento total',
            'description':
                'Plano inicial de cardio e exercícios funcionais para desenvolver resistência com segurança.',
            'level': 'Iniciante',
            'durationWeeks': 6,
            'daysPerWeek': 3,
            'category': 'Cardio',
            'exercises': [
              {
                'week': 1,
                'day': 1,
                'name': 'Caminhada rápida',
                'duration': '25 min',
                'notes': 'Mantenha um ritmo confortável.',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Agachamento com peso corporal',
                'sets': '3',
                'reps': '10',
              },
              {
                'week': 1,
                'day': 1,
                'name': 'Flexão inclinada',
                'sets': '3',
                'reps': '8',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Caminhada e trote leve',
                'duration': '20 min',
                'notes': 'Alterne 2 min caminhando e 1 min trotando.',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Ponte de glúteos',
                'sets': '3',
                'reps': '12',
              },
              {
                'week': 1,
                'day': 2,
                'name': 'Prancha',
                'sets': '3',
                'duration': '20 s',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Bicicleta ergométrica',
                'duration': '25 min',
                'notes': 'Intensidade leve a moderada.',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Avanço alternado',
                'sets': '3',
                'reps': '8 por perna',
              },
              {
                'week': 1,
                'day': 3,
                'name': 'Abdominal curto',
                'sets': '3',
                'reps': '12',
              },
            ],
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
          'role': _currentRole,
          'personal': {'name': 'Marcos Silva', 'cref': '0948-G/SP'},
          'athlete': {
            'name': 'Rafael Costa',
            'weightKg': 81.4,
            'heightCm': 182,
            'city': 'Jardins',
            'state': 'SP',
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
        {
          'friends': [
            {
              'id': 'preview-friend',
              'displayName': 'Mariana Costa',
              'status': 'accepted',
            },
          ],
          'incomingRequests': [
            {
              'id': 'preview-request-1',
              'displayName': 'Lucas Mendes',
              'status': 'pending',
            },
          ],
          'outgoingRequests': [],
        },
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
    if (widget.module == 'Alunos & Personal') {
      _athletesNextCursor = null;
      _athletesHasMore = false;
    }
    setState(() {
      _data = _load();
      _notice = '';
    });
    await _data;
  }

  void _handleIntegrationReturn() {
    if (widget.module != 'Perfil & Configura\u00e7\u00f5es') return;
    final uri = integrationReturnLink.value;
    if (uri == null) return;
    final provider = uri.queryParameters['integration'];
    final result = uri.queryParameters['integration_result'];
    if (!['strava', 'google_fit'].contains(provider) ||
        !['success', 'error'].contains(result)) {
      return;
    }

    integrationReturnLink.value = null;
    final name = provider == 'strava' ? 'Strava' : 'Google Fit';
    unawaited(() async {
      await _refresh();
      if (!mounted) return;
      setState(() {
        _notice = result == 'success'
            ? '$name conectado. As integra\u00e7\u00f5es foram atualizadas.'
            : 'A autoriza\u00e7\u00e3o do $name n\u00e3o foi conclu\u00edda.';
      });
    }());
  }

  Future<void> _run(Future<dynamic> Function() call, String success) async {
    if (Api.isDemoSession) {
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
    integrationReturnLink.removeListener(_handleIntegrationReturn);
    _search.dispose();
    _message.dispose();
    _chatScroll.dispose();
    _receiver.dispose();
    _title.dispose();
    _value.dispose();
    _deleteConfirmation.dispose();
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
                        if (Api.isDemoSession)
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
                        else if (widget.module == 'Conquistas')
                          _achievementCatalog(primary)
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
                          _chatInbox(
                            primary,
                            _currentRole == 'personal' && data.length > 1
                                ? data[1]
                                : null,
                            data.length > (_currentRole == 'personal' ? 2 : 1)
                                ? data[_currentRole == 'personal' ? 2 : 1]
                                : null,
                            _chatPersonalContact,
                          )
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
    'Conquistas' => (
      'CONQUISTAS DO ATLETA',
      'Acompanhe suas medalhas, pontos de experiência e próximos objetivos.',
      'Progresso e reconhecimento',
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
            if (widget.module == 'Aulas' && _currentRole == 'personal')
              _button(
                'REGISTRAR AULA',
                Icons.add,
                () => _createClass(_snapshotData),
              ),
            if (widget.module == 'Comunidade')
              _button('PUBLICAR', Icons.add, _composePost),
            if (widget.module == 'Metas & Desafios')
              _button('NOVA META', Icons.flag, _createGoal),
            if (widget.module == 'Medidas')
              _button('NOVA AVALIAÇÃO', Icons.add, _createMeasurement),
            if (widget.module == 'Nutrição')
              _button('REGISTRAR REFEIÇÃO', Icons.restaurant, _createMeal),
            if (widget.module == 'Agendamentos')
              _button(
                _currentRole == 'personal'
                    ? 'NOVO HORÁRIO'
                    : 'NOVO AGENDAMENTO',
                Icons.event,
                _bookSlot,
              ),
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
    final availableAchievements = _list(rawStats['achievements']);
    final earnedAchievements = _list(rawStats['userAchievements']);
    final earnedIds = earnedAchievements
        .map((item) => _text(_map(item)['achievementId']))
        .toSet();
    final earnedXp = availableAchievements
        .where(
          (achievement) => earnedIds.contains(_text(_map(achievement)['id'])),
        )
        .fold<double>(
          0,
          (total, achievement) => total + _n(_map(achievement)['xpReward']),
        );
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
      'Conquistas' => [
        (
          'CONQUISTAS DISPONÍVEIS',
          availableAchievements.length.toString(),
          Icons.military_tech,
        ),
        (
          'CONQUISTADAS',
          earnedAchievements.length.toString(),
          Icons.emoji_events,
        ),
        ('XP CONQUISTADO', earnedXp.round().toString(), Icons.bolt),
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
        final itemWidth = constraints.maxWidth < 460
            ? constraints.maxWidth
            : constraints.maxWidth < 520
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
                    maxValueLines: card.$1 == 'ALERTAS' && itemWidth < 190
                        ? 2
                        : 1,
                    valueFontSize: card.$1 == 'ALERTAS' && itemWidth < 190
                        ? 17
                        : 21,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<Map<String, dynamic>> _communityDemoPosts() => [
    {
      'id': 'demo-post-camila',
      'isDemoExample': true,
      'text': 'Novo recorde no agachamento: 140 kg! Consist\u00eancia pagando.',
      'createdAt': DateTime.now().toIso8601String(),
      'user': {'displayName': 'Camila Duarte'},
      '_count': {'likes': 34, 'comments': 2},
      'comments': [
        {
          'text':
              'Parab\u00e9ns pelo recorde! Evolu\u00e7\u00e3o incr\u00edvel.',
          'user': {'displayName': 'Marcos Silva'},
        },
        {
          'text': 'Consist\u00eancia d\u00e1 resultado. Mandou muito bem!',
          'user': {'displayName': 'Ana Souza'},
        },
      ],
    },
    {
      'id': 'demo-post-marcos',
      'isDemoExample': true,
      'text': 'Treino de pernas conclu\u00eddo. Bora manter o ritmo!',
      'createdAt': DateTime.now().toIso8601String(),
      'user': {'displayName': 'Marcos Silva'},
      '_count': {'likes': 19, 'comments': 2},
      'comments': [
        {
          'text': 'Boa! J\u00e1 garanti o meu treino de hoje tamb\u00e9m.',
          'user': {'displayName': 'Camila Duarte'},
        },
        {
          'text': 'Ritmo forte! Continue assim.',
          'user': {'displayName': 'Rafael Costa'},
        },
      ],
    },
    {
      'id': 'demo-post-ana',
      'isDemoExample': true,
      'text': 'Mais uma semana de foco e disciplina.',
      'createdAt': DateTime.now().toIso8601String(),
      'user': {'displayName': 'Ana Souza'},
      '_count': {'likes': 12, 'comments': 2},
      'comments': [
        {
          'text': 'Semana conclu\u00edda com sucesso!',
          'user': {'displayName': 'Marcos Silva'},
        },
        {
          'text': 'Inspira\u00e7\u00e3o para continuar firme.',
          'user': {'displayName': 'Camila Duarte'},
        },
      ],
    },
  ];

  Widget _community(List<dynamic> d, bool wide) {
    final feedResponse = d.isNotEmpty ? d[0] : null;
    final feed = _map(feedResponse);
    final posts = List<dynamic>.from(_list(feed['posts'] ?? feedResponse));
    final challenges = _list(d.length > 1 ? d[1] : null);
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

  Widget _achievementCatalog(dynamic raw) {
    final data = _map(raw);
    final achievements = _list(data['achievements']);
    final earnedById = <String, Map<String, dynamic>>{
      for (final value in _list(data['userAchievements']))
        if (_text(_map(value)['achievementId']).isNotEmpty)
          _text(_map(value)['achievementId']): _map(value),
    };
    if (achievements.isEmpty) {
      return _section(
        'MEDALHAS DISPON\u00CDVEIS',
        Icons.military_tech,
        _empty('Nenhuma medalha est\u00E1 dispon\u00EDvel no momento.'),
      );
    }
    return _section(
      'MEDALHAS DISPON\u00CDVEIS',
      Icons.military_tech,
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 3
              : constraints.maxWidth >= 520
              ? 2
              : 1;
          final spacing = 10.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: achievements.map((value) {
              final achievement = _map(value);
              final id = _text(achievement['id']);
              final earned = earnedById[id];
              final nested = _map(earned?['achievement']);
              final xp = _n(achievement['xpReward'] ?? nested['xpReward']);
              final earnedAt = _text(earned?['earnedAt']);
              final date = DateTime.tryParse(earnedAt);
              return SizedBox(
                width: width,
                child: Container(
                  height: 184,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: earned == null
                        ? _mRaised
                        : _mOrange.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: earned == null
                          ? Colors.white10
                          : _mOrange.withValues(alpha: .36),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _text(achievement['icon']).isEmpty
                                  ? '🏅'
                                  : _text(achievement['icon']),
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                          Icon(
                            earned == null
                                ? Icons.lock_outline
                                : Icons.check_circle,
                            color: earned == null ? _mMuted : stitchGreen,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _text(achievement['title']),
                        style: const TextStyle(
                          color: _mText,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _text(achievement['description']),
                        style: const TextStyle(
                          color: _mMuted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.bolt, color: _mOrange, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '+${xp.round()} XP',
                            style: const TextStyle(
                              color: _mOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          if (earned != null)
                            Text(
                              date == null
                                  ? 'CONQUISTADA'
                                  : 'EM ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                              style: const TextStyle(
                                color: stitchGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else
                            const Text(
                              'BLOQUEADA',
                              style: TextStyle(
                                color: _mMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _postList(List<dynamic> rows) => rows.isEmpty
      ? _empty('Seu mural aparecer? quando houver publica??es.')
      : Column(
          children: rows.map((value) {
            final post = _map(value);
            final id = _text(post['id']);
            final isMine =
                (id.startsWith('preview-post-') && Api.isDemoSession) ||
                (_currentUserId.isNotEmpty &&
                    _text(_map(post['user'])['id']) == _currentUserId);
            final imageUrl = _text(post['imageUrl']).trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _rowCard(
                    '${_userName(post)}${post['isDemoExample'] == true ? ' \u00b7 DEMONSTRA\u00c7\u00c3O' : ''}',
                    _text(post['text'] ?? post['content']),
                    Icons.groups,
                    tail: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Curtir',
                          onPressed: () => _togglePostLike(post),
                          icon: Icon(
                            post['likedByCurrentUser'] == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _mOrange,
                          ),
                        ),
                        Text(_text(_map(post['_count'])['likes'])),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Ver coment\u00e1rios',
                          onPressed: () => _showPostComments(post),
                          icon: const Icon(
                            Icons.comment_outlined,
                            color: _mOrange,
                          ),
                        ),
                        Text(_text(_map(post['_count'])['comments'])),
                        if (isMine)
                          PopupMenuButton<String>(
                            tooltip: 'Opções da publicação',
                            onSelected: (action) {
                              if (action == 'delete') _deletePost(post);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Apagar publicação'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 6,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _socialImage(imageUrl, height: 260),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        );

  Widget _socialImage(String source, {double height = 180}) {
    final image = source.startsWith('data:image/')
        ? Image.memory(
            base64Decode(source.substring(source.indexOf(',') + 1)),
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
          )
        : Image.network(
            source,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
    return image;
  }

  Future<String?> _pickSocialImage() async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 72,
      );
      if (selected == null) return null;
      final bytes = await selected.readAsBytes();
      if (bytes.length > 280_000) {
        _showInfo('A foto excede o limite. Escolha uma imagem menor.');
        return null;
      }
      final mimeType =
          selected.mimeType == 'image/png' || selected.mimeType == 'image/webp'
          ? selected.mimeType!
          : 'image/jpeg';
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    } catch (error) {
      if (mounted) {
        _showInfo('N\u00e3o foi poss\u00edvel selecionar a foto: $error');
      }
      return null;
    }
  }

  Future<void> _showPostComments(Map<String, dynamic> post) async {
    final comments = _list(post['comments']).map(_map).toList();
    final total = _n(_map(post['_count'])['comments']).round();
    if ((Api.isDemoSession || post['isDemoExample'] == true) &&
        comments.length < total) {
      for (var index = comments.length; index < total; index++) {
        comments.add({
          'text': index.isEven
              ? 'Mandou bem no treino! Vamos manter a consist\u00eancia.'
              : 'Parab\u00e9ns pelo progresso. Continue assim!',
          'user': {
            'displayName': index.isEven ? 'Rafael Costa' : 'Camila Duarte',
          },
        });
      }
    }
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: Row(
          children: [
            const Icon(Icons.comment_outlined, color: _mOrange),
            const SizedBox(width: 10),
            Expanded(child: Text('Coment\u00e1rios ($total)')),
          ],
        ),
        content: SizedBox(
          width: _dialogWidth(dialogContext, 480),
          height: MediaQuery.sizeOf(dialogContext).height * .55,
          child: comments.isEmpty
              ? const Center(
                  child: Text(
                    'Ainda n\u00e3o h\u00e1 coment\u00e1rios nesta publica\u00e7\u00e3o.',
                    style: TextStyle(color: _mMuted),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final user = _map(comment['user']);
                    final name = _communityUserName(user);
                    final commentId = _text(comment['id']);
                    final isMine =
                        commentId.startsWith('preview-comment-') ||
                        (_currentUserId.isNotEmpty &&
                            (_text(comment['userId']) == _currentUserId ||
                                _text(user['id']) == _currentUserId));
                    final imageUrl = _text(comment['imageUrl']).trim();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: _mText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isMine && commentId.isNotEmpty)
                              IconButton(
                                tooltip: 'Apagar meu coment\u00e1rio',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => Navigator.pop(
                                  dialogContext,
                                  'delete:$commentId',
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: _mMuted,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        if (_text(comment['text']).trim().isNotEmpty)
                          Text(
                            _text(comment['text']),
                            style: const TextStyle(
                              color: _mMuted,
                              fontSize: 13,
                            ),
                          ),
                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _socialImage(imageUrl, height: 200),
                          ),
                        ],
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'add'),
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('COMENTAR'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    if (result == 'add') {
      await _commentPost(_text(post['id']));
    } else if (result.startsWith('delete:')) {
      await _deletePostComment(_text(post['id']), result.substring(7));
    }
  }

  Future<void> _deletePostComment(String postId, String commentId) async {
    if (postId.isEmpty || commentId.isEmpty) return;
    if (commentId.startsWith('preview-comment-') || Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final feed = Map<String, dynamic>.from(_map(next[0]));
      final posts = List<dynamic>.from(_list(feed['posts']));
      final index = posts.indexWhere(
        (item) => _text(_map(item)['id']) == postId,
      );
      if (index < 0) return;
      final post = Map<String, dynamic>.from(_map(posts[index]));
      final comments = List<dynamic>.from(_list(post['comments']))
        ..removeWhere((item) => _text(_map(item)['id']) == commentId);
      post['comments'] = comments;
      final counts = Map<String, dynamic>.from(_map(post['_count']));
      counts['comments'] = comments.length;
      post['_count'] = counts;
      posts[index] = post;
      feed['posts'] = posts;
      next[0] = feed;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Coment\u00e1rio apagado nesta pr\u00e9via.';
      });
      return;
    }
    await _run(
      () => Api.delete('/api/social/$postId/comment/$commentId', {}),
      'Seu coment\u00e1rio foi apagado.',
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final id = _text(post['id']);
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Apagar publicação?'),
        content: const Text('Esta ação removerá sua publicação do mural.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('APAGAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (id.startsWith('preview-post-') || Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final feed = Map<String, dynamic>.from(_map(next[0]));
      final posts = List<dynamic>.from(_list(feed['posts']))
        ..removeWhere((item) => _text(_map(item)['id']) == id);
      feed['posts'] = posts;
      next[0] = feed;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Publica\u00e7\u00e3o apagada nesta pr\u00e9via.';
      });
      return;
    }
    await _run(
      () => Api.delete('/api/social/$id', {}),
      'Sua publicação foi apagada.',
    );
  }

  bool _isParticipating(Map challenge) {
    final id = _text(challenge['id']);
    if (id.isEmpty) return false;
    if (Api.isDemoSession || _currentRole != 'personal') {
      if (_joinedChallengeIds.contains(id)) return true;
    }
    final participantUserId = _currentRole == 'personal'
        ? _text(_selectedChallengeAthlete?['userId'])
        : _currentUserId;
    return participantUserId.isNotEmpty &&
        _list(challenge['participants']).any(
          (participant) =>
              _text(_map(participant)['userId']) == participantUserId,
        );
  }

  Map<String, dynamic>? get _selectedChallengeAthlete => _challengeAthletes
      .where((athlete) => _text(athlete['id']) == _selectedChallengeAthleteId)
      .firstOrNull;

  Future<void> _joinChallenge(Map challenge) async {
    final id = _text(challenge['id']);
    if (id.isEmpty || _isParticipating(challenge) || _busy) return;
    final demo = Api.isDemoSession;
    final selectedAthlete = _currentRole == 'personal' && !demo
        ? _selectedChallengeAthlete
        : null;
    if (_currentRole == 'personal' &&
        !demo &&
        (selectedAthlete == null || _text(selectedAthlete['id']).isEmpty)) {
      setState(() => _notice = 'Selecione um aluno vinculado para participar.');
      return;
    }
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
                'Participa\u00e7\u00e3o registrada nesta pr\u00e9via.',
          );
        }
      } else {
        await Api.post('/api/challenges', {
          'challengeId': id,
          if (selectedAthlete != null)
            'athleteId': _text(selectedAthlete['id']),
        });
        _joinedChallengeIds.add(id);
        await _refresh();
        if (mounted) setState(() => _notice = 'Voc\u00ea entrou no desafio.');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice = 'N\u00e3o foi poss\u00edvel participar: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveChallenge(Map challenge) async {
    final id = _text(challenge['id']);
    if (id.isEmpty || !_isParticipating(challenge) || _busy) return;
    final selectedAthlete = _currentRole == 'personal' && !Api.isDemoSession
        ? _selectedChallengeAthlete
        : null;
    setState(() {
      _busy = true;
      _notice = '';
    });
    try {
      if (Api.isDemoSession) {
        _joinedChallengeIds.remove(id);
        await Api.savePreviewChallengeIds(_joinedChallengeIds.toList());
        if (mounted) {
          setState(() {
            _data = _load();
            _notice = 'Voc\u00ea saiu do desafio nesta pr\u00e9via.';
          });
        }
      } else {
        final athleteQuery = selectedAthlete == null
            ? ''
            : '?athleteId=${Uri.encodeQueryComponent(_text(selectedAthlete['id']))}';
        await Api.delete(
          '/api/challenges/${Uri.encodeComponent(id)}$athleteQuery',
          {},
        );
        _joinedChallengeIds.remove(id);
        await _refresh();
        if (mounted) setState(() => _notice = 'Voc\u00ea saiu do desafio.');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice = 'N\u00e3o foi poss\u00edvel sair do desafio: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createChallenge() async {
    final title = await _prompt('Criar desafio', 'Nome do desafio');
    if (title == null || title.trim().length < 3) return;
    final description = await _prompt(
      'Descri\u00e7\u00e3o',
      'Explique o objetivo do desafio',
    );
    if (description == null) return;
    if (!mounted) return;
    const types = <(String, String, String)>[
      ('workouts', 'Treinos conclu\u00eddos', 'sess\u00f5es'),
      ('distance', 'Dist\u00e2ncia percorrida', 'km'),
      ('calories', 'Calorias ativas', 'kcal'),
      ('custom', 'Meta personalizada', 'pontos'),
    ];
    final type = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: _mCard,
        title: const Text('Tipo de desafio'),
        children: types
            .map(
              (item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, item.$1),
                child: Text('${item.$2} (${item.$3})'),
              ),
            )
            .toList(),
      ),
    );
    if (type == null) return;
    final targetText = await _prompt(
      'Meta do desafio',
      'Informe o valor a ser alcan\u00e7ado',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final target = double.tryParse(
      (targetText ?? '').trim().replaceAll(',', '.'),
    );
    if (target == null || target <= 0) {
      _showInfo('Informe uma meta maior que zero.');
      return;
    }
    final durationText = await _prompt(
      'Dura\u00e7\u00e3o',
      'N\u00famero de dias (1 a 365)',
      keyboardType: TextInputType.number,
    );
    final days = int.tryParse((durationText ?? '').trim());
    if (days == null || days < 1 || days > 365) {
      _showInfo('A dura\u00e7\u00e3o precisa ser de 1 a 365 dias.');
      return;
    }
    final startDate = DateTime.now().toUtc();
    final endDate = startDate.add(Duration(days: days));
    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'type': type,
      'goalValue': target,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    setState(() {
      _busy = true;
      _notice = '';
    });
    try {
      if (Api.isDemoSession) {
        final challenge = <String, dynamic>{
          'id': 'preview-custom-${startDate.microsecondsSinceEpoch}',
          'title': title.trim(),
          'name': title.trim(),
          'description': description.trim(),
          'type': type,
          'goalValue': target,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'participants': _demoChallengeParticipants.take(2).toList(),
          'creatorName': _currentRole == 'personal'
              ? 'Personal de demonstra\u00e7\u00e3o'
              : 'Atleta de demonstra\u00e7\u00e3o',
        };
        final custom = await Api.previewCustomChallenges();
        custom.add(challenge);
        await Api.savePreviewCustomChallenges(custom);
        _joinedChallengeIds.add(challenge['id'] as String);
        await Api.savePreviewChallengeIds(_joinedChallengeIds.toList());
        final next = List<dynamic>.from(_snapshotData);
        if (next.length > 1) next[1] = [..._list(next[1]), challenge];
        if (!mounted) return;
        setState(() {
          _snapshotData = next;
          _data = Future.value(next);
          _notice = 'Desafio criado. Voc\u00ea j\u00e1 est\u00e1 participando.';
        });
      } else {
        final result = await Api.post('/api/challenges', body);
        final id = _text(_map(result)['id']);
        if (id.isNotEmpty) _joinedChallengeIds.add(id);
        await _refresh();
        if (mounted) {
          setState(() {
            _notice =
                'Desafio criado. Voc\u00ea j\u00e1 est\u00e1 participando.';
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice = 'N\u00e3o foi poss\u00edvel criar o desafio: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _challengeCards(List<dynamic> rows) => Column(
    children: [
      if (_currentRole == 'personal' && !Api.isDemoSession)
        _challengeAthleteSelector(),
      if (rows.isEmpty)
        _empty('Nenhum desafio ativo foi encontrado.')
      else
        ...rows.map((row) {
          final challenge = _map(row);
          final joined = _isParticipating(challenge);
          final demo = Api.isDemoSession;
          final people = _list(challenge['participants']);
          final names = people
              .map((person) {
                final participant = _map(person);
                final user = _map(participant['user']);
                final profileName = _text(
                  participant['displayName'] ??
                      participant['name'] ??
                      user['displayName'] ??
                      user['name'] ??
                      _map(user['athlete'])['name'] ??
                      _map(user['personal'])['name'],
                );
                if (profileName.isNotEmpty) return profileName;
                if (_currentRole == 'personal' && !demo) {
                  final selectedAthlete = _selectedChallengeAthlete;
                  if (selectedAthlete != null &&
                      _text(participant['userId']) ==
                          _text(selectedAthlete['userId'])) {
                    final selectedName = _text(selectedAthlete['name']).trim();
                    if (selectedName.isNotEmpty) return selectedName;
                  }
                }
                if (_currentUserId.isNotEmpty &&
                    _text(participant['userId']) == _currentUserId) {
                  return _currentUserName;
                }
                return '';
              })
              .where((name) => name.isNotEmpty)
              .toList();
          if (_currentRole == 'personal' && !demo && joined) {
            final selectedName = _text(
              _selectedChallengeAthlete?['name'],
            ).trim();
            if (selectedName.isNotEmpty && !names.contains(selectedName)) {
              names.add(selectedName);
            }
          }
          if ((_currentRole != 'personal' || _hasAthleteProfile) &&
              !demo &&
              joined) {
            final accountName = _currentUserName.trim();
            if (accountName.isNotEmpty && !names.contains(accountName)) {
              names.add(accountName);
            }
          }
          final fictionalNames = demo
              ? <String>[]
              : _demoChallengeParticipants
                    .map((participant) => _text(participant['displayName']))
                    .where((name) => name.isNotEmpty && !names.contains(name))
                    .toList();
          final demoName = _currentUserName.isEmpty
              ? 'Voc\u00ea'
              : _currentUserName;
          if (demo && joined && !names.contains(demoName)) names.add(demoName);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _section(
              _text(challenge['name'] ?? challenge['title']),
              Icons.local_fire_department,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(challenge['description']),
                    style: const TextStyle(color: _mMuted),
                  ),
                  if (challenge['goalValue'] != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Meta: ${_n(challenge['goalValue'])} ${switch (_text(challenge['type'])) {
                            'distance' => 'km',
                            'workouts' => 'sess\u00f5es',
                            'calories' => 'kcal',
                            _ => 'pontos',
                          }}',
                      style: const TextStyle(color: _mMuted, fontSize: 12),
                    ),
                  ],
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
                        joined ? 'SAIR' : 'PARTICIPAR',
                        joined ? Icons.exit_to_app : Icons.add,
                        _busy
                            ? null
                            : () => joined
                                  ? _leaveChallenge(challenge)
                                  : _joinChallenge(challenge),
                      ),
                    ],
                  ),
                  if (names.isNotEmpty) ...[
                    const Divider(height: 20),
                    Text(
                      demo
                          ? 'PARTICIPANTES DE DEMONSTRA\u00c7\u00c3O'
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
                            (name) => Chip(
                              avatar: const Icon(Icons.person, size: 15),
                              label: Text(name),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    if (demo)
                      const Text(
                        'Nomes fict\u00edcios para a apresenta\u00e7\u00e3o.',
                        style: TextStyle(fontSize: 11, color: _mMuted),
                      ),
                  ],
                  if (fictionalNames.isNotEmpty) ...[
                    const Divider(height: 20),
                    const Text(
                      'EXEMPLOS FICT\u00CDCIOS (N\u00C3O CONTABILIZADOS)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _mMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: fictionalNames
                          .map(
                            (name) => Chip(
                              avatar: const Icon(
                                Icons.person_outline,
                                size: 15,
                              ),
                              label: Text(name),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const Text(
                      'Nomes ilustrativos; n\u00E3o entram no total de participantes.',
                      style: TextStyle(fontSize: 11, color: _mMuted),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      Align(
        alignment: Alignment.centerRight,
        child: _button(
          'CRIAR DESAFIO',
          Icons.add,
          _busy ? null : _createChallenge,
        ),
      ),
    ],
  );

  Widget _challengeAthleteSelector() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _mRaised,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALUNO QUE PARTICIPARÁ',
          style: TextStyle(
            color: _mMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_challengeAthletes.isEmpty)
          const Text(
            'Nenhum aluno vinculado foi encontrado. Vincule o atleta em Alunos & Personal.',
            style: TextStyle(color: _mMuted, fontSize: 12),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedChallengeAthleteId,
            isExpanded: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: 'Selecione um aluno vinculado',
            ),
            items: _challengeAthletes.map((athlete) {
              final id = _text(athlete['id']);
              final name = _text(athlete['name']).trim();
              return DropdownMenuItem<String>(
                value: id,
                child: Text(name.isEmpty ? 'Atleta' : name),
              );
            }).toList(),
            onChanged: (id) {
              if (id == null) return;
              setState(() {
                _selectedChallengeAthleteId = id;
                _notice = '';
              });
            },
          ),
      ],
    ),
  );

  Widget _analytics(List<dynamic> d) {
    final week = _payload(d.isNotEmpty ? d[0] : null),
        month = _payload(d.length > 1 ? d[1] : null),
        year = _payload(d.length > 2 ? d[2] : null),
        sessions = _list(d.length > 3 ? d[3] : null),
        measures = _list(d.length > 4 ? d[4] : null);
    final selected = switch (_analyticsPeriod) {
      'month' => month,
      'year' => year,
      _ => week,
    };
    final activeSeconds = _n(
      selected['totalActiveTime'] ?? selected['totalVolume'],
    );
    final count = _n(selected['totalSessions']);
    final metrics = <(String, String, IconData)>[
      ('Sessoes', count.round().toString(), Icons.fitness_center),
      ('Tempo ativo', _duration(activeSeconds), Icons.timer_outlined),
      (
        'Calorias',
        '${_n(selected['totalCalories']).round()} kcal',
        Icons.local_fire_department_outlined,
      ),
      (
        'Distancia',
        '${_n(selected['totalDistance']).toStringAsFixed(1)} km',
        Icons.route_outlined,
      ),
      (
        'FC media',
        '${_n(selected['avgHeartRate']).round()} bpm',
        Icons.favorite_border,
      ),
      (
        'Media por sessao',
        count > 0 ? _duration(activeSeconds / count) : '--',
        Icons.query_stats,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section(
          'ANALYTICS & PERFORMANCE',
          Icons.insights,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children:
                    [
                          ('week', '7 DIAS'),
                          ('month', '30 DIAS'),
                          ('year', '12 MESES'),
                        ]
                        .map(
                          (period) => ChoiceChip(
                            label: Text(period.$2),
                            selected: _analyticsPeriod == period.$1,
                            onSelected: (_) =>
                                setState(() => _analyticsPeriod = period.$1),
                            selectedColor: _mOrange,
                            labelStyle: TextStyle(
                              color: _analyticsPeriod == period.$1
                                  ? Colors.black
                                  : _mText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 480
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 10 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: metrics
                        .map(
                          (metric) => SizedBox(
                            width: width,
                            child: _rowCard(metric.$1, metric.$2, metric.$3),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              _analyticsChart(selected),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final recent = _section(
              'SESSOES RECENTES',
              Icons.fitness_center,
              _sessionList(sessions),
            );
            final body = _section(
              'COMPOSICAO CORPORAL',
              Icons.monitor_weight,
              _genericList(measures),
            );
            if (constraints.maxWidth < 700) {
              return Column(
                children: [recent, const SizedBox(height: 12), body],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: recent),
                const SizedBox(width: 12),
                Expanded(child: body),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _analyticsChart(Map<String, dynamic> stats) {
    final raw = _map(stats['chartData']);
    final now = DateTime.now();
    final buckets = <String, double>{};
    final labels = <String>[];
    if (_analyticsPeriod == 'year') {
      for (var offset = 11; offset >= 0; offset--) {
        final date = DateTime(now.year, now.month - offset, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        labels.add(key);
        buckets[key] = 0;
      }
      for (final entry in raw.entries) {
        final date = DateTime.tryParse(entry.key.toString());
        if (date == null) continue;
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        if (buckets.containsKey(key)) {
          buckets[key] = buckets[key]! + _n(entry.value);
        }
      }
    } else {
      final days = _analyticsPeriod == 'month' ? 30 : 7;
      for (var offset = days - 1; offset >= 0; offset--) {
        final date = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: offset));
        final key = date.toIso8601String().substring(0, 10);
        labels.add(key);
        buckets[key] = _n(raw[key]);
      }
    }
    final values = labels.map((key) => buckets[key] ?? 0).toList();
    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final visibleLabels = _analyticsPeriod == 'week'
        ? labels.map((key) => key.substring(8, 10)).toList()
        : _analyticsPeriod == 'month'
        ? labels
              .asMap()
              .entries
              .map(
                (e) => e.key % 5 == 0 || e.key == labels.length - 1
                    ? e.value.substring(8, 10)
                    : '',
              )
              .toList()
        : labels.map((key) => key.substring(5, 7)).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mRaised,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TEMPO DE TREINO',
            style: TextStyle(
              color: _mText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(labels.length, (index) {
                final fraction = maxValue == 0 ? 0.0 : values[index] / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: fraction.clamp(.035, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _mOrange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          visibleLabels[index],
                          style: const TextStyle(color: _mMuted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          if (maxValue == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Ainda nao ha sessoes neste periodo.',
                style: TextStyle(color: _mMuted, fontSize: 11),
              ),
            ),
        ],
      ),
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
                                  : () => _changeAppointment(id, 'cancel'),
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
                                  : () => _changeAppointment(id, 'confirm'),
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
                      tail: _currentRole == 'personal'
                          ? const Icon(
                              Icons.event_available,
                              color: Colors.green,
                            )
                          : _button(
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

  String _nutritionDateKey(DateTime date) =>
      "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  String _nutritionDateLabel(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _selectNutritionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nutritionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _nutritionDate = DateTime(selected.year, selected.month, selected.day);
      _data = _load();
      _notice = '';
    });
  }

  Widget _nutritionManager(List<dynamic> d) {
    final meals = _list(d.isNotEmpty ? d[0] : null);
    final plans = _list(d.length > 1 ? d[1] : null);
    final foods = _list(d.length > 2 ? d[2] : null);
    return Column(
      children: [
        _section(
          'DIÁRIO ALIMENTAR',
          Icons.calendar_today,
          Row(
            children: [
              Expanded(
                child: Text(
                  _nutritionDateLabel(_nutritionDate),
                  style: const TextStyle(
                    color: _mText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const ValueKey('nutrition-select-date'),
                onPressed: _selectNutritionDate,
                icon: const Icon(Icons.edit_calendar, size: 16),
                label: const Text('ESCOLHER DATA'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                        id.isEmpty ? null : () => _addFoodToMeal(id),
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
                  tail: _button(
                    'ABRIR PLANO',
                    Icons.open_in_new,
                    () => _showDietPlanDetails(p),
                  ),
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
          'ALIMENTOS SUGERIDOS',
          Icons.search,
          _nutritionFoodList(foods),
        ),
      ],
    );
  }

  Widget _nutritionFoodList(List<dynamic> foods) {
    if (foods.isEmpty) {
      return _empty(
        'Nenhum alimento sugerido foi encontrado. Use “Adicionar alimento” na refeição para buscar ou cadastrar uma alternativa.',
      );
    }

    String unitLabel(dynamic rawUnit) {
      final unit = _text(rawUnit).trim().toLowerCase();
      return switch (unit) {
        'unit' || 'un' || 'un.' || 'unidade' || 'units' => 'unidade',
        'ml' || 'milliliter' || 'milliliters' => 'ml',
        'kg' => 'kg',
        'portion' || 'porção' || 'porcao' => 'porção',
        '' => 'g',
        _ => unit,
      };
    }

    String formatNumber(double value) =>
        value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

    return Column(
      children: foods.map((rawFood) {
        final food = _map(rawFood);
        final serving = _n(food['servingSize']);
        final unit = unitLabel(food['servingUnit']);
        final calories = _n(food['calories']).round();
        final protein = _n(food['proteinG']);
        final carbs = _n(food['carbsG']);
        final fat = _n(food['fatG']);
        final details = <String>[
          if (serving > 0) 'Porção de ${formatNumber(serving)} $unit',
          '$calories kcal',
          if (food['proteinG'] != null) 'Proteínas: ${formatNumber(protein)} g',
          if (food['carbsG'] != null) 'Carboidratos: ${formatNumber(carbs)} g',
          if (food['fatG'] != null) 'Gorduras: ${formatNumber(fat)} g',
        ];
        final name = _text(food['name']).trim();
        return _rowCard(
          name.isEmpty ? 'Alimento' : name,
          details.join(' • '),
          Icons.restaurant_menu,
        );
      }).toList(),
    );
  }

  Future<void> _addFoodToMeal(String mealId) async {
    final initialFoods = _list(
      _dataOrEmpty(2),
    ).map((food) => Map<String, dynamic>.from(_map(food))).toList();
    Future<List<Map<String, dynamic>>> searchFoods(String query) async {
      if (Api.isDemoSession) {
        final normalizedQuery = _normalizeNutritionText(query);
        return initialFoods.where((food) {
          final text = _normalizeNutritionText(
            '${food['name'] ?? ''} ${food['aliases'] ?? ''} ${food['category'] ?? ''}',
          );
          return text.contains(normalizedQuery);
        }).toList();
      }
      final response = await Api.get(
        '/api/nutrition/foods?q=${Uri.encodeQueryComponent(query)}',
      );
      return _list(
        response,
      ).map((food) => Map<String, dynamic>.from(_map(food))).toList();
    }

    final selections = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NutritionMealBuilderDialog(
        foods: initialFoods,
        searchFoods: searchFoods,
      ),
    );
    if (selections == null || selections.isEmpty || !mounted) return;

    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final meals = List<dynamic>.from(_list(next[0]));
      final mealIndex = meals.indexWhere(
        (meal) => _text(_map(meal)['id']) == mealId,
      );
      if (mealIndex < 0) return;
      final meal = Map<String, dynamic>.from(_map(meals[mealIndex]));
      final mealFoods = List<dynamic>.from(_list(meal['foods']));
      final totals = Map<String, dynamic>.from(_map(meal['totals']));
      for (final selection in selections) {
        final food = Map<String, dynamic>.from(_map(selection['food']));
        final amount = _n(selection['amount']);
        if (food.isEmpty || amount <= 0) continue;
        mealFoods.add({'food': food, 'amount': amount});
        for (final field in ['calories', 'proteinG', 'carbsG', 'fatG']) {
          totals[field] = _n(totals[field]) + _n(food[field]) * amount;
        }
      }
      meal['foods'] = mealFoods;
      meal['totals'] = totals;
      meals[mealIndex] = meal;
      next[0] = meals;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Alimentos adicionados ao prato nesta pr\u00e9via.';
      });
      return;
    }

    await _run(() async {
      for (final selection in selections) {
        final food = _map(selection['food']);
        var foodId = _text(food['id']);
        if (foodId.isEmpty) {
          final savedFood = await Api.post('/api/nutrition/foods', {
            'name': _text(food['name']),
            'servingSize': _n(food['servingSize']),
            'servingUnit': _text(food['servingUnit']).isEmpty
                ? 'g'
                : _text(food['servingUnit']),
            'calories': _n(food['calories']),
            'proteinG': _n(food['proteinG']),
            'carbsG': _n(food['carbsG']),
            'fatG': _n(food['fatG']),
            'category': _text(food['category']).isEmpty
                ? 'other'
                : _text(food['category']),
          });
          foodId = _text(_map(savedFood)['id']);
          if (foodId.isEmpty) {
            throw StateError('O servidor não retornou o alimento criado.');
          }
        }
        await Api.post('/api/nutrition/meals', {
          'mealId': mealId,
          'foodId': foodId,
          'amount': _n(selection['amount']),
        });
      }
    }, 'Refei\u00e7\u00e3o atualizada.');
  }

  String _normalizeNutritionText(String value) {
    var normalized = value.toLowerCase();
    const replacements = <int, String>{
      0xe1: 'a',
      0xe0: 'a',
      0xe3: 'a',
      0xe2: 'a',
      0xe4: 'a',
      0xe9: 'e',
      0xe8: 'e',
      0xea: 'e',
      0xeb: 'e',
      0xed: 'i',
      0xec: 'i',
      0xee: 'i',
      0xef: 'i',
      0xf3: 'o',
      0xf2: 'o',
      0xf5: 'o',
      0xf4: 'o',
      0xf6: 'o',
      0xfa: 'u',
      0xf9: 'u',
      0xfb: 'u',
      0xfc: 'u',
      0xe7: 'c',
    };
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(
        String.fromCharCode(entry.key),
        entry.value,
      );
    }
    return normalized;
  }

  Future<void> _showDietPlanDetails(Map<String, dynamic> plan) async {
    String value(String key, String unit) {
      final raw = plan[key];
      if (raw == null || raw.toString().isEmpty) return 'N\u00e3o definido';
      final number = _n(raw);
      final formatted = number == number.roundToDouble()
          ? number.round().toString()
          : number.toStringAsFixed(1);
      return '$formatted $unit';
    }

    final title = _text(plan['title'] ?? plan['name']);
    final description = _text(plan['description']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: Text(
          title.isEmpty ? 'Plano alimentar' : title,
          style: const TextStyle(color: _mText, fontWeight: FontWeight.w900),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: _dialogWidth(dialogContext, 560),
            maxHeight: MediaQuery.sizeOf(dialogContext).height * .7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isEmpty
                      ? 'Metas nutricionais do plano'
                      : description,
                  style: const TextStyle(color: _mMuted, height: 1.45),
                ),
                const SizedBox(height: 16),
                _rowCard(
                  'Calorias por dia',
                  value('dailyCalories', 'kcal'),
                  Icons.local_fire_department,
                ),
                _rowCard(
                  'Prote\u00ednas',
                  value('proteinGoal', 'g'),
                  Icons.fitness_center,
                ),
                _rowCard('Carboidratos', value('carbsGoal', 'g'), Icons.grain),
                _rowCard(
                  'Gorduras',
                  value('fatGoal', 'g'),
                  Icons.water_drop_outlined,
                ),
                if (plan['startDate'] != null || plan['endDate'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Per\u00edodo: ${_text(plan['startDate']).split('T').first} \u2014 ${_text(plan['endDate']).isEmpty
                              ? 'sem data final'
                              : _text(plan['endDate']).split('T').first}',
                      style: const TextStyle(color: _mMuted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Widget _students(List<dynamic> data) {
    final students = _list(data.length > 1 ? data[1] : null).map(_map).toList();
    return Column(
      children: [
        _section(
          'ALUNOS E ADES\u00c3O',
          Icons.groups,
          Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('personal-copilot-open'),
                      onPressed: _busy
                          ? null
                          : () => showPersonalCopilot(context),
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('GEMINI IA'),
                    ),
                    _button(
                      'NOVO ALUNO',
                      Icons.person_add_alt_1,
                      _showStudentOptions,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (students.isEmpty)
                _empty('Nenhum aluno vinculado a este Personal.')
              else
                ...students.map(_studentCard),
              if (_athletesHasMore && !Api.isDemoSession) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('load-more-athletes'),
                  onPressed: _loadingMoreAthletes ? null : _loadMoreAthletes,
                  icon: _loadingMoreAthletes
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    _loadingMoreAthletes
                        ? 'CARREGANDO...'
                        : 'CARREGAR MAIS ALUNOS',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'A\u00c7\u00d5ES DO COACH',
          Icons.bolt,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _button(
                'CRIAR HOR\u00c1RIO DISPON\u00cdVEL',
                Icons.event_available,
                () => _bookSlot(),
              ),
              _button('ATUALIZAR LISTA', Icons.refresh, _refresh),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadMoreAthletes() async {
    final cursor = _athletesNextCursor;
    if (cursor == null || cursor.isEmpty || _loadingMoreAthletes) return;
    setState(() {
      _loadingMoreAthletes = true;
      _notice = '';
    });
    try {
      final response = _map(
        await Api.get(
          '/api/athletes?take=20&plans=1&progress=1&cursor=${Uri.encodeQueryComponent(cursor)}',
        ),
      );
      final current = List<dynamic>.from(
        _list(_snapshotData.length > 1 ? _snapshotData[1] : null),
      );
      final knownIds = current.map((item) => _text(_map(item)['id'])).toSet();
      for (final athlete in _list(response['data'])) {
        final id = _text(_map(athlete)['id']);
        if (id.isEmpty || knownIds.add(id)) current.add(athlete);
      }
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 2) {
        next.add(<dynamic>[]);
      }
      next[1] = current;
      _athletesNextCursor = response['nextCursor']?.toString();
      _athletesHasMore =
          response['hasMore'] == true ||
          (_athletesNextCursor?.isNotEmpty ?? false);
      if (!mounted) return;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice = 'Não foi possível carregar mais alunos: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMoreAthletes = false);
    }
  }

  Widget _studentCard(Map<String, dynamic> student) {
    final name = _text(student['name']).trim();
    final title = name.isEmpty ? 'Atleta' : name;
    final details = <String>[
      if (_text(student['objective']).trim().isNotEmpty)
        _text(student['objective']).trim(),
      if (_text(student['experienceLevel']).trim().isNotEmpty)
        _text(student['experienceLevel']).trim(),
      if (_text(student['phone']).trim().isNotEmpty)
        _text(student['phone']).trim(),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: _mRaised,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: CircleAvatar(
            backgroundColor: _mOrange.withValues(alpha: .14),
            foregroundColor: _mOrange,
            child: Text(title.substring(0, 1).toUpperCase()),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          subtitle: Text(
            details.isEmpty ? 'Aluno vinculado' : details.join(' \u2022 '),
            style: const TextStyle(color: _mMuted, fontSize: 11),
          ),
          onTap: () => _showStudentDetails(student),
          trailing: PopupMenuButton<String>(
            tooltip: 'A\u00e7\u00f5es de $title',
            enabled: !_busy,
            onSelected: (action) {
              switch (action) {
                case 'details':
                  _showStudentDetails(student);
                case 'edit':
                  _showStudentForm(student: student);
                case 'unlink':
                  _unlinkStudent(student);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'details', child: Text('Ver ficha')),
              const PopupMenuItem(value: 'edit', child: Text('Editar dados')),
              const PopupMenuItem(
                value: 'unlink',
                child: Text('Desvincular do Personal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _studentField(
    String keyName,
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey('student-$keyName'),
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator:
            validator ??
            (required
                ? (value) => value == null || value.trim().isEmpty
                      ? 'Preencha $label.'
                      : null
                : null),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Future<void> _showStudentOptions() async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Adicionar aluno'),
        content: const Text(
          'Cadastre um aluno ou vincule uma conta existente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'existing'),
            child: const Text('VINCULAR ALUNO EXISTENTE'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'new'),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('CADASTRAR NOVO'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'new') {
      await _showStudentForm();
    } else {
      await _showExistingStudentPicker();
    }
  }

  Future<void> _showExistingStudentPicker() async {
    if (Api.isDemoSession) {
      setState(() {
        _notice =
            'O v\u00ednculo de contas fica dispon\u00edvel ao entrar com uma conta personal real.';
      });
      return;
    }
    final search = TextEditingController();
    final available = Api.availableAthletes();
    String? athleteId;
    try {
      athleteId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: _mCard,
            title: const Text('Selecionar aluno'),
            content: SizedBox(
              width: _dialogWidth(dialogContext, 520),
              height: 420,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: available,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'N\u00e3o foi poss\u00edvel carregar os alunos: ${snapshot.error}',
                      ),
                    );
                  }
                  final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                  final query = search.text.trim().toLowerCase();
                  final filtered = rows.where((row) {
                    final searchable =
                        '${_text(row['name'])} ${_text(row['email'])}'
                            .toLowerCase();
                    return query.isEmpty || searchable.contains(query);
                  }).toList();
                  return Column(
                    children: [
                      TextField(
                        controller: search,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Buscar por nome ou e-mail',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  rows.isEmpty
                                      ? 'N\u00e3o h\u00e1 contas de aluno sem personal vinculado.'
                                      : 'Nenhum aluno corresponde \u00e0 busca.',
                                ),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final row = filtered[index];
                                  final name = _text(row['name']).trim();
                                  final location =
                                      [_text(row['city']), _text(row['state'])]
                                          .where((part) => part.isNotEmpty)
                                          .join(' ? ');
                                  final subtitle = [
                                    _text(row['email']),
                                    location,
                                  ].where((part) => part.isNotEmpty).join('\n');
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        (name.isEmpty ? 'A' : name[0])
                                            .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(name.isEmpty ? 'Aluno' : name),
                                    subtitle: subtitle.isEmpty
                                        ? null
                                        : Text(subtitle),
                                    isThreeLine: location.isNotEmpty,
                                    onTap: () => Navigator.pop(
                                      dialogContext,
                                      _text(row['id']),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCELAR'),
              ),
            ],
          ),
        ),
      );
    } finally {
      search.dispose();
    }
    if (athleteId == null || !mounted) return;
    if (athleteId.isEmpty) {
      _showInfo(
        'A conta selecionada n\u00e3o possui um identificador v\u00e1lido.',
      );
      return;
    }
    if (widget.module == 'Medidas') {
      _selectedMeasurementAthleteId = athleteId;
    }
    await _run(
      () => Api.linkAthlete(athleteId!),
      'Aluno vinculado ? sua lista.',
    );
  }

  Future<void> _showStudentForm({Map<String, dynamic>? student}) async {
    final editing = student != null;
    final studentId = _text(student?['id']);
    final formKey = GlobalKey<FormState>();
    final fields = <String, TextEditingController>{
      'name': TextEditingController(text: _text(student?['name'])),
      'email': TextEditingController(),
      'cpf': TextEditingController(),
      'height': TextEditingController(),
      'weight': TextEditingController(),
      'cep': TextEditingController(),
      'city': TextEditingController(),
      'state': TextEditingController(),
      'phone': TextEditingController(),
      'objective': TextEditingController(text: _text(student?['objective'])),
      'days': TextEditingController(text: _text(student?['availableDays'])),
      'observations': TextEditingController(
        text: _text(student?['observations']),
      ),
    };
    var sex = 'masculino';
    var experience = _text(student?['experienceLevel']);
    if (!['iniciante', 'intermediario', 'avancado'].contains(experience)) {
      experience = 'iniciante';
    }
    Map<String, dynamic>? values;

    try {
      values = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            backgroundColor: _mCard,
            title: Text(editing ? 'Editar dados do aluno' : 'Cadastrar aluno'),
            content: SizedBox(
              width: _dialogWidth(dialogContext, 520),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _studentField(
                        'name',
                        fields['name']!,
                        'Nome',
                        required: true,
                      ),
                      if (!editing) ...[
                        _studentField(
                          'email',
                          fields['email']!,
                          'E-mail',
                          required: true,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _studentField(
                          'cpf',
                          fields['cpf']!,
                          'CPF',
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('student-sex'),
                          initialValue: sex,
                          decoration: const InputDecoration(
                            labelText: 'Sexo',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'masculino',
                              child: Text('Masculino'),
                            ),
                            DropdownMenuItem(
                              value: 'feminino',
                              child: Text('Feminino'),
                            ),
                            DropdownMenuItem(
                              value: 'outro',
                              child: Text('Outro'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => sex = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _studentField(
                          'height',
                          fields['height']!,
                          'Altura em cm',
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                        _studentField(
                          'weight',
                          fields['weight']!,
                          'Peso em kg',
                          required: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('student-experience'),
                          initialValue: experience,
                          decoration: const InputDecoration(
                            labelText: 'N\u00edvel de experi\u00eancia',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'iniciante',
                              child: Text('Iniciante'),
                            ),
                            DropdownMenuItem(
                              value: 'intermediario',
                              child: Text('Intermedi\u00e1rio'),
                            ),
                            DropdownMenuItem(
                              value: 'avancado',
                              child: Text('Avan\u00e7ado'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => experience = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _studentField(
                          'cep',
                          fields['cep']!,
                          'CEP',
                          required: true,
                          keyboardType: TextInputType.number,
                        ),
                        _studentField(
                          'city',
                          fields['city']!,
                          'Cidade',
                          required: true,
                        ),
                        _studentField(
                          'state',
                          fields['state']!,
                          'UF',
                          required: true,
                        ),
                        _studentField(
                          'phone',
                          fields['phone']!,
                          'Telefone (opcional)',
                          keyboardType: TextInputType.phone,
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          key: const ValueKey('student-edit-experience'),
                          initialValue: experience,
                          decoration: const InputDecoration(
                            labelText: 'N\u00edvel de experi\u00eancia',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'iniciante',
                              child: Text('Iniciante'),
                            ),
                            DropdownMenuItem(
                              value: 'intermediario',
                              child: Text('Intermedi\u00e1rio'),
                            ),
                            DropdownMenuItem(
                              value: 'avancado',
                              child: Text('Avan\u00e7ado'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => experience = value);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        _studentField(
                          'objective',
                          fields['objective']!,
                          'Objetivo',
                        ),
                        _studentField(
                          'days',
                          fields['days']!,
                          'Dias dispon\u00edveis',
                        ),
                        _studentField(
                          'observations',
                          fields['observations']!,
                          'Observa\u00e7\u00f5es',
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCELAR'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  final body = <String, dynamic>{
                    'name': fields['name']!.text.trim(),
                    if (editing) ...{
                      'experienceLevel': experience,
                      'objective': fields['objective']!.text.trim(),
                      'availableDays': fields['days']!.text.trim(),
                      'observations': fields['observations']!.text.trim(),
                    } else ...{
                      'email': fields['email']!.text.trim(),
                      'cpf': fields['cpf']!.text.trim(),
                      'sex': sex,
                      'heightCm':
                          int.tryParse(fields['height']!.text.trim()) ?? 0,
                      'weightKg':
                          double.tryParse(
                            fields['weight']!.text.trim().replaceAll(',', '.'),
                          ) ??
                          0,
                      'experienceLevel': experience,
                      'cep': fields['cep']!.text.trim(),
                      'city': fields['city']!.text.trim(),
                      'state': fields['state']!.text.trim().toUpperCase(),
                      'phone': fields['phone']!.text.trim(),
                    },
                  };
                  Navigator.pop(dialogContext, body);
                },
                child: Text(
                  editing ? 'SALVAR ALTERA\u00c7\u00d5ES' : 'CRIAR ALUNO',
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      // The dialog route keeps its form widgets alive during the reverse animation.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      for (final controller in fields.values) {
        controller.dispose();
      }
    }

    if (values == null || !mounted) return;
    if (Api.isDemoSession) {
      _setPreviewStudent(values, id: editing ? studentId : null);
      return;
    }
    await _run(
      () => editing
          ? Api.patch(
              '/api/athletes/${Uri.encodeComponent(studentId)}',
              values!,
            )
          : Api.post('/api/athletes/register', values!),
      editing ? 'Dados do aluno atualizados.' : 'Aluno cadastrado com sucesso.',
    );
  }

  void _setPreviewStudent(Map<String, dynamic> values, {String? id}) {
    final next = List<dynamic>.from(_snapshotData);
    while (next.length < 2) {
      next.add(<dynamic>[]);
    }
    final students = List<dynamic>.from(_list(next[1]));
    final index = students.indexWhere(
      (row) => _text(_map(row)['id']) == (id ?? ''),
    );
    if (index >= 0) {
      students[index] = <String, dynamic>{..._map(students[index]), ...values};
    } else {
      students.add({
        'id': 'preview-athlete-${DateTime.now().microsecondsSinceEpoch}',
        ...values,
      });
    }
    next[1] = students;
    setState(() {
      _snapshotData = next;
      _data = Future.value(next);
      _notice =
          'Pr\u00e9via: altera\u00e7\u00e3o aplicada localmente; n\u00e3o enviada ao servidor.';
    });
  }

  Future<void> _showStudentDetails(Map<String, dynamic> student) async {
    var details = student;
    final id = _text(student['id']);
    if (!Api.isDemoSession && id.isNotEmpty) {
      try {
        details = _map(
          await Api.get('/api/athletes/${Uri.encodeComponent(id)}'),
        );
      } catch (error) {
        if (mounted) setState(() => _notice = error.toString());
      }
    }
    if (!mounted) return;

    final fields = <(String, String)>[
      ('Nome', _text(details['name'])),
      ('E-mail', _text(details['email'])),
      ('Objetivo', _text(details['objective'])),
      ('N\u00edvel', _text(details['experienceLevel'])),
      ('Telefone', _text(details['phone'])),
      (
        'Altura',
        details['heightCm'] == null ? '' : '${details['heightCm']} cm',
      ),
      ('Peso', details['weightKg'] == null ? '' : '${details['weightKg']} kg'),
      ('Dias dispon\u00edveis', _text(details['availableDays'])),
      ('Observa\u00e7\u00f5es', _text(details['observations'])),
    ].where((field) => field.$2.trim().isNotEmpty).toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: Text(
          _text(details['name']).isEmpty
              ? 'Ficha do atleta'
              : _text(details['name']),
        ),
        content: SizedBox(
          width: _dialogWidth(dialogContext, 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields
                  .map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.$1.toUpperCase(),
                            style: const TextStyle(
                              color: _mMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(field.$2),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          if (_currentRole == 'personal')
            TextButton.icon(
              key: const ValueKey('personal-copilot-student'),
              onPressed: () {
                final navigator = Navigator.of(dialogContext);
                navigator.pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !navigator.mounted) return;
                  showPersonalCopilot(navigator.context, student: details);
                });
              },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('COPILOT DESTE ALUNO'),
            ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showStudentProgress(student);
            },
            icon: const Icon(Icons.monitor_weight_outlined),
            label: const Text('VER EVOLU\u00c7\u00c3O'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStudentProgress(Map<String, dynamic> student) async {
    final athleteId = _text(student['id']);
    if (athleteId.isEmpty) return;

    List<Map<String, dynamic>> entries;
    if (Api.isDemoSession) {
      entries = _list(student['progressEntries']).map(_map).toList();
    } else {
      try {
        final response = await Api.get('/api/progress?athleteId=$athleteId');
        final payload = _map(response);
        entries = _list(
          payload['data'] ?? payload['progress'] ?? response,
        ).map(_map).toList();
      } catch (_) {
        if (mounted) {
          _showInfo(
            'N\u00e3o foi poss\u00edvel carregar a evolu\u00e7\u00e3o.',
          );
        }
        return;
      }
    }
    if (!mounted) return;

    final studentName = _text(student['name']);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: Text('Evolu\u00e7\u00e3o f\u00edsica - $studentName'),
        content: SizedBox(
          width: _dialogWidth(dialogContext, 480),
          child: SingleChildScrollView(
            child: entries.isEmpty
                ? const Text(
                    'Ainda n\u00e3o h\u00e1 avalia\u00e7\u00f5es registradas.',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: entries.map((entry) {
                      final weight = _text(entry['weight']);
                      final date = _text(entry['date']);
                      final muscleMass = _text(entry['muscleMass']);
                      final bodyFat = _text(entry['bodyFat']);
                      final measurements = <String>[
                        if (muscleMass.isNotEmpty)
                          'Massa magra: $muscleMass kg',
                        if (bodyFat.isNotEmpty) 'Gordura: $bodyFat%',
                        if (_text(entry['note']).isNotEmpty)
                          _text(entry['note']),
                      ];
                      return _rowCard(
                        weight.isEmpty ? 'Avalia\u00e7\u00e3o' : '$weight kg',
                        <String>[
                          date,
                          ...measurements,
                        ].where((value) => value.isNotEmpty).join(' \u2022 '),
                        Icons.monitor_weight_outlined,
                      );
                    }).toList(),
                  ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('FECHAR'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              _recordStudentProgress(student);
            },
            icon: const Icon(Icons.add),
            label: const Text('REGISTRAR AVALIA\u00c7\u00c3O'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordStudentProgress(Map<String, dynamic> student) async {
    final fields = <String, TextEditingController>{
      'weight': TextEditingController(),
      'muscleMass': TextEditingController(),
      'bodyFat': TextEditingController(),
      'note': TextEditingController(),
    };
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic>? values;
    try {
      values = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Nova avalia\u00e7\u00e3o'),
          content: SizedBox(
            width: _dialogWidth(dialogContext, 420),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _studentField(
                    'progress-weight',
                    fields['weight']!,
                    'Peso em kg',
                    required: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      return parsed == null || parsed <= 0
                          ? 'Informe um peso v\u00e1lido.'
                          : null;
                    },
                  ),
                  _studentField(
                    'progress-muscle',
                    fields['muscleMass']!,
                    'Massa magra em kg (opcional)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      return parsed == null || parsed < 0
                          ? 'Informe um valor v\u00e1lido.'
                          : null;
                    },
                  ),
                  _studentField(
                    'progress-body-fat',
                    fields['bodyFat']!,
                    'Gordura corporal em % (opcional)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final parsed = double.tryParse(
                        value.trim().replaceAll(',', '.'),
                      );
                      return parsed == null || parsed < 0 || parsed > 100
                          ? 'Use um percentual entre 0 e 100.'
                          : null;
                    },
                  ),
                  _studentField(
                    'progress-note',
                    fields['note']!,
                    'Observa\u00e7\u00f5es',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                final muscleText = fields['muscleMass']!.text.trim();
                final bodyFatText = fields['bodyFat']!.text.trim();
                Navigator.pop(dialogContext, <String, dynamic>{
                  'athleteId': _text(student['id']),
                  'date': DateTime.now().toIso8601String(),
                  'weight': double.parse(
                    fields['weight']!.text.trim().replaceAll(',', '.'),
                  ),
                  if (muscleText.isNotEmpty)
                    'muscleMass': double.tryParse(
                      muscleText.replaceAll(',', '.'),
                    ),
                  if (bodyFatText.isNotEmpty)
                    'bodyFat': double.tryParse(
                      bodyFatText.replaceAll(',', '.'),
                    ),
                  if (fields['note']!.text.trim().isNotEmpty)
                    'note': fields['note']!.text.trim(),
                });
              },
              child: const Text('SALVAR AVALIA\u00c7\u00c3O'),
            ),
          ],
        ),
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      for (final controller in fields.values) {
        controller.dispose();
      }
    }
    if (values == null || !mounted) return;

    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 2) {
        next.add(<dynamic>[]);
      }
      final rows = List<dynamic>.from(_list(next[1]));
      final athleteId = _text(student['id']);
      final index = rows.indexWhere(
        (row) => _text(_map(row)['id']) == athleteId,
      );
      if (index < 0) return;
      final updated = <String, dynamic>{..._map(rows[index])};
      final progress = List<dynamic>.from(_list(updated['progressEntries']));
      final progressId = DateTime.now().microsecondsSinceEpoch;
      progress.insert(0, {'id': 'preview-progress-$progressId', ...values});
      updated['progressEntries'] = progress;
      rows[index] = updated;
      next[1] = rows;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice =
            'Pr\u00e9via: avalia\u00e7\u00e3o registrada somente nesta demonstra\u00e7\u00e3o.';
      });
      await _showStudentProgress(updated);
      return;
    }

    await _run(
      () => Api.post('/api/progress', values!),
      'Evolu\u00e7\u00e3o registrada.',
    );
    await _showStudentProgress(student);
  }

  String athleteIdFor(Map<String, dynamic> student) => _text(student['id']);

  Future<void> _unlinkStudent(Map<String, dynamic> student) async {
    final id = _text(student['id']);
    if (id.isEmpty) {
      _showInfo('Este aluno n\u00e3o possui um identificador v\u00e1lido.');
      return;
    }
    final name = _text(student['name']).trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Desvincular aluno?'),
        content: Text(
          'A conta${name.isEmpty ? '' : ' de $name'} e o hist\u00f3rico de treinos ser\u00e3o preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('DESVINCULAR'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 2) {
        next.add(<dynamic>[]);
      }
      final students = List<dynamic>.from(_list(next[1]))
        ..removeWhere((row) => _text(_map(row)['id']) == id);
      next[1] = students;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice =
            'Pr\u00e9via: aluno desvinculado somente desta demonstra\u00e7\u00e3o.';
      });
      return;
    }

    await _run(
      () => Api.delete('/api/athletes/${Uri.encodeComponent(id)}', {}),
      'Aluno desvinculado. A conta e o hist\u00f3rico foram preservados.',
    );
  }

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
      _achievementCatalog(d.length > 2 ? d[2] : null),
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
            final displayMetric =
                metric.toLowerCase().startsWith('sess') ||
                    metric.toLowerCase().contains('session')
                ? 'sess\u00f5es'
                : metric;
            String formatValue(double value) => value == value.roundToDouble()
                ? value.round().toString()
                : value.toString().replaceAll('.', ',');
            // Os campos numéricos são a fonte atual do progresso. O texto
            // legado `progresso` pode ficar desatualizado após uma edição.
            final progressText = target > 0
                ? '${formatValue(current)} de ${formatValue(target)} $displayMetric'
                : 'Defina um valor-alvo';
            final statusLabel = completed ? 'Conclu\u00edda' : 'Em andamento';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _mRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          completed ? Icons.check_circle : Icons.flag_outlined,
                          color: completed ? Colors.green : _mOrange,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _text(goal['title'] ?? 'Meta'),
                          style: const TextStyle(
                            color: _mText,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (completed ? Colors.green : _mOrange)
                              .withValues(alpha: .13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: completed ? Colors.green : _mOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          progressText,
                          style: const TextStyle(
                            color: _mMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: _mText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: _mCard,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completed ? Colors.green : _mOrange,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
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
                          onPressed: _busy
                              ? null
                              : () => _updateGoalProgress(goal),
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
    if (Api.isDemoSession) {
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
    if (Api.isDemoSession) {
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
    if (Api.isDemoSession) {
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
        if (changes.containsKey('currentValue')) {
          goals[index].remove('progresso');
        }
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
                final rawDuration = _text(p['durationWeeks'] ?? p['duration']);
                final durationLabel =
                    rawDuration.toLowerCase().contains('semana')
                    ? rawDuration
                    : '$rawDuration semanas';
                final subtitle =
                    '${_text(p['category'])} \u2022 ${_text(p['level'])} \u2022 $durationLabel';
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
    final id = _text(program['id']);
    if (id.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProgramDetailPage(programId: id, initialProgram: program),
      ),
    );
  }

  Future<void> _openChat(String userId, String name) async {
    if (Api.isDemoSession) {
      setState(() {
        _activeChatUserId = userId;
        _activeChatName = name;
        _activeChatMessages = [
          {
            'id': 'preview-history-$userId',
            'senderId': userId,
            'receiverId': _currentUserId.isEmpty
                ? 'preview-current-user'
                : _currentUserId,
            'text': 'Olá! Esta é uma conversa de demonstração.',
          },
        ];
        _notice = 'Conversa aberta na prévia.';
      });
      _scrollChatToLatest();
      _revealChatComposer();
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
      if (mounted) {
        setState(() => _activeChatMessages = _list(result));
        _scrollChatToLatest();
        _revealChatComposer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notice = 'Não foi possível abrir a conversa: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _scrollChatToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _revealChatComposer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _chatComposerKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String? _messageTime(dynamic value) {
    final timestamp = DateTime.tryParse(_text(value));
    if (timestamp == null) return null;
    final local = timestamp.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<void> _sendChatMessage() async {
    final receiverId = _activeChatUserId;
    final text = _message.text.trim();
    if (receiverId == null || receiverId.isEmpty || text.isEmpty || _busy) {
      return;
    }
    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_activeChatMessages)
        ..add({
          'id': 'preview-message-${DateTime.now().microsecondsSinceEpoch}',
          'senderId': _currentUserId.isEmpty
              ? 'preview-current-user'
              : _currentUserId,
          'receiverId': receiverId,
          'text': text,
        });
      setState(() {
        _activeChatMessages = next;
        _message.clear();
        _notice = 'Mensagem adicionada nesta prévia.';
      });
      _scrollChatToLatest();
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
        _scrollChatToLatest();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _notice = 'Não foi possível enviar a mensagem: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _chatInbox(
    dynamic raw, [
    dynamic linkedAthletesRaw,
    dynamic friendsRaw,
    Map<String, dynamic>? personalContact,
  ]) {
    final root = _map(raw);
    final rawConversations = root['conversations'];
    final source = rawConversations is List
        ? <String, dynamic>{'sent': rawConversations, 'received': <dynamic>[]}
        : _map(rawConversations);
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
    for (final rawAthlete in _list(linkedAthletesRaw)) {
      final athlete = _map(rawAthlete);
      final userId = _text(athlete['userId']);
      final name = _text(athlete['name']).trim();
      if (userId.isEmpty) continue;
      contacts[userId] = {
        'id': userId,
        'displayName': name.isEmpty ? 'Aluno' : name,
        'contactType': 'athlete',
      };
    }
    for (final rawFriend in _list(friendsRaw)) {
      final friend = _map(rawFriend);
      final id = _text(friend['id']);
      if (id.isEmpty) continue;
      contacts[id] = {
        ...friend,
        'displayName': _text(friend['displayName']).isNotEmpty
            ? friend['displayName']
            : 'Amigo WeGYM',
        'contactType': 'friend',
      };
    }
    if (_currentRole != 'personal' && personalContact != null) {
      final id = _text(personalContact['id'] ?? personalContact['userId']);
      if (id.isNotEmpty) {
        contacts[id] = {
          ...personalContact,
          'displayName': _text(personalContact['name']).isNotEmpty
              ? personalContact['name']
              : 'Meu personal',
          'contactType': 'personal',
        };
      }
    }
    return Column(
      children: [
        _section(
          _currentRole == 'personal' ? 'CONVERSAS E ALUNOS' : 'CONVERSAS',
          Icons.forum,
          contacts.isEmpty
              ? _empty('Nenhuma conversa disponível.')
              : Column(
                  children: contacts.entries.map((entry) {
                    final name = _text(entry.value['displayName']).isEmpty
                        ? (_currentRole == 'personal' ? 'Aluno' : 'Atleta')
                        : _text(entry.value['displayName']);
                    return _rowCard(
                      name,
                      'Toque para abrir o histórico de mensagens.',
                      entry.value['contactType'] == 'athlete'
                          ? Icons.school
                          : Icons.person,
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
                SizedBox(
                  height: (MediaQuery.sizeOf(context).height * .45)
                      .clamp(220.0, 520.0)
                      .toDouble(),
                  child: _activeChatMessages.isEmpty
                      ? Center(
                          child: _empty(
                            'Ainda não há mensagens nesta conversa.',
                          ),
                        )
                      : ListView.builder(
                          controller: _chatScroll,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _activeChatMessages.length,
                          itemBuilder: (context, index) {
                            final message = _map(_activeChatMessages[index]);
                            final mine = _currentUserId.isNotEmpty
                                ? _text(message['senderId']) == _currentUserId
                                : Api.isDemoSession &&
                                      _text(message['senderId']) ==
                                          'preview-current-user';
                            final time = _messageTime(message['createdAt']);
                            return Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints(
                                  maxWidth: 560,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? _mOrange.withValues(alpha: .18)
                                      : _mRaised,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: mine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(_text(message['text'])),
                                    if (time != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: _mMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                Row(
                  key: _chatComposerKey,
                  children: [
                    Expanded(
                      child: _input(
                        _message,
                        'Escreva uma mensagem',
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
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

  Widget _providerIntegrationCard(String provider, List<dynamic> integrations) {
    final isGoogleFit = provider == 'google_fit';
    final title = isGoogleFit ? 'Google Fit' : 'Strava';
    final record = integrations.map(_map).where((item) {
      final key = _text(item['provider']).toLowerCase();
      final name = _text(item['name']).toLowerCase();
      return key == provider ||
          (isGoogleFit && name.contains('google fit')) ||
          (!isGoogleFit && name.contains('strava'));
    }).firstOrNull;
    final rawStatus = _text(record?['status']);
    final isPending = rawStatus.toLowerCase().contains('oauth');
    final connected = record != null && !isPending;
    final enabled = record?['enabled'] != false;
    final status = connected
        ? enabled
              ? 'Conectado e pronto para sincronizar'
              : 'Conectado; sincroniza\u00e7\u00e3o pausada'
        : rawStatus.isNotEmpty
        ? rawStatus
        : 'N\u00e3o conectado';
    final lastSyncDate = DateTime.tryParse(
      _text(record?['lastSyncAt']),
    )?.toLocal();
    final statusDetail = connected && lastSyncDate != null
        ? '$status \u2022 \u00faltima sincroniza\u00e7\u00e3o ${lastSyncDate.day.toString().padLeft(2, '0')}/${lastSyncDate.month.toString().padLeft(2, '0')}/${lastSyncDate.year}'
        : status;
    final statusColor = connected ? stitchGreen : _mMuted;
    final action = connected
        ? OutlinedButton.icon(
            key: ValueKey('disconnect-$provider'),
            onPressed: _busy
                ? null
                : () => _run(
                    () =>
                        Api.delete('/api/integrations', {'provider': provider}),
                    'Integra\u00e7\u00e3o desconectada.',
                  ),
            icon: const Icon(Icons.link_off, size: 14),
            label: Text('DESCONECTAR ${title.toUpperCase()}'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _mOrange,
              side: BorderSide(color: _mOrange.withValues(alpha: .55)),
              textStyle: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            ),
          )
        : FilledButton.icon(
            key: ValueKey('connect-$provider'),
            onPressed: _busy ? null : () => _connectIntegration(provider),
            icon: const Icon(Icons.link, size: 14),
            label: Text('CONECTAR ${title.toUpperCase()}'),
            style: FilledButton.styleFrom(
              backgroundColor: _mOrange,
              foregroundColor: stitchOnPrimaryContainer,
              textStyle: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            ),
          );

    return Container(
      key: ValueKey('integration-$provider'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mRaised,
        borderRadius: BorderRadius.circular(11),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final providerInfo = Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isGoogleFit
                      ? Icons.monitor_heart_outlined
                      : Icons.directions_run,
                  color: statusColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _mText,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            statusDetail,
                            style: TextStyle(color: _mMuted, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          return constraints.maxWidth < 470
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    providerInfo,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: providerInfo),
                    const SizedBox(width: 12),
                    action,
                  ],
                );
        },
      ),
    );
  }

  Widget _profile(dynamic raw) {
    final p = _map(raw),
        athlete = _map(p['athlete']),
        integrations = _dataOrEmpty(1),
        personal = _map(p['personal']);
    final isPersonal = p['role'] == 'personal';
    final name = _text(p['name'] ?? athlete['name'] ?? personal['name']);
    final subscriptionResponse = _snapshotData.length > 2
        ? _map(_snapshotData[2])
        : <String, dynamic>{};
    final subscription = _map(subscriptionResponse['data']);
    final hasActivePlan = subscription['status'] == 'active';
    final weight = _n(athlete['weightKg']);
    final height = _n(athlete['heightCm']);
    final bmi = weight > 0 && height > 0
        ? weight / ((height / 100) * (height / 100))
        : null;
    final city = _text(athlete['city']);
    final state = _text(athlete['state']);
    final location = [
      city,
      state,
    ].where((value) => value.isNotEmpty).join(', ');
    final experience = _text(athlete['experienceLevel']);
    final identityDetail = isPersonal
        ? (_text(personal['cref']).isEmpty ? '' : 'CREF ${personal['cref']}')
        : [location, experience].where((value) => value.isNotEmpty).join(' · ');
    final createdAt = DateTime.tryParse(_text(p['createdAt']))?.toLocal();
    final memberSince = createdAt == null
        ? ''
        : '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';

    return Column(
      children: [
        _profileIdentityCard(
          name: name,
          email: _text(p['email']),
          role: isPersonal ? 'Personal Trainer' : 'Atleta',
          detail: identityDetail,
          memberSince: memberSince,
          imageUrl: _text(p['avatarUrl']).isNotEmpty
              ? _text(p['avatarUrl'])
              : _text(p['avatarPlaceholder']),
          onEditName: _editProfile,
          onChangePhoto: () => _changeProfilePhoto(p),
        ),
        const SizedBox(height: 12),
        _section(
          isPersonal ? 'CREDENCIAL PROFISSIONAL' : 'DADOS BIOMÉTRICOS',
          isPersonal ? Icons.badge_outlined : Icons.monitor_weight_outlined,
          isPersonal
              ? _rowCard('CREF', _text(personal['cref']), Icons.badge_outlined)
              : Column(
                  children: [
                    _rowCard(
                      'PESO ATUAL',
                      weight > 0
                          ? '${weight.toStringAsFixed(1)} kg'
                          : 'Não informado',
                      Icons.monitor_weight_outlined,
                      tail: IconButton(
                        tooltip: 'Editar peso',
                        onPressed: () => _editProfileMetric(
                          field: 'weightKg',
                          value: weight > 0 ? weight.toString() : '',
                          title: 'Editar peso',
                          hint: 'Peso em kg',
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    _rowCard(
                      'ALTURA',
                      height > 0 ? '${height.round()} cm' : 'Não informada',
                      Icons.height,
                      tail: IconButton(
                        tooltip: 'Editar altura',
                        onPressed: () => _editProfileMetric(
                          field: 'heightCm',
                          value: height > 0 ? height.round().toString() : '',
                          title: 'Editar altura',
                          hint: 'Altura em cm',
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                    _rowCard(
                      'IMC',
                      bmi == null
                          ? 'Preencha peso e altura para calcular'
                          : '${bmi.toStringAsFixed(1)} · ${_bmiCategory(bmi)}',
                      Icons.favorite_outline,
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        if (_workoutReminders.isSupported) ...[
          _workoutReminderCard(),
          const SizedBox(height: 12),
        ],
        _section(
          'PLANO WEGYM',
          Icons.workspace_premium,
          _rowCard(
            'Plano atual',
            hasActivePlan
                ? _text(subscription['plan'] ?? 'WeGYM PRO')
                : 'Plano gratuito',
            Icons.workspace_premium,
            tail: _button(
              hasActivePlan ? 'VER ASSINATURA' : 'CONHECER PLANOS',
              Icons.arrow_forward,
              () => widget.onNavigate?.call(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _section(
          'INTEGRA\u00c7\u00d5ES',
          Icons.bluetooth,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (HealthPlatformIntegration.isSupportedPlatform) ...[
                _nativeHealthIntegrationCard(),
                const SizedBox(height: 4),
              ],
              for (final provider in const ['google_fit', 'strava'])
                _providerIntegrationCard(provider, _list(integrations)),
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
                _exportProfileData,
              ),
              const LegalDocumentLink(
                buttonKey: ValueKey('legal-link-terms-profile'),
                kind: LegalDocumentKind.terms,
                label: 'LER TERMOS DE USO',
                compact: true,
              ),
              const LegalDocumentLink(
                buttonKey: ValueKey('legal-link-privacy-profile'),
                kind: LegalDocumentKind.privacy,
                label: 'LER POL\u00cdTICA DE PRIVACIDADE',
                compact: true,
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
        const SizedBox(height: 12),
        _profileResources(),
        if (kIsWeb) ...[const SizedBox(height: 12), const PwaInstallCard()],
      ],
    );
  }

  Widget _profileIdentityCard({
    required String name,
    required String email,
    required String role,
    required String detail,
    required String memberSince,
    required String imageUrl,
    required VoidCallback onEditName,
    required VoidCallback onChangePhoto,
  }) => _section(
    'IDENTIDADE',
    Icons.person_outline,
    LayoutBuilder(
      builder: (context, constraints) {
        final avatar = Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileAvatar(name: name, imageUrl: imageUrl, radius: 42),
            Positioned(
              right: -5,
              bottom: -5,
              child: Material(
                color: _mOrange,
                shape: const CircleBorder(),
                child: IconButton(
                  key: const ValueKey('profile-avatar-change-info'),
                  tooltip: 'Alterar foto de perfil',
                  onPressed: onChangePhoto,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.camera_alt_outlined, size: 15),
                ),
              ),
            ),
          ],
        );
        final info = Column(
          crossAxisAlignment: constraints.maxWidth < 480
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: constraints.maxWidth < 480
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    name.isEmpty ? 'Perfil WeGYM' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('profile-identity-edit-name'),
                  tooltip: 'Editar nome',
                  onPressed: onEditName,
                  icon: const Icon(Icons.edit_outlined, size: 17),
                ),
              ],
            ),
            if (email.isNotEmpty)
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _mMuted, fontSize: 11),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              alignment: constraints.maxWidth < 480
                  ? WrapAlignment.center
                  : WrapAlignment.start,
              children: [
                _identityTag(role, _mOrange),
                if (detail.isNotEmpty) _identityTag(detail, _mRaised),
                if (memberSince.isNotEmpty)
                  _identityTag('Membro desde $memberSince', _mRaised),
              ],
            ),
          ],
        );
        if (constraints.maxWidth < 480) {
          return Column(children: [avatar, const SizedBox(height: 12), info]);
        }
        return Row(
          children: [
            avatar,
            const SizedBox(width: 18),
            Expanded(child: info),
          ],
        );
      },
    ),
  );

  Widget _identityTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _mText,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _profileResources() {
    const resources =
        <({String label, String description, IconData icon, int page})>[
          (
            label: 'METAS',
            description: 'Objetivos pessoais',
            icon: Icons.flag_outlined,
            page: 8,
          ),
          (
            label: 'CHECK-IN',
            description: 'Registro di\u00e1rio',
            icon: Icons.fact_check_outlined,
            page: 14,
          ),
          (
            label: 'FEED',
            description: 'Publica\u00e7\u00f5es da comunidade',
            icon: Icons.dynamic_feed_outlined,
            page: 3,
          ),
          (
            label: 'CHAT',
            description: 'Converse com seu coach',
            icon: Icons.chat_bubble_outline,
            page: 10,
          ),
          (
            label: 'PROGRAMAS',
            description: 'Treinos organizados',
            icon: Icons.menu_book_outlined,
            page: 9,
          ),
          (
            label: 'NUTRI\u00c7\u00c3O',
            description: 'Refei\u00e7\u00f5es e macros',
            icon: Icons.restaurant_outlined,
            page: 6,
          ),
          (
            label: 'CONQUISTAS',
            description: 'Medalhas e recordes',
            icon: Icons.emoji_events_outlined,
            page: 20,
          ),
          (
            label: 'DESAFIOS',
            description: 'Participe da comunidade',
            icon: Icons.sports_martial_arts_outlined,
            page: 8,
          ),
          (
            label: 'AGENDA',
            description: 'Hor\u00e1rios e sess\u00f5es',
            icon: Icons.calendar_month_outlined,
            page: 5,
          ),
          (
            label: 'EVOLU\u00c7\u00c3O',
            description: 'Medidas e progresso',
            icon: Icons.show_chart,
            page: 13,
          ),
        ];
    return _section(
      'TODOS OS RECURSOS',
      Icons.grid_view_rounded,
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 3 : 2;
          return GridView.builder(
            key: const ValueKey('profile-resources-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resources.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: columns == 2 ? 2.25 : 2.6,
            ),
            itemBuilder: (context, index) {
              final resource = resources[index];
              return Material(
                color: _mRaised,
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  key: ValueKey('profile-resource-${resource.page}-$index'),
                  borderRadius: BorderRadius.circular(11),
                  onTap: widget.onNavigate == null
                      ? null
                      : () => widget.onNavigate!(resource.page),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Icon(resource.icon, color: _mOrange, size: 20),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _mText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                resource.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _mMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: _mMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
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
        'ASSINE O WEGYM PRO',
        Icons.workspace_premium,
        Column(
          children: [
            _rowCard(
              'WEGYM PRO MENSAL',
              'R\$ 49,90 • cobrança mensal • Checkout Pro do Mercado Pago',
              Icons.calendar_month,
              tail: _button(
                'ASSINAR',
                Icons.arrow_forward,
                () => _openPaymentCheckout('mensal'),
              ),
            ),
            _rowCard(
              'WEGYM PRO ANUAL',
              'R\$ 399,90 • cobrança anual • Checkout Pro do Mercado Pago',
              Icons.workspace_premium,
              tail: _button(
                'ASSINAR',
                Icons.arrow_forward,
                () => _openPaymentCheckout('anual'),
              ),
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

  Future<void> _openPaymentCheckout(String planId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentCheckoutPage(planId: planId),
      ),
    );
  }

  Widget _measurements(List<dynamic> d) => Column(
    children: [
      if (_currentRole == 'personal') ...[
        _section(
          'SELECIONE O ALUNO',
          Icons.person_search,
          _measurementAthletes.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _empty('Nenhum aluno vinculado a este personal.'),
                    const SizedBox(height: 10),
                    _button(
                      'VINCULAR OU CADASTRAR ALUNO',
                      Icons.person_add_alt_1,
                      _showStudentOptions,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.onNavigate == null
                          ? null
                          : () => widget.onNavigate!(7),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('ABRIR ALUNOS & PERSONAL'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedMeasurementAthleteId,
                      decoration: const InputDecoration(
                        labelText: 'Aluno avaliado',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: _measurementAthletes.map((athlete) {
                        final id = _text(athlete['id']);
                        final name = _text(athlete['name']).trim();
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name.isEmpty ? 'Atleta' : name),
                        );
                      }).toList(),
                      onChanged: (id) {
                        if (id == null || id == _selectedMeasurementAthleteId) {
                          return;
                        }
                        setState(() {
                          _selectedMeasurementAthleteId = id;
                          _data = _load();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _showStudentOptions,
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('VINCULAR OUTRO ALUNO'),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
      ],
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

  Widget _friends(List<dynamic> d) {
    final response = _map(d.isNotEmpty ? d[0] : null);
    final friends = _list(response['friends'])
        .map(
          (row) => {
            ..._map(row),
            'name': _text(_map(row)['displayName']).isEmpty
                ? 'Usuário WeGYM'
                : _text(_map(row)['displayName']),
          },
        )
        .toList();
    final incoming = _list(response['incomingRequests']);
    final outgoing = _list(response['outgoingRequests'])
        .map(
          (row) => {
            ..._map(row),
            'name': _text(_map(row)['displayName']).isEmpty
                ? 'Usuário WeGYM'
                : _text(_map(row)['displayName']),
          },
        )
        .toList();
    return Column(
      children: [
        _section(
          'SUA REDE',
          Icons.people,
          _genericList(friends, empty: 'Ainda não há conexões para mostrar.'),
        ),
        const SizedBox(height: 12),
        _section(
          'SOLICITAÇÕES RECEBIDAS',
          Icons.person_add_alt,
          incoming.isEmpty
              ? _empty('Nenhuma solicitação pendente.')
              : Column(
                  children: incoming.map((raw) {
                    final request = _map(raw);
                    final name = _text(request['displayName']).isEmpty
                        ? 'Usuário WeGYM'
                        : _text(request['displayName']);
                    final id = _text(request['friendshipId'] ?? request['id']);
                    return _rowCard(
                      name,
                      'Quer se conectar com você',
                      Icons.person_add_alt,
                      tail: Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Aceitar solicitação de $name',
                            onPressed: _busy
                                ? null
                                : () => _respondFriend(id, true),
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Recusar solicitação de $name',
                            onPressed: _busy
                                ? null
                                : () => _respondFriend(id, false),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: _mOrange,
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
          'SOLICITAÇÕES ENVIADAS',
          Icons.outgoing_mail,
          _genericList(
            outgoing,
            empty: 'Você ainda não enviou solicitações pendentes.',
          ),
        ),
      ],
    );
  }

  Widget _classes(List<dynamic> data) {
    final classes = _list(data.isNotEmpty ? data[0] : null);
    final students = _list(data.length > 1 ? data[1] : null);
    return _section(
      'AULAS AGENDADAS',
      Icons.calendar_month,
      Column(
        children: [
          if (_currentRole == 'personal' && students.isEmpty)
            _empty('Vincule alunos para registrar aulas.'),
          if (classes.isEmpty)
            _empty('Nenhuma aula foi encontrada para esta conta.')
          else
            ...classes.map((rawClass) {
              final item = _map(rawClass);
              final athlete = _map(item['athlete']);
              final athleteId = _text(athlete['id'] ?? item['athleteId']);
              final linkedStudent = students
                  .map(_map)
                  .where((student) => _text(student['id']) == athleteId)
                  .firstOrNull;
              final athleteName = _text(
                athlete['name'] ??
                    _map(linkedStudent)['name'] ??
                    item['athleteName'],
              );
              final date = DateTime.tryParse(_text(item['date']));
              final dateText = date == null
                  ? _text(item['date'])
                  : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
              final statusLabel = switch (_text(item['status'])) {
                'confirmed' => 'Confirmada',
                'scheduled' => 'Agendada',
                'pending' => 'Pendente',
                'canceled' => 'Cancelada',
                _ => _text(item['status']),
              };
              final details = [
                if (athleteName.isNotEmpty) athleteName,
                if (dateText.isNotEmpty) dateText,
                if (_text(item['time']).isNotEmpty) _text(item['time']),
                statusLabel,
              ].where((value) => value.isNotEmpty).join(' • ');
              return _rowCard(
                _text(item['type']).isEmpty ? 'Aula' : _text(item['type']),
                details,
                Icons.event_available,
              );
            }),
        ],
      ),
    );
  }

  Future<void> _createClass(List<dynamic> data) async {
    if (_currentRole != 'personal') {
      _showInfo('Somente contas Personal podem registrar aulas.');
      return;
    }
    final students = _list(data.length > 1 ? data[1] : null)
        .map((item) => _map(item))
        .where((student) => _text(student['id']).isNotEmpty)
        .toList();
    if (students.isEmpty) {
      _showInfo('Vincule um aluno antes de registrar uma aula.');
      return;
    }

    final typeController = TextEditingController(text: 'Treino acompanhado');
    var selectedAthleteId = _text(students.first['id']);
    var selectedDate = DateUtils.dateOnly(DateTime.now());
    var selectedTime = const TimeOfDay(hour: 18, minute: 0);
    final classDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Registrar aula'),
          content: SizedBox(
            width: _dialogWidth(dialogContext, 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedAthleteId,
                    decoration: const InputDecoration(
                      labelText: 'Aluno',
                      border: OutlineInputBorder(),
                    ),
                    items: students
                        .map(
                          (student) => DropdownMenuItem(
                            value: _text(student['id']),
                            child: Text(
                              _text(student['name']).isEmpty
                                  ? 'Aluno'
                                  : _text(student['name']),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedAthleteId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: typeController,
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de aula',
                      hintText: 'Ex.: Treino de força, avaliação física',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateUtils.dateOnly(DateTime.now()),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (value != null) {
                              setDialogState(
                                () => selectedDate = DateUtils.dateOnly(value),
                              );
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await showTimePicker(
                              context: dialogContext,
                              initialTime: selectedTime,
                            );
                            if (value != null) {
                              setDialogState(() => selectedTime = value);
                            }
                          },
                          icon: const Icon(Icons.schedule),
                          label: Text(selectedTime.format(dialogContext)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              onPressed: () {
                final type = typeController.text.trim();
                if (type.length < 2) return;
                Navigator.pop(dialogContext, {
                  'athleteId': selectedAthleteId,
                  'type': type,
                  'day': const [
                    'Dom',
                    'Seg',
                    'Ter',
                    'Qua',
                    'Qui',
                    'Sex',
                    'Sab',
                  ][selectedDate.weekday % 7],
                  'date': DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    12,
                  ).toUtc().toIso8601String(),
                  'time':
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                });
              },
              icon: const Icon(Icons.event_available),
              label: const Text('REGISTRAR AULA'),
            ),
          ],
        ),
      ),
    );
    typeController.dispose();
    if (classDetails == null || !mounted) return;

    final athlete = students.firstWhere(
      (student) => _text(student['id']) == classDetails['athleteId'],
      orElse: () => <String, dynamic>{},
    );
    if (Api.isDemoSession) {
      final newClass = <String, dynamic>{
        ...classDetails,
        'id': 'preview-class-${DateTime.now().microsecondsSinceEpoch}',
        'status': 'confirmed',
        'athlete': {
          'id': classDetails['athleteId'],
          'name': _text(athlete['name']),
        },
      };
      final savedClasses = await Api.previewClasses();
      await Api.savePreviewClasses([...savedClasses, newClass]);
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 2) {
        next.add(<dynamic>[]);
      }
      next[0] = [newClass, ..._list(next[0])];
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Aula registrada nesta prévia.';
      });
      return;
    }

    await _run(
      () => Api.post('/api/classes', classDetails),
      'Aula registrada para ${_text(athlete['name'])}.',
    );
  }

  Widget _section(String title, IconData icon, Widget child) =>
      StitchSection(title: title, icon: icon, child: child);

  double _dialogWidth(BuildContext context, double preferredWidth) =>
      (MediaQuery.sizeOf(context).width - 48)
          .clamp(0.0, preferredWidth)
          .toDouble();

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
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: _mText,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 14 : 12,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: TextStyle(
                  color: _mMuted,
                  fontSize: compact ? 12 : 10,
                  height: 1.4,
                ),
              ),
          ],
        );
        final textRow = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _mOrange, size: 17),
            const SizedBox(width: 10),
            Expanded(child: details),
          ],
        );
        final alignedTail = tail == null
            ? null
            : Align(alignment: Alignment.centerRight, child: tail);
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textRow,
              if (alignedTail != null) const SizedBox(height: 8),
              ?alignedTail,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: textRow),
            if (alignedTail != null) const SizedBox(width: 8),
            ?alignedTail,
          ],
        );
      },
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
  Widget _input(
    TextEditingController c,
    String label, {
    ValueChanged<String>? onSubmitted,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: c,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Future<void> _showChallengeLeaderboard(String challengeId) async {
    if (challengeId.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeLeaderboardPage(challengeId: challengeId),
      ),
    );
  }

  Future<void> _composePost() async {
    final controller = TextEditingController();
    String? imageUrl;
    final post = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Nova publicação'),
          content: SizedBox(
            width: _dialogWidth(dialogContext, 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'O que voc? quer compartilhar?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _socialImage(imageUrl!, height: 200),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() => imageUrl = null),
                        icon: const Icon(Icons.close),
                        label: const Text('REMOVER FOTO'),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await _pickSocialImage();
                        if (image != null && dialogContext.mounted) {
                          setDialogState(() => imageUrl = image);
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('ADICIONAR FOTO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (controller.text.trim().isEmpty && imageUrl == null) return;
                Navigator.pop(dialogContext, {
                  'text': controller.text.trim(),
                  if (imageUrl != null) 'imageUrl': imageUrl!,
                });
              },
              icon: const Icon(Icons.send),
              label: const Text('PUBLICAR'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (post == null || !mounted) return;
    final text = post['text']?.trim() ?? '';
    final image = post['imageUrl'];
    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final feed = Map<String, dynamic>.from(_map(next[0]));
      final posts = List<dynamic>.from(_list(feed['posts']));
      posts.insert(0, {
        'id': 'preview-post-${DateTime.now().microsecondsSinceEpoch}',
        'text': text,
        'imageUrl': ?image,
        'createdAt': DateTime.now().toIso8601String(),
        'user': {
          'id': _currentUserId,
          'displayName': _currentUserName.isEmpty
              ? 'Usu\u00e1rio'
              : _currentUserName,
        },
        '_count': {'likes': 0, 'comments': 0},
        'comments': <dynamic>[],
        'likedByCurrentUser': false,
      });
      feed['posts'] = posts;
      next[0] = feed;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Publica\u00e7\u00e3o criada nesta pr\u00e9via.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/social', {
        if (text.isNotEmpty) 'text': text,
        'imageUrl': ?image,
      }),
      'Publica??o enviada.',
    );
  }

  Future<void> _togglePostLike(Map<String, dynamic> post) async {
    final id = _text(post['id']);
    if (id.isEmpty) return;
    if (Api.isDemoSession || id.startsWith('demo-post-')) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final feed = Map<String, dynamic>.from(_map(next[0]));
      final posts = List<dynamic>.from(_list(feed['posts']));
      final index = posts.indexWhere((item) => _text(_map(item)['id']) == id);
      if (index < 0) return;
      final updated = Map<String, dynamic>.from(_map(posts[index]));
      final liked = updated['likedByCurrentUser'] == true;
      final counts = Map<String, dynamic>.from(_map(updated['_count']));
      counts['likes'] = (_n(counts['likes']).round() + (liked ? -1 : 1)).clamp(
        0,
        1 << 31,
      );
      updated['_count'] = counts;
      updated['likedByCurrentUser'] = !liked;
      posts[index] = updated;
      feed['posts'] = posts;
      next[0] = feed;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = liked
            ? 'Curtida removida nesta prévia.'
            : 'Curtida registrada nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/social/$id/like', {}),
      'Curtida registrada.',
    );
  }

  Future<void> _commentPost(String id) async {
    if (id.isEmpty) return;
    final controller = TextEditingController();
    String? imageUrl;
    final comment = await showDialog<Map<String, String>?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Comentar publicação'),
          content: SizedBox(
            width: _dialogWidth(dialogContext, 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Escreva seu coment\u00e1rio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _socialImage(imageUrl!, height: 180),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() => imageUrl = null),
                        icon: const Icon(Icons.close),
                        label: const Text('REMOVER FOTO'),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final image = await _pickSocialImage();
                        if (image != null && dialogContext.mounted) {
                          setDialogState(() => imageUrl = image);
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('ADICIONAR FOTO'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (controller.text.trim().isEmpty && imageUrl == null) return;
                Navigator.pop(dialogContext, {
                  'text': controller.text.trim(),
                  if (imageUrl != null) 'imageUrl': imageUrl!,
                });
              },
              icon: const Icon(Icons.send),
              label: const Text('ENVIAR'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    if (comment == null || !mounted) return;
    final text = comment['text']?.trim() ?? '';
    final image = comment['imageUrl'];
    if (Api.isDemoSession ||
        id.startsWith('demo-post-') ||
        id.startsWith('preview-post-')) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final feed = Map<String, dynamic>.from(_map(next[0]));
      final posts = List<dynamic>.from(_list(feed['posts']));
      final index = posts.indexWhere((item) => _text(_map(item)['id']) == id);
      if (index < 0) return;
      final updated = Map<String, dynamic>.from(_map(posts[index]));
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final comments = List<dynamic>.from(_list(updated['comments']))
        ..add({
          'id': 'preview-comment-$timestamp',
          'text': text,
          'imageUrl': ?image,
          'userId': _currentUserId,
          'user': {
            'id': _currentUserId,
            'displayName': _currentUserName.isEmpty
                ? 'Usu\u00e1rio'
                : _currentUserName,
          },
        });
      updated['comments'] = comments;
      final counts = Map<String, dynamic>.from(_map(updated['_count']));
      counts['comments'] = _n(counts['comments']).round() + 1;
      updated['_count'] = counts;
      posts[index] = updated;
      feed['posts'] = posts;
      next[0] = feed;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Coment\u00e1rio adicionado nesta pr\u00e9via.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/social/$id/comment', {
        'text': text,
        'imageUrl': ?image,
      }),
      'Coment\u00e1rio enviado.',
    );
  }

  Future<void> _editProfile() async {
    final name = await _prompt('Editar nome', 'Nome completo');
    if (name != null && name.trim().isNotEmpty) {
      await _saveProfile({'name': name.trim()}, 'Perfil atualizado.');
    }
  }

  Future<void> _editProfileMetric({
    required String field,
    required String value,
    required String title,
    required String hint,
  }) async {
    final input = await _prompt(
      title,
      hint,
      initialValue: value,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (input == null || input.trim().isEmpty) return;
    final number = double.tryParse(input.trim().replaceAll(',', '.'));
    final valid =
        number != null &&
        (field == 'weightKg'
            ? number >= 20 && number <= 400
            : number > 60 && number < 250);
    if (!valid) {
      _showInfo(
        field == 'weightKg'
            ? 'Informe um peso entre 20 e 400 kg.'
            : 'Informe uma altura entre 61 e 249 cm.',
      );
      return;
    }
    await _saveProfile({
      field: field == 'heightCm' ? number.round() : number,
    }, field == 'weightKg' ? 'Peso atualizado.' : 'Altura atualizada.');
  }

  Future<void> _changeProfilePhoto(Map<String, dynamic> profile) async {
    try {
      final selected = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (selected == null) return;
      final bytes = await selected.readAsBytes();
      if (bytes.length > 280_000) {
        _showInfo('A foto ficou muito grande. Escolha uma imagem menor.');
        return;
      }
      final mimeType = selected.mimeType;
      final safeMimeType = mimeType == 'image/png' || mimeType == 'image/webp'
          ? mimeType!
          : 'image/jpeg';
      final avatarUrl = 'data:$safeMimeType;base64,${base64Encode(bytes)}';
      if (Api.isDemoSession) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_avatarStorageKey(profile), avatarUrl);
        await _saveProfile({
          'avatarUrl': avatarUrl,
        }, 'Foto salva nesta demonstração.');
      } else {
        await _saveProfile({
          'avatarUrl': avatarUrl,
        }, 'Foto de perfil atualizada.');
      }
    } catch (error) {
      if (mounted) {
        _showInfo('Não foi possível selecionar a foto: $error');
      }
    }
  }

  Future<void> _saveProfile(
    Map<String, dynamic> changes,
    String successMessage,
  ) async {
    if (!Api.isDemoSession) {
      await _run(() => Api.patch('/api/user/profile', changes), successMessage);
      return;
    }

    final next = List<dynamic>.from(_snapshotData);
    if (next.isEmpty || next.first is! Map) return;
    final profile = Map<String, dynamic>.from(_map(next.first));
    final nestedKey = profile['role'] == 'personal' ? 'personal' : 'athlete';
    final nested = Map<String, dynamic>.from(_map(profile[nestedKey]));
    for (final entry in changes.entries) {
      if (entry.key == 'avatarUrl') {
        profile['avatarUrl'] = entry.value;
        continue;
      }
      if (entry.key == 'name') profile['name'] = entry.value;
      nested[entry.key] = entry.value;
    }
    profile[nestedKey] = nested;
    next[0] = profile;
    setState(() {
      _snapshotData = next;
      _data = Future.value(next);
      _notice =
          'Pr\u00e9via: altera\u00e7\u00e3o aplicada somente nesta demonstra\u00e7\u00e3o.';
    });
  }

  String _bmiCategory(double bmi) => switch (bmi) {
    < 18.5 => 'abaixo do peso',
    < 25 => 'faixa saud\u00e1vel',
    < 30 => 'sobrepeso',
    _ => 'obesidade',
  };

  Future<void> _connectIntegration(String provider) async {
    await _run(() async {
      final result = _map(
        await Api.post('/api/integrations', {
          'provider': provider,
          'platform': kIsWeb ? 'flutter_web' : 'flutter_native',
        }),
      );
      if (!mounted) return null;
      final url = _text(result['url']);
      if (url.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _mCard,
            title: const Text('Autorização necessária'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Abra a autorização do provedor no navegador. '
                  'Ao concluir, o WeGYM volta para esta tela e atualiza o status automaticamente.',
                ),
                const SizedBox(height: 12),
                SelectableText(url),
              ],
            ),
            actions: [
              FilledButton.icon(
                onPressed: () => _openOAuthUrl(url),
                icon: const Icon(Icons.open_in_new),
                label: const Text('ABRIR NO NAVEGADOR'),
              ),
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

  Future<void> _openOAuthUrl(String value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final opened = await launchUrl(
        Uri.parse(value),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Não foi possível abrir o navegador.');
    } catch (_) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir automaticamente. Copie o link exibido.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    _deleteConfirmation.clear();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refreshDialog) => AlertDialog(
          backgroundColor: _mCard,
          title: const Text('Excluir conta?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta a\u00e7\u00e3o \u00e9 permanente e apaga os dados da conta.',
              ),
              const SizedBox(height: 12),
              const Text('Digite EXCLUIR para confirmar.'),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('account-delete-confirmation'),
                controller: _deleteConfirmation,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => refreshDialog(() {}),
                decoration: const InputDecoration(
                  labelText: 'Confirma\u00e7\u00e3o',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR'),
            ),
            FilledButton(
              onPressed:
                  _deleteConfirmation.text.trim().toUpperCase() == 'EXCLUIR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('EXCLUIR'),
            ),
          ],
        ),
      ),
    );
    _deleteConfirmation.clear();
    if (ok != true) return;
    if (Api.isDemoSession) {
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
      await Api.delete('/api/user/account', {});
      await Api.logout();
      if (mounted) {
        setState(() => _notice = 'Conta exclu\u00edda. Sess\u00e3o encerrada.');
        widget.onLogout?.call();
      }
    } catch (error) {
      if (mounted) setState(() => _notice = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportProfileData() async {
    if (Api.isDemoSession) {
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
      final data = await Api.get('/api/user/export');
      final savedPath = await ProfileDataExport.saveJson(data);
      if (mounted) {
        setState(
          () => _notice = savedPath == null
              ? 'Exporta\u00e7\u00e3o cancelada.'
              : 'Arquivo de dados exportado com sucesso.',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _notice = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
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
    if (Api.isDemoSession) {
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
    final email = await _prompt('Adicionar amigo', 'E-mail da pessoa');
    if (email != null && email.trim().isNotEmpty) {
      final normalizedEmail = email.trim().toLowerCase();
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalizedEmail)) {
        _showInfo('Informe um e-mail válido.');
        return;
      }
      if (Api.isDemoSession) {
        final next = List<dynamic>.from(_snapshotData);
        final response = Map<String, dynamic>.from(
          _map(next.isNotEmpty ? next[0] : null),
        );
        final outgoing = List<dynamic>.from(
          _list(response['outgoingRequests']),
        );
        outgoing.add({
          'id': 'preview-outgoing-${DateTime.now().microsecondsSinceEpoch}',
          'displayName': normalizedEmail,
          'status': 'pending',
        });
        response['outgoingRequests'] = outgoing;
        if (next.isEmpty) {
          next.add(response);
        } else {
          next[0] = response;
        }
        setState(() {
          _snapshotData = next;
          _data = Future.value(next);
          _notice = 'Solicitação adicionada nesta prévia.';
        });
        return;
      }
      await _run(
        () => Api.post('/api/friends', {'addresseeEmail': normalizedEmail}),
        'Solicitação enviada.',
      );
    }
  }

  Future<void> _respondFriend(String requestId, bool accept) async {
    if (requestId.isEmpty) return;
    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final response = Map<String, dynamic>.from(_map(next[0]));
      final incoming = List<dynamic>.from(_list(response['incomingRequests']));
      final index = incoming.indexWhere((item) {
        final request = _map(item);
        return _text(request['friendshipId'] ?? request['id']) == requestId;
      });
      if (index < 0) return;
      final request = _map(incoming.removeAt(index));
      if (accept) {
        final friends = List<dynamic>.from(_list(response['friends']))
          ..add({...request, 'status': 'accepted'});
        response['friends'] = friends;
      }
      response['incomingRequests'] = incoming;
      next[0] = response;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = accept
            ? 'Solicitação aceita nesta prévia.'
            : 'Solicitação recusada nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/friends', {
        'action': 'respond',
        'friendshipId': requestId,
        'response': accept ? 'accept' : 'reject',
      }),
      accept ? 'Amizade aceita.' : 'Solicitação recusada.',
    );
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
    if (Api.isDemoSession) {
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
    if (Api.isDemoSession) {
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
    if (_currentRole == 'personal' &&
        _selectedMeasurementAthleteId == null &&
        !Api.isDemoSession) {
      _showInfo('Selecione um aluno antes de registrar a avalia\u00e7\u00e3o.');
      return;
    }
    final weightText = await _prompt(
      'Nova avalia\u00e7\u00e3o',
      'Peso em kg (obrigat\u00f3rio)',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (weightText == null) return;
    final weight = double.tryParse(weightText.replaceAll(',', '.'));
    if (weight == null || weight < 20 || weight > 400) {
      _showInfo('Informe um peso entre 20 e 400 kg.');
      return;
    }
    final muscleText = await _prompt(
      'Massa muscular',
      'Massa muscular em kg (opcional)',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (muscleText == null) return;
    final muscleMass = muscleText.trim().isEmpty
        ? null
        : double.tryParse(muscleText.replaceAll(',', '.'));
    if (muscleText.trim().isNotEmpty &&
        (muscleMass == null || muscleMass < 0 || muscleMass > 200)) {
      _showInfo('Informe uma massa muscular entre 0 e 200 kg.');
      return;
    }
    final fatText = await _prompt(
      'Gordura corporal',
      'Percentual de gordura (opcional)',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (fatText == null) return;
    final bodyFat = fatText.trim().isEmpty
        ? null
        : double.tryParse(fatText.replaceAll(',', '.'));
    if (fatText.trim().isNotEmpty &&
        (bodyFat == null || bodyFat < 0 || bodyFat > 70)) {
      _showInfo('Informe um percentual de gordura entre 0 e 70.');
      return;
    }
    final note = await _prompt(
      'Observa\u00e7\u00f5es',
      'Observa\u00e7\u00f5es da avalia\u00e7\u00e3o (opcional)',
    );
    if (note == null) return;

    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      final measurements = List<dynamic>.from(
        _list(next.isNotEmpty ? next[0] : const []),
      );
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final records = <Map<String, dynamic>>[
        {
          'id': 'preview-measurement-weight-$timestamp',
          'name': 'Peso',
          'value': '${weight.toStringAsFixed(1)} kg',
          'date': 'Agora',
        },
        if (muscleMass != null)
          {
            'id': 'preview-measurement-muscle-$timestamp',
            'name': 'Massa muscular',
            'value': '${muscleMass.toStringAsFixed(1)} kg',
            'date': 'Agora',
          },
        if (bodyFat != null)
          {
            'id': 'preview-measurement-fat-$timestamp',
            'name': 'Gordura corporal',
            'value': '${bodyFat.toStringAsFixed(1)}%',
            'date': 'Agora',
          },
      ];
      measurements.insertAll(0, records);
      while (next.length < 3) {
        next.add([]);
      }
      next[0] = measurements;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Avalia\u00e7\u00e3o registrada nesta pr\u00e9via.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/body-measurements', {
        'weight': weight,
        'muscleMass': ?muscleMass,
        'bodyFat': ?bodyFat,
        if (note.trim().isNotEmpty) 'note': note.trim(),
        'date': DateTime.now().toIso8601String(),
        if (_currentRole == 'personal')
          'athleteId': _selectedMeasurementAthleteId,
      }),
      'Avalia\u00e7\u00e3o registrada.',
    );
  }

  Future<void> _createDietPlan() async {
    if (Api.isDemoSession) {
      final title = await _prompt('Novo plano alimentar', 'Nome do plano');
      if (title == null || title.trim().isEmpty) return;
      final caloriesText = await _prompt(
        'Meta calórica diária',
        'Calorias por dia (opcional)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 2) {
        next.add(<dynamic>[]);
      }
      final plans = List<dynamic>.from(_list(next[1]));
      plans.add({
        'id': 'preview-diet-${DateTime.now().microsecondsSinceEpoch}',
        'title': title.trim(),
        'dailyCalories': calories,
        'description': calories == null
            ? 'Plano alimentar de demonstração'
            : '${calories.round()} kcal por dia',
      });
      next[1] = plans;
      if (!mounted) return;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Plano alimentar criado nesta prévia.';
      });
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
    const mealTypes = <(String, String)>[
      ('breakfast', 'Café da manhã'),
      ('lunch', 'Almoço'),
      ('dinner', 'Jantar'),
      ('snack', 'Lanche'),
    ];
    final type = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: _mCard,
        title: const Text('Registrar refeição'),
        children: mealTypes
            .map(
              (meal) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, meal.$1),
                child: Text(meal.$2),
              ),
            )
            .toList(),
      ),
    );
    if (type == null) return;
    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      while (next.length < 3) {
        next.add(<dynamic>[]);
      }
      final meals = List<dynamic>.from(_list(next[0]));
      final labels = {
        'breakfast': 'Café da manhã',
        'lunch': 'Almoço',
        'dinner': 'Jantar',
        'snack': 'Lanche',
      };
      meals.insert(0, {
        'id': 'preview-meal-${DateTime.now().microsecondsSinceEpoch}',
        'type': type,
        'name': labels[type] ?? 'Refeição',
        'date': _nutritionDateKey(_nutritionDate),
        'foods': <dynamic>[],
        'totals': {'calories': 0, 'proteinG': 0, 'carbsG': 0, 'fatG': 0},
      });
      next[0] = meals;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = 'Refeição registrada nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.post('/api/nutrition/meals', {
        'type': type,
        'date': _nutritionDateKey(_nutritionDate),
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
    if (Api.isDemoSession) {
      _addPreviewAppointment(slot);
      return;
    }
    await _run(
      () => Api.post('/api/appointments', {'slotId': slotId, 'type': 'treino'}),
      'Agendamento solicitado.',
    );
  }

  Future<void> _bookSlot() async {
    if (_currentRole == 'personal') {
      await _createAppointmentSlot();
      return;
    }
    final slots = _list(
      _snapshotData.length > 1 ? _snapshotData[1] : null,
    ).map(_map).where((slot) => slot['available'] != false).toList();
    if (slots.isEmpty) {
      _showInfo('Não há horários disponíveis para reservar.');
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mCard,
        title: const Text('Escolha um horário'),
        content: SizedBox(
          width: _dialogWidth(dialogContext, 440),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: slots.map((slot) {
                final date = _text(slot['date']);
                final start = _text(slot['startTime']);
                final end = _text(slot['endTime']);
                return ListTile(
                  leading: const Icon(Icons.event_available, color: _mOrange),
                  title: Text(date),
                  subtitle: Text('$start – $end'),
                  onTap: () => Navigator.pop(dialogContext, slot),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
    if (selected != null) await _bookSlotFor(selected);
  }

  Future<void> _createAppointmentSlot() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
      helpText: 'Horário de término',
    );
    if (end == null || !mounted) return;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    if (endMinutes <= startMinutes) {
      _showInfo('O término precisa ser depois do início no mesmo dia.');
      return;
    }
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final dateValue = _nutritionDateKey(date);
    final startValue = '${twoDigits(start.hour)}:${twoDigits(start.minute)}';
    final endValue = '${twoDigits(end.hour)}:${twoDigits(end.minute)}';
    final payload = {
      'date': dateValue,
      'startTime': startValue,
      'endTime': endValue,
    };

    if (Api.isDemoSession) {
      if (widget.module == 'Agendamentos') {
        final next = List<dynamic>.from(_snapshotData);
        while (next.length < 2) {
          next.add(<dynamic>[]);
        }
        final slots = List<dynamic>.from(_list(next[1]))
          ..add({
            'id': 'preview-slot-${DateTime.now().microsecondsSinceEpoch}',
            ...payload,
            'available': true,
          });
        next[1] = slots;
        setState(() {
          _snapshotData = next;
          _data = Future.value(next);
          _notice = 'Horário criado nesta prévia.';
        });
      } else {
        setState(() => _notice = 'Horário criado nesta prévia.');
      }
      return;
    }
    await _run(
      () => Api.post('/api/appointments/slots', payload),
      'Horário disponível criado.',
    );
  }

  void _addPreviewAppointment(Map<String, dynamic> slot) {
    final next = List<dynamic>.from(_snapshotData);
    while (next.length < 2) {
      next.add(<dynamic>[]);
    }
    final appointments = List<dynamic>.from(_list(next[0]));
    final date = _text(slot['date']);
    final time = _text(slot['startTime']);
    appointments.insert(0, {
      'id': 'preview-appointment-${DateTime.now().microsecondsSinceEpoch}',
      'date': [date, time].where((part) => part.isNotEmpty).join(' • '),
      'status': 'pending',
      if (_currentRole == 'personal')
        'athlete': {'displayName': 'Atleta da demonstração'}
      else
        'personal': {'displayName': 'Carlos Personal'},
    });
    final slots = List<dynamic>.from(_list(next[1]))
      ..removeWhere((item) => _text(_map(item)['id']) == _text(slot['id']));
    next[0] = appointments;
    next[1] = slots;
    setState(() {
      _snapshotData = next;
      _data = Future.value(next);
      _notice = 'Agendamento solicitado nesta prévia.';
    });
  }

  Future<void> _changeAppointment(String id, String action) async {
    final successMessage = action == 'cancel'
        ? 'Agendamento cancelado.'
        : 'Agendamento confirmado.';
    if (Api.isDemoSession) {
      final next = List<dynamic>.from(_snapshotData);
      if (next.isEmpty) return;
      final appointments = List<dynamic>.from(_list(next[0]));
      final index = appointments.indexWhere(
        (item) => _text(_map(item)['id']) == id,
      );
      if (index < 0) return;
      appointments[index] = {
        ..._map(appointments[index]),
        'status': action == 'cancel' ? 'cancelled' : 'confirmed',
      };
      next[0] = appointments;
      setState(() {
        _snapshotData = next;
        _data = Future.value(next);
        _notice = action == 'cancel'
            ? 'Agendamento cancelado nesta prévia.'
            : 'Agendamento confirmado nesta prévia.';
      });
      return;
    }
    await _run(
      () => Api.patch('/api/appointments', {'id': id, 'action': action}),
      successMessage,
    );
  }

  Future<String?> _prompt(
    String title,
    String hint, {
    String initialValue = '',
    TextInputType? keyboardType,
  }) async {
    final c = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _mCard,
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: keyboardType,
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
    // Wait for the dialog's reverse transition before disposing the controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
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
  String _communityUserName(Map user) {
    final athlete = _text(_map(user['athlete'])['name']).trim();
    final personal = _text(_map(user['personal'])['name']).trim();
    final display = _text(user['displayName'] ?? user['name']).trim();
    return athlete.isNotEmpty
        ? athlete
        : personal.isNotEmpty
        ? personal
        : display.isNotEmpty
        ? display
        : 'Usu\u00e1rio';
  }

  String _userName(dynamic row) {
    final post = _map(row);
    final user = _map(post['user']);
    if (_currentUserId.isNotEmpty && _text(user['id']) == _currentUserId) {
      return _currentUserName.isEmpty ? 'Usu\u00e1rio' : _currentUserName;
    }
    return _communityUserName(user);
  }

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
