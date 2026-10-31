import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'stitch_design_system.dart';

const _surface = stitchSurface;
const _days = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];
const _dayCodes = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
const _dayShort = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
const _splitOptions = [
  'PPL',
  'Upper/Lower',
  'Full body',
  'ABC',
  'Bro split',
  'Personalizado',
];

class WorkoutBuilderPage extends StatefulWidget {
  const WorkoutBuilderPage({
    super.key,
    required this.onStartSession,
    this.onStartPlannedSession,
  });
  final VoidCallback onStartSession;
  final ValueChanged<List<Map<String, dynamic>>>? onStartPlannedSession;
  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  final _catalog = <String, String>{
    'Supino reto com barra': 'Peito',
    'Supino inclinado com halteres': 'Peito',
    'Crossover na polia': 'Peito',
    'Crucifixo com halteres': 'Peito',
    'Peck deck': 'Peito',
    'Flex\u00e3o de bra\u00e7os': 'Peito',
    'Supino na m\u00e1quina': 'Peito',
    'Crossover na polia baixa': 'Peito',
    'Puxada frontal': 'Costas',
    'Remada baixa': 'Costas',
    'Remada unilateral': 'Costas',
    'Remada curvada com barra': 'Costas',
    'Pulldown com bra\u00e7os retos': 'Costas',
    'Remada cavalinho': 'Costas',
    'Barra fixa assistida': 'Costas',
    'Remada na m\u00e1quina': 'Costas',
    'Desenvolvimento com halteres': 'Ombros',
    'Eleva\u00e7\u00e3o lateral': 'Ombros',
    'Face pull': 'Ombros',
    'Crucifixo inverso': 'Ombros',
    'Desenvolvimento na m\u00e1quina': 'Ombros',
    'Eleva\u00e7\u00e3o frontal': 'Ombros',
    'Agachamento livre': 'Quadr\u00edceps',
    'Leg press 45\u00b0': 'Quadr\u00edceps',
    'Cadeira extensora': 'Quadr\u00edceps',
    'Afundo com halteres': 'Quadr\u00edceps',
    'Agachamento b\u00falgaro': 'Quadr\u00edceps',
    'Hack squat': 'Quadr\u00edceps',
    'Levantamento terra romeno': 'Posterior',
    'Mesa flexora': 'Posterior',
    'Cadeira flexora': 'Posterior',
    'Stiff com halteres': 'Posterior',
    'Hip thrust': 'Gl\u00fateos',
    'Glute bridge': 'Gl\u00fateos',
    'Coice na polia': 'Gl\u00fateos',
    'Abdu\u00e7\u00e3o de quadril': 'Gl\u00fateos',
    'Rosca direta': 'B\u00edceps',
    'Rosca martelo': 'B\u00edceps',
    'Rosca inclinada': 'B\u00edceps',
    'Rosca Scott': 'B\u00edceps',
    'Tr\u00edceps corda': 'Tr\u00edceps',
    'Mergulho nas paralelas': 'Tr\u00edceps',
    'Tr\u00edceps franc\u00eas com halter': 'Tr\u00edceps',
    'Extens\u00e3o de tr\u00edceps na polia': 'Tr\u00edceps',
    'Panturrilha em p\u00e9': 'Panturrilhas',
    'Panturrilha sentada': 'Panturrilhas',
    'Prancha': 'Core',
    'Abdominal na polia': 'Core',
    'Eleva\u00e7\u00e3o de pernas': 'Core',
    'Dead bug': 'Core',
  };
  int _day = DateTime.now().weekday - 1;
  final Map<int, List<Map<String, String>>> _plans = {};
  final Map<int, String> _savedPlanIds = {};
  final Set<int> _trainingDays = {0, 2, 4};
  List<Map<String, dynamic>> _athletes = [];
  String? _athleteId;
  String _athleteName = '';
  String _split = 'PPL';
  bool _isPersonal = false;
  bool _loadingPlan = true;
  bool _saving = false;
  bool _generatingWithAI = false;
  String _notice = '';
  String _libraryQuery = '';
  String? _muscleFilter;
  List<Map<String, String>> get _exercises =>
      _plans.putIfAbsent(_day, () => <Map<String, String>>[]);

  @override
  void initState() {
    super.initState();
    _initializePlans();
  }

  Map<String, String> _exercise(String name) => {
    'name': name,
    'muscle': _catalog[name] ?? 'Geral',
    'sets': '3',
    'reps': '10',
    'load': '0',
  };

  Future<void> _generateWithAI() async {
    final goal = TextEditingController();
    final level = ValueNotifier<String>('Intermediário');
    final input = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: stitchSurface,
        title: const Text('Montar treino com IA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: goal,
              decoration: const InputDecoration(
                labelText: 'Objetivo ou foco do treino',
                hintText: 'Ex.: hipertrofia de peito e tríceps',
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: level,
              builder: (context, selected, _) => DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(labelText: 'Nível'),
                items: const ['Iniciante', 'Intermediário', 'Avançado']
                    .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) level.value = value;
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, [goal.text.trim(), level.value]),
            child: const Text('GERAR'),
          ),
        ],
      ),
    );
    goal.dispose();
    level.dispose();
    if (input == null || input[0].isEmpty) return;
    setState(() {
      _generatingWithAI = true;
      _notice = '';
    });
    try {
      final result = await Api.generateAIWorkout(message: input[0], level: input[1]);
      final workout = result['workoutData'];
      final rows = workout is Map ? workout['exercises'] : null;
      if (rows is! List || rows.isEmpty) {
        throw Exception('A IA não retornou exercícios para este objetivo.');
      }
      final generated = rows.whereType<Map>().map((row) => <String, String>{
        'name': row['name']?.toString() ?? 'Exercício',
        'muscle': _catalog[row['name']?.toString()] ?? 'Geral',
        'sets': row['sets']?.toString() ?? '3',
        'reps': row['reps']?.toString() ?? '10',
        'load': row['load']?.toString() ?? '0',
      }).toList();
      if (!mounted) return;
      setState(() {
        _plans[_day] = generated;
        _notice = (result['text'] ?? 'Treino sugerido pela IA.').toString();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _notice = const bool.fromEnvironment('PREVIEW_DASHBOARD')
          ? 'A IA requer o backend Next.js ativo e uma sessão autenticada. Entre com uma conta real para gerar sugestões.'
          : 'Não foi possível gerar o treino: $error');
    } finally {
      if (mounted) setState(() => _generatingWithAI = false);
    }
  }

  Future<void> _initializePlans() async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      _applySplitToDays();
      if (mounted) setState(() => _loadingPlan = false);
      return;
    }
    try {
      final profile = await Api.profile();
      _isPersonal = profile['role'] == 'personal';
      if (_isPersonal) {
        _athletes = await Api.athletes();
        if (_athletes.isNotEmpty) {
          _athleteId = _athletes.first['id']?.toString();
          _athleteName = _athletes.first['name']?.toString() ?? '';
        }
      } else {
        final athlete = profile['athlete'];
        _athleteId = athlete is Map ? athlete['id']?.toString() : null;
        _athleteName = athlete is Map ? athlete['name']?.toString() ?? '' : '';
      }
      if (_athleteId != null) await _loadPlans(_athleteId!);
    } catch (error) {
      _notice = 'N\u00e3o foi poss\u00edvel carregar os treinos: $error';
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _selectAthlete(Map<String, dynamic> athlete) async {
    final id = athlete['id']?.toString();
    if (id == null || id == _athleteId) return;
    setState(() {
      _athleteId = id;
      _athleteName = athlete['name']?.toString() ?? '';
      _loadingPlan = true;
      _plans.clear();
      _savedPlanIds.clear();
      _trainingDays.clear();
      _notice = '';
    });
    try {
      await _loadPlans(id);
    } catch (error) {
      _notice =
          'N\u00e3o foi poss\u00edvel carregar os treinos do atleta: $error';
    } finally {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  Future<void> _loadPlans(String athleteId) async {
    final rows = await Api.trainingPlan(athleteId);
    _plans.clear();
    _savedPlanIds.clear();
    for (final row in rows) {
      final index = _dayCodes.indexOf(row['day']?.toString() ?? '');
      if (index < 0) continue;
      final planId = row['id']?.toString();
      if (planId != null) _savedPlanIds[index] = planId;
      final rawExercises = row['exercises'];
      _plans[index] = rawExercises is List
          ? rawExercises.whereType<Map>().map((item) {
              final exercise = _exercise(item['name']?.toString() ?? '');
              exercise['sets'] = item['sets']?.toString() ?? '3';
              exercise['reps'] = item['reps']?.toString() ?? '10';
              exercise['load'] = item['load']?.toString() ?? '0';
              return exercise;
            }).toList()
          : <Map<String, String>>[];
    }
    _trainingDays
      ..clear()
      ..addAll(_plans.keys);
    if (_trainingDays.isEmpty) {
      _trainingDays.addAll([0, 2, 4]);
      _applySplitToDays();
    }
    _day = _trainingDays.contains(DateTime.now().weekday - 1)
        ? DateTime.now().weekday - 1
        : _trainingDays.first;
  }

  List<String> _splitExercises(int position) {
    const push = [
      'Supino reto com barra',
      'Supino inclinado com halteres',
      'Crossover na polia',
      'Desenvolvimento com halteres',
      'Eleva\u00e7\u00e3o lateral',
      'Tr\u00edceps corda',
    ];
    const pull = [
      'Puxada frontal',
      'Remada baixa',
      'Remada unilateral',
      'Face pull',
      'Rosca direta',
      'Rosca martelo',
    ];
    const legs = [
      'Agachamento livre',
      'Leg press 45\u00b0',
      'Levantamento terra romeno',
      'Cadeira extensora',
      'Mesa flexora',
      'Hip thrust',
      'Panturrilha em p\u00e9',
    ];
    const upper = [
      'Supino reto com barra',
      'Remada curvada com barra',
      'Supino inclinado com halteres',
      'Puxada frontal',
      'Desenvolvimento com halteres',
      'Rosca direta',
      'Tr\u00edceps corda',
    ];
    const lower = [
      'Agachamento livre',
      'Levantamento terra romeno',
      'Leg press 45\u00b0',
      'Cadeira flexora',
      'Afundo com halteres',
      'Hip thrust',
      'Panturrilha sentada',
    ];
    const full = [
      'Agachamento livre',
      'Supino reto com barra',
      'Remada baixa',
      'Levantamento terra romeno',
      'Desenvolvimento com halteres',
      'Cadeira flexora',
      'Prancha',
    ];
    const shoulders = [
      'Desenvolvimento com halteres',
      'Eleva\u00e7\u00e3o lateral',
      'Crucifixo inverso',
      'Eleva\u00e7\u00e3o frontal',
      'Face pull',
    ];
    const arms = [
      'Rosca direta',
      'Rosca martelo',
      'Rosca inclinada',
      'Tr\u00edceps corda',
      'Tr\u00edceps franc\u00eas com halter',
    ];
    const chest = [
      'Supino reto com barra',
      'Supino inclinado com halteres',
      'Crossover na polia',
      'Crucifixo com halteres',
      'Peck deck',
      'Crossover na polia baixa',
    ];
    const back = [
      'Puxada frontal',
      'Remada curvada com barra',
      'Remada baixa',
      'Remada unilateral',
      'Remada cavalinho',
      'Barra fixa assistida',
    ];
    final groups = switch (_split) {
      'PPL' => [push, pull, legs],
      'Upper/Lower' => [upper, lower],
      'Full body' => [full],
      'ABC' => [push, pull, legs],
      'Bro split' => [chest, back, legs, shoulders, arms],
      _ => <List<String>>[],
    };
    return groups.isEmpty ? [] : groups[position % groups.length];
  }

  void _applySplitToDays() {
    final selected = _trainingDays.toList()..sort();
    for (var position = 0; position < selected.length; position++) {
      _plans[selected[position]] = _splitExercises(
        position,
      ).map(_exercise).toList();
    }
  }

  void _toggleTrainingDay(int index, bool selected) {
    if (!selected && _trainingDays.length == 1) return;
    setState(() {
      if (selected) {
        _trainingDays.add(index);
        if (!_plans.containsKey(index)) {
          final ordered = _trainingDays.toList()..sort();
          _plans[index] = _splitExercises(
            ordered.indexOf(index),
          ).map(_exercise).toList();
        }
      } else {
        _trainingDays.remove(index);
      }
      if (!_trainingDays.contains(_day)) _day = _trainingDays.first;
      _notice = '';
    });
  }

  Future<void> _savePlan() async {
    final preview = const bool.fromEnvironment('PREVIEW_DASHBOARD');
    if (_trainingDays.isEmpty || (!preview && _athleteId == null)) {
      setState(
        () => _notice = _isPersonal
            ? 'Selecione um atleta vinculado antes de salvar.'
            : 'Não foi possível identificar seu perfil de atleta.',
      );
      return;
    }
    if (preview) {
      setState(
        () => _notice =
            'Prévia: divisão semanal salva localmente para $_athleteName.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _notice = '';
    });
    try {
      final selected = _trainingDays.toList()..sort();
      final removedDays = _savedPlanIds.keys
          .where((day) => !_trainingDays.contains(day))
          .toList();
      for (final day in removedDays) {
        await Api.deleteTrainingPlan(_savedPlanIds.remove(day)!);
        _plans.remove(day);
      }
      for (final index in selected) {
        final id = await Api.saveTrainingPlan(
          athleteId: _athleteId!,
          day: _dayCodes[index],
          exercises: (_plans[index] ?? [])
              .map(
                (exercise) => {
                  'name': exercise['name'] ?? '',
                  'sets': exercise['sets'] ?? '3',
                  'reps': exercise['reps'] ?? '10',
                  'load': exercise['load'] ?? '0',
                },
              )
              .toList(),
        );
        if (id != null) _savedPlanIds[index] = id;
      }
      if (mounted) {
        setState(
          () => _notice = 'Divisão semanal salva para $_athleteName.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _notice =
              'Não foi possível salvar a divisão: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addExercise(String name) {
    setState(() {
      _exercises.add(_exercise(name));
      _notice = '';
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 940;
      final horizontalPadding = wide ? 18.0 : 12.0;
      final contentWidth = (constraints.maxWidth - horizontalPadding * 2)
          .clamp(0.0, 1500.0)
          .toDouble();
      final muscles = <String, int>{};
      for (final exercise in _exercises) {
        final muscle = exercise['muscle'] ?? 'Geral';
        muscles[muscle] =
            (muscles[muscle] ?? 0) +
            (int.tryParse(exercise['sets'] ?? '') ?? 0);
      }

      // Keep the whole screen scrollable. A short browser window must never
      // squeeze the editor and analysis column into a zero-height Flex.
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          18,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: contentWidth, maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 14),
                _stats(contentWidth),
                const SizedBox(height: 14),
                _planControls(),
                const SizedBox(height: 14),
                _dayTabs(),
                const SizedBox(height: 14),
                if (wide)
                  SizedBox(
                    height: 620,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _editor(wide: true)),
                        const SizedBox(width: 14),
                        SizedBox(width: 300, child: _side(muscles)),
                      ],
                    ),
                  )
                else ...[
                  _editor(wide: false),
                  const SizedBox(height: 14),
                  SizedBox(height: 620, child: _side(muscles)),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _header() => StitchCard(
    gradient: true,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.file_upload_outlined, size: 16),
              label: const Text('IMPORTAR MODELO'),
            ),
            OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
              label: const Text('PDF / EXPORTAR'),
            ),
            FilledButton.icon(
              onPressed:
                  _saving ||
                      _loadingPlan ||
                      (_athleteId == null &&
                          !const bool.fromEnvironment('PREVIEW_DASHBOARD'))
                  ? null
                  : _savePlan,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: Text(_saving ? 'SALVANDO...' : 'SALVAR SEMANA'),
              style: FilledButton.styleFrom(
                backgroundColor: stitchOrange,
                foregroundColor: stitchOnPrimaryContainer,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const StitchTag('Ativa • Semana 3 de 8', color: stitchGreen),
                const StitchKicker('Macrociclo: força & hipertrofia'),
              ],
            ),
            const SizedBox(height: 9),
            const Text(
              'PLANEJAMENTO DE TREINO',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: stitchText,
                fontSize: 21,
                height: 1.12,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Organize seus treinos, ajuste cargas e acompanhe o volume por grupo muscular.',
              style: TextStyle(color: stitchMuted, fontSize: 11, height: 1.4),
            ),
          ],
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 14), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            Flexible(
              child: Align(alignment: Alignment.centerRight, child: actions),
            ),
          ],
        );
      },
    ),
  );

  Widget _stats(double availableWidth) {
    final totalSets = _exercises.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item['sets'] ?? '') ?? 0),
    );
    final columns = availableWidth >= 900
        ? 4
        : availableWidth >= 360
        ? 2
        : 1;
    final width = (availableWidth - (columns - 1) * 10) / columns;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: width,
          child: StitchMetric(
            label: 'EXERCÍCIOS NO TREINO',
            value: _exercises.length.toString(),
            icon: Icons.fitness_center,
          ),
        ),
        SizedBox(
          width: width,
          child: StitchMetric(
            label: 'SÉRIES TOTAIS',
            value: totalSets.toString(),
            icon: Icons.view_list,
            tint: stitchGreen,
          ),
        ),
        SizedBox(
          width: width,
          child: StitchMetric(
            label: 'TEMPO ESTIMADO',
            value: '${totalSets * 3} min',
            icon: Icons.timer_outlined,
            tint: stitchBlue,
          ),
        ),
        SizedBox(
          width: width,
          child: StitchMetric(
            label: 'CARGA PLANEJADA',
            value: _plannedLoad(),
            icon: Icons.monitor_weight_outlined,
            tint: stitchPeach,
          ),
        ),
      ],
    );
  }

  String _plannedLoad() {
    var volume = 0.0;
    for (final exercise in _exercises) {
      final sets = int.tryParse(exercise['sets'] ?? '');
      final reps = int.tryParse(exercise['reps'] ?? '');
      final load = double.tryParse(
        (exercise['load'] ?? '').replaceAll(',', '.'),
      );
      if (sets == null || reps == null || load == null) return '—';
      volume += sets * reps * load;
    }
    if (volume <= 0) return '—';
    return volume >= 1000
        ? '${(volume / 1000).toStringAsFixed(1)} t'
        : '${volume.toStringAsFixed(0)} kg';
  }

  Widget _planControls() => StitchCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month, color: stitchOrange, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: StitchKicker('AGENDA E DIVIS\u00c3O SEMANAL'),
            ),
            DropdownButton<String>(
              value: _split,
              dropdownColor: stitchSurface,
              underline: const SizedBox.shrink(),
              items: _splitOptions
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _split = value;
                  if (_split != 'Personalizado') _applySplitToDays();
                  _notice = '';
                });
              },
            ),
          ],
        ),
        if (_isPersonal) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_search, color: stitchPeach, size: 17),
              const SizedBox(width: 8),
              const Text(
                'ATLETA',
                style: TextStyle(
                  color: stitchMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _athleteId,
                  hint: Text(
                    _athletes.isEmpty
                        ? 'Nenhum atleta vinculado'
                        : 'Selecione o atleta',
                  ),
                  dropdownColor: stitchSurface,
                  items: _athletes
                      .map(
                        (athlete) => DropdownMenuItem<String>(
                          value: athlete['id']?.toString(),
                          child: Text(
                            athlete['name']?.toString() ?? 'Atleta',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    final matches = _athletes.where(
                      (item) => item['id']?.toString() == id,
                    );
                    if (matches.isNotEmpty) _selectAthlete(matches.first);
                  },
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 7),
        const Text(
          'Escolha os dias em que vai treinar. O modelo distribui treinos diferentes; depois, edite os exercícios de cada dia.',
          style: TextStyle(color: stitchMuted, fontSize: 10, height: 1.4),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: List.generate(
            _dayShort.length,
            (index) => FilterChip(
              label: Text(_dayShort[index]),
              selected: _trainingDays.contains(index),
              onSelected: (selected) => _toggleTrainingDay(index, selected),
              selectedColor: stitchOrange,
              backgroundColor: stitchSurfaceLow,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        if (_loadingPlan) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 2),
        ],
        if (_isPersonal && _athletes.isEmpty && !_loadingPlan)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Cadastre ou vincule um atleta para montar o plano dele.',
              style: TextStyle(color: stitchPeach, fontSize: 10),
            ),
          ),
      ],
    ),
  );

  Widget _dayTabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(_days.length, (index) {
        final selected = _day == index;
        final scheduled = _trainingDays.contains(index);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              '${scheduled ? 'TREINO' : 'ADICIONAR'} ${_dayShort[index]}',
            ),
            selected: selected,
            onSelected: (_) => setState(() {
              if (!scheduled) {
                _trainingDays.add(index);
                final ordered = _trainingDays.toList()..sort();
                _plans[index] = _splitExercises(
                  ordered.indexOf(index),
                ).map(_exercise).toList();
              }
              _day = index;
              _notice = '';
            }),
            selectedColor: stitchOrange,
            backgroundColor: stitchSurface,
            side: BorderSide(color: selected ? stitchOrange : Colors.white10),
            labelStyle: TextStyle(
              color: selected ? stitchOnPrimaryContainer : stitchMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    ),
  );

  Widget _editor({required bool wide}) {
    final exerciseList = _exercises.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'Adicione exercícios à sessão para montar seu treino.',
              textAlign: TextAlign.center,
              style: TextStyle(color: stitchMuted),
            ),
          )
        : ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: _exercises.length,
            onReorder: (oldIndex, newIndex) => setState(() {
              if (newIndex > oldIndex) newIndex--;
              final moved = _exercises.removeAt(oldIndex);
              _exercises.insert(newIndex, moved);
            }),
            itemBuilder: (context, index) => _exerciseTile(index),
          );
    return StitchCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Row(
                children: [
                  Expanded(
                    child: Text(
                      'TREINO ${String.fromCharCode(65 + _day)}  •  ${_days[_day].toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: stitchText,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                  StitchTag('${_exercises.length} EXERCÍCIOS'),
                ],
              );
              final startControl = FilledButton.icon(
                onPressed: _isPersonal
                    ? null
                    : () {
                        final exercises = _exercises
                            .map(
                              (exercise) => Map<String, dynamic>.from(exercise),
                            )
                            .toList();
                        final start = widget.onStartPlannedSession;
                        if (start != null) {
                          start(exercises);
                        } else {
                          widget.onStartSession();
                        }
                      },
                icon: const Icon(Icons.play_arrow, size: 17),
                label: const Text('INICIAR SESSÃO'),
                style: FilledButton.styleFrom(
                  backgroundColor: stitchOrange,
                  foregroundColor: stitchOnPrimaryContainer,
                  textStyle: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
              final controls = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _generatingWithAI ? null : _generateWithAI,
                    icon: _generatingWithAI
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 15),
                    label: Text(_generatingWithAI ? 'GERANDO' : 'GERAR COM IA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: stitchGreen,
                      side: const BorderSide(color: stitchGreen),
                      textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                    ),
                  ),
                  startControl,
                ],
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [title, const SizedBox(height: 8), controls],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  controls,
                ],
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Colors.white12),
          ),
          if (wide)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    exerciseList,
                    const SizedBox(height: 8),
                    _addExerciseAction(),
                  ],
                ),
              ),
            ),
          if (!wide) ...[
            exerciseList,
            const SizedBox(height: 8),
            _addExerciseAction(),
          ],
          if (_notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _notice,
                style: TextStyle(
                  color: _notice.toLowerCase().contains('não foi')
                      ? Colors.orangeAccent
                      : stitchGreen,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addExerciseAction() => OutlinedButton.icon(
    onPressed: _chooseExercise,
    icon: const Icon(Icons.add),
    label: const Text('ADICIONAR EXERCÍCIO'),
    style: OutlinedButton.styleFrom(
      foregroundColor: stitchPeach,
      side: const BorderSide(color: stitchOutline),
    ),
  );
  Widget _exerciseTile(int index) {
    final exercise = _exercises[index];
    return Container(
      key: ValueKey('$_day-${exercise['name']}-$index'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stitchSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_indicator,
                  color: stitchMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: stitchSurfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: stitchPeach,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: stitchText,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StitchTag(
                      exercise['muscle'] ?? 'Geral',
                      color: stitchPeach,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StitchTag('${exercise['sets'] ?? '0'} SÉRIES'),
              PopupMenuButton<String>(
                tooltip: 'Ações do exercício',
                icon: const Icon(Icons.more_vert, color: stitchMuted, size: 19),
                onSelected: (action) {
                  if (action == 'remove') {
                    setState(() => _exercises.removeAt(index));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remover exercício'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withValues(alpha: .07)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _editField('Séries', exercise, 'sets'),
              _editField('Repetições', exercise, 'reps'),
              _editField('Carga (kg)', exercise, 'load'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, Map<String, String> exercise, String field) =>
      SizedBox(
        width: 112,
        child: TextFormField(
          key: ValueKey('$_day-${exercise['name']}-$field'),
          initialValue: exercise[field],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: stitchText,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            filled: true,
            fillColor: stitchSurface,
            labelStyle: const TextStyle(color: stitchMuted, fontSize: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
          onChanged: (value) => setState(() => exercise[field] = value),
        ),
      );
  Widget _side(Map<String, int> muscles) => Column(
    children: [
      Expanded(
        flex: 3,
        child: StitchCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    color: stitchOrange,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: StitchKicker('Análise de volume')),
                  StitchTag(
                    muscles.isEmpty ? 'INICIANDO' : 'ATIVO',
                    color: stitchGreen,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: muscles.isEmpty
                      ? const Center(
                          child: Text(
                            'Adicione exercícios para ver o volume por grupo muscular.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: stitchMuted, fontSize: 10),
                          ),
                        )
                      : Column(
                          children: muscles.entries.map((entry) {
                            final progress = (entry.value / 20).clamp(.04, 1.0);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            color: stitchText,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${entry.value} séries',
                                        style: const TextStyle(
                                          color: stitchPeach,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      color: stitchOrange,
                                      backgroundColor: stitchSurfaceHighest,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: stitchSurfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: stitchGreen, size: 15),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Ajuste o número de séries para equilibrar o volume semanal.',
                        style: TextStyle(
                          color: stitchMuted,
                          fontSize: 9,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        flex: 5,
        child: StitchCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.library_books_outlined,
                    color: stitchGreen,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(child: StitchKicker('Biblioteca rápida')),
                  Text(
                    '${_catalog.length} exercícios',
                    style: const TextStyle(color: stitchMuted, fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) =>
                    setState(() => _libraryQuery = value.trim().toLowerCase()),
                style: const TextStyle(color: stitchText, fontSize: 11),
                decoration: InputDecoration(
                  hintText: 'Filtrar por exercício ou músculo...',
                  hintStyle: const TextStyle(color: stitchMuted, fontSize: 10),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: stitchMuted,
                    size: 17,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: stitchSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final group in const [
                      'Todos',
                      'Peito',
                      'Costas',
                      'Pernas',
                      'Ombros',
                      'Braços',
                      'Core',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text(group.toUpperCase()),
                          selected: (_muscleFilter ?? 'Todos') == group,
                          onSelected: (_) => setState(
                            () =>
                                _muscleFilter = group == 'Todos' ? null : group,
                          ),
                          selectedColor: stitchOrange,
                          backgroundColor: stitchSurfaceLow,
                          side: BorderSide.none,
                          labelStyle: TextStyle(
                            color: (_muscleFilter ?? 'Todos') == group
                                ? stitchOnPrimaryContainer
                                : stitchMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final entries = _catalog.entries.where((entry) {
                      final matchesSearch =
                          _libraryQuery.isEmpty ||
                          entry.key.toLowerCase().contains(_libraryQuery) ||
                          entry.value.toLowerCase().contains(_libraryQuery);
                      final group = _muscleFilter;
                      final muscle = entry.value.toLowerCase();
                      final matchesGroup =
                          group == null ||
                          switch (group) {
                            'Pernas' => [
                              'quadríceps',
                              'posterior',
                              'glúteos',
                              'panturrilhas',
                            ].any(muscle.contains),
                            'Braços' => [
                              'bíceps',
                              'tríceps',
                            ].any(muscle.contains),
                            'Core' => muscle == 'core',
                            _ => muscle.contains(group.toLowerCase()),
                          };
                      return matchesSearch && matchesGroup;
                    }).toList();
                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nenhum exercício encontrado.',
                          style: TextStyle(color: stitchMuted, fontSize: 10),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final item = entries[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          leading: const Icon(
                            Icons.drag_indicator,
                            color: stitchMuted,
                            size: 16,
                          ),
                          title: Text(
                            item.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: stitchText,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          subtitle: StitchKicker(
                            item.value,
                            color: stitchMuted,
                          ),
                          trailing: IconButton(
                            tooltip: 'Adicionar ${item.key}',
                            onPressed: () => _addExercise(item.key),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: stitchOrange,
                              size: 19,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  Future<void> _chooseExercise() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: _catalog.entries
              .map(
                (e) => ListTile(
                  title: Text(e.key),
                  subtitle: Text(e.value),
                  onTap: () => Navigator.pop(context, e.key),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) _addExercise(selected);
  }

  void _import() {
    setState(() {
      _plans[_day] = [
        _exercise('Agachamento livre'),
        _exercise('Leg press 45°'),
        _exercise('Levantamento terra romeno'),
        _exercise('Mesa flexora'),
        _exercise('Panturrilha em pé'),
      ];
    });
  }

  void _export() {
    final text =
        'WEGYM — ${_days[_day]}\n${_exercises
            .map(
              (e) =>
                  '${e['name'] ?? ''}: ${e['sets'] ?? ''} x ${e['reps'] ?? ''} @ ${e['load'] ?? '0'} kg',
            )
            .join('\n')}';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text('Resumo do plano'),
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }
}

/// Owns an active session independently from the currently selected page.
class WorkoutSessionController {
  WorkoutSessionController({this.plannedExercises}) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (running && !saved) elapsed.value++;
    });
  }
  final List<Map<String, dynamic>>? plannedExercises;
  final ValueNotifier<int> elapsed = ValueNotifier<int>(0);
  Timer? _timer;
  bool running = true;
  bool saving = false;
  bool saved = false;
  String notice = '';

  void toggle() {
    if (saving || saved) return;
    running = !running;
    notice = '';
  }

  void dispose() {
    _timer?.cancel();
    elapsed.dispose();
  }
}

/// Active workout screen, separate from the weekly plan editor.
class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({
    super.key,
    required this.preview,
    required this.controller,
    required this.onExit,
  });

  final bool preview;
  final WorkoutSessionController controller;
  final VoidCallback onExit;

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  WorkoutSessionController get _session => widget.controller;
  late final Future<List<Map<String, dynamic>>> _plannedExercises =
      _loadPlannedExercises();

  Future<List<Map<String, dynamic>>> _loadPlannedExercises() async {
    if (_session.plannedExercises != null) return _session.plannedExercises!;
    if (widget.preview) {
      return [
        {
          'name': 'Supino reto com barra',
          'sets': '4',
          'reps': '8–10',
          'load': '80 kg',
        },
        {
          'name': 'Supino inclinado com halteres',
          'sets': '3',
          'reps': '10–12',
          'load': '32 kg',
        },
        {
          'name': 'Crossover na polia',
          'sets': '3',
          'reps': '12–15',
          'load': '20 kg',
        },
        {'name': 'Tríceps corda', 'sets': '4', 'reps': '12', 'load': '40 kg'},
      ];
    }
    try {
      final profile = await Api.profile();
      final athlete = profile['athlete'];
      final athleteId = athlete is Map ? athlete['id']?.toString() : null;
      if (athleteId == null || athleteId.isEmpty) return [];
      final plans = await Api.trainingPlan(athleteId);
      final today = _days[DateTime.now().weekday - 1].toLowerCase();
      final plan = plans.cast<Map<String, dynamic>?>().firstWhere(
        (item) =>
            (item?['day'] ?? item?['weekday'] ?? '').toString().toLowerCase() ==
            today,
        orElse: () => null,
      );
      final exercises = plan?['exercises'];
      if (exercises is! List) return [];
      return exercises
          .whereType<Map>()
          .map(
            (item) => item.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _toggleTimer() {
    setState(_session.toggle);
  }

  Future<void> _finish() async {
    if (_session.elapsed.value < 1) {
      setState(
        () => _session.notice =
            'Registre pelo menos um segundo de treino antes de concluir.',
      );
      return;
    }
    setState(() {
      _session.saving = true;
      _session.running = false;
      _session.notice = '';
    });
    try {
      final exercises = await _plannedExercises;
      if (!widget.preview) {
        await Api.saveSession(_session.elapsed.value, exercises: exercises);
      }
      if (!mounted) return;
      setState(() {
        _session.saved = true;
        _session.notice = widget.preview
            ? 'Prévia: a sessão não foi enviada ao servidor.'
            : 'Treino registrado com sucesso.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _session.running = false;
        _session.notice = 'Não foi possível registrar o treino: $error';
      });
    } finally {
      if (mounted) setState(() => _session.saving = false);
    }
  }

  Future<void> _exit() async {
    if (!_session.saved && _session.elapsed.value > 0) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: stitchSurface,
          title: const Text('Sair do treino?'),
          content: const Text('A sessão em andamento será descartada.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CONTINUAR TREINANDO'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('SAIR SEM SALVAR'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    widget.onExit();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      return ListView(
        padding: EdgeInsets.all(wide ? 24 : 14),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StitchCard(
                    gradient: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: StitchKicker('SESSÃO DE TREINO'),
                            ),
                            TextButton.icon(
                              onPressed: _exit,
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('SAIR'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _session.saved
                              ? 'TREINO CONCLUÍDO'
                              : 'TREINO EM ANDAMENTO',
                          style: const TextStyle(
                            color: stitchText,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'A navegação continua disponível enquanto sua sessão está aberta.',
                          style: TextStyle(color: stitchMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  StitchCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: wide ? 32 : 24,
                    ),
                    child: Column(
                      children: [
                        const StitchKicker('TEMPO DE TREINO'),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _session.elapsed,
                          builder: (context, seconds, _) => Text(
                            formatSessionTime(seconds),
                            style: TextStyle(
                              color: stitchText,
                              fontSize: wide ? 68 : 52,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _session.saved || _session.saving
                                  ? null
                                  : _toggleTimer,
                              icon: Icon(
                                _session.running
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                _session.running ? 'PAUSAR' : 'RETOMAR',
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: _session.saved || _session.saving
                                  ? null
                                  : _finish,
                              icon: _session.saving
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _session.saving
                                    ? 'SALVANDO...'
                                    : 'FINALIZAR E SALVAR',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: stitchOrange,
                                foregroundColor: stitchOnPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        if (_session.notice.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            _session.notice,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _session.saved ? stitchGreen : stitchPeach,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _plannedExercises,
                    builder: (context, snapshot) {
                      final exercises = snapshot.data ?? [];
                      return StitchSection(
                        title: 'EXERCÍCIOS DO TREINO',
                        icon: Icons.fitness_center,
                        child: exercises.isEmpty
                            ? const Text(
                                'Sessão livre: nenhum exercício foi programado para hoje.',
                                style: TextStyle(
                                  color: stitchMuted,
                                  fontSize: 12,
                                ),
                              )
                            : Column(
                                children: exercises.map((exercise) {
                                  final name = (exercise['name'] ?? 'Exercício')
                                      .toString();
                                  final details = [
                                    if (exercise['sets'] != null)
                                      '${exercise['sets']} séries',
                                    if (exercise['reps'] != null)
                                      '${exercise['reps']} repetições',
                                    if (exercise['load'] != null)
                                      '${exercise['load']} kg',
                                  ].join(' • ');
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: stitchSurfaceLow,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.fitness_center,
                                          color: stitchOrange,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  color: stitchText,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              if (details.isNotEmpty)
                                                Text(
                                                  details,
                                                  style: const TextStyle(
                                                    color: stitchMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

String formatSessionTime(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}
