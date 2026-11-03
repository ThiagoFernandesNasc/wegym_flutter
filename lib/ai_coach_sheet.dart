import 'package:flutter/material.dart';

import 'api.dart';
import 'stitch_design_system.dart';

Future<void> showAiCoachSheet(
  BuildContext context, {
  ValueChanged<List<Map<String, dynamic>>>? onStartWorkout,
}) async {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 720) {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 560,
          height: size.height.clamp(560.0, 760.0).toDouble() * .88,
          child: AiCoachSheet(onStartWorkout: onStartWorkout),
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: .9,
      child: AiCoachSheet(onStartWorkout: onStartWorkout),
    ),
  );
}

class AiCoachSheet extends StatefulWidget {
  const AiCoachSheet({super.key, this.onStartWorkout});

  final ValueChanged<List<Map<String, dynamic>>>? onStartWorkout;

  @override
  State<AiCoachSheet> createState() => _AiCoachSheetState();
}

class _AiCoachSheetState extends State<AiCoachSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_CoachMessage> _messages = [];
  String _level = 'Intermediário';
  bool _sending = false;

  static const _isPreview = bool.fromEnvironment('PREVIEW_DASHBOARD');

  static const _suggestions = [
    'Monte um treino de peito e tríceps',
    'Sugira um treino de pernas para iniciante',
    'Quero ganhar força em 45 minutos',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedPrompt]) async {
    final prompt = (suggestedPrompt ?? _input.text).trim();
    if (prompt.isEmpty || _sending) return;

    setState(() {
      _messages.add(_CoachMessage.user(prompt));
      _input.clear();
      _sending = true;
    });
    _scrollToLatest();

    try {
      final result = await Api.generateAIWorkout(
        message: prompt,
        level: _level,
        previewDemo: _isPreview,
      );
      final rawWorkout = result['workoutData'];
      final rawExercises = rawWorkout is Map ? rawWorkout['exercises'] : null;
      final exercises = rawExercises is List
          ? rawExercises.whereType<Map>().map((row) {
              return <String, String>{
                'name': row['name']?.toString() ?? 'Exercício',
                'sets': row['sets']?.toString() ?? '3',
                'reps': row['reps']?.toString() ?? '10',
                'load': row['load']?.toString() ?? '',
              };
            }).toList()
          : <Map<String, String>>[];

      if (!mounted) return;
      setState(() {
        _messages.add(
          _CoachMessage.assistant(
            (result['text'] ?? 'Sugestão de treino gerada.').toString(),
            exercises,
          ),
        );
        _sending = false;
      });
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiResponseException
          ? error.message
          : 'N\u00e3o consegui consultar o Gemini. Confira a conex\u00e3o e a chave do backend.';
      setState(() {
        _messages.add(_CoachMessage.assistant(message));
        _sending = false;
      });
    }
    _scrollToLatest();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: stitchSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: stitchOutline.withValues(alpha: .72)),
    ),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: stitchOrange.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: stitchOrange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSISTENTE IA WEGYM',
                        style: TextStyle(
                          color: stitchText,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'GEMINI \u2022 SUGEST\u00d5ES DE TREINO',
                        style: TextStyle(
                          color: stitchMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar assistente',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: stitchMuted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(
                labelText: 'Nível de treino',
                prefixIcon: Icon(Icons.trending_up),
                isDense: true,
              ),
              items: const ['Iniciante', 'Intermediário', 'Avançado']
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: _sending
                  ? null
                  : (value) {
                      if (value != null) setState(() => _level = value);
                    },
            ),
          ),
          const Divider(height: 1, color: stitchOutline),
          Expanded(
            child: _messages.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: stitchOrange,
                              ),
                            ),
                          ),
                        );
                      }
                      return _bubble(_messages[index]);
                    },
                  ),
          ),
          const Divider(height: 1, color: stitchOutline),
          Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              10,
              14,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _send(value),
                    decoration: const InputDecoration(
                      hintText: 'Descreva seu objetivo de treino...',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar mensagem',
                  onPressed: _sending ? null : () => _send(),
                  style: IconButton.styleFrom(
                    backgroundColor: stitchOrange,
                    foregroundColor: stitchOnPrimaryContainer,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyState() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const SizedBox(height: 20),
      const Icon(Icons.fitness_center, color: stitchOrange, size: 36),
      const SizedBox(height: 12),
      const Text(
        'Planeje seu próximo treino',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: stitchText,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Conte seu objetivo e receba uma sugestão baseada no seu nível.',
        textAlign: TextAlign.center,
        style: TextStyle(color: stitchMuted, fontSize: 12, height: 1.4),
      ),
      const SizedBox(height: 18),
      for (final prompt in _suggestions)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: _sending ? null : () => _send(prompt),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              side: const BorderSide(color: stitchOutline),
              foregroundColor: stitchPeach,
            ),
            child: Text(prompt),
          ),
        ),
    ],
  );

  Widget _bubble(_CoachMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isUser ? stitchOrange : stitchSurfaceLow,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isUser ? stitchOnPrimaryContainer : stitchText,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              if (message.exercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final exercise in message.exercises)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: stitchCanvas.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fitness_center,
                          color: stitchOrange,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise['name'] ?? 'Exercício',
                                style: const TextStyle(
                                  color: stitchText,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exercise['sets'] ?? '3'} s\u00e9ries \u2022 ${exercise['reps'] ?? '10'} repeti\u00e7\u00f5es${(exercise['load'] ?? '').isEmpty ? '' : ' \u2022 ${exercise['load']}'}',
                                style: const TextStyle(
                                  color: stitchMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (!isUser &&
                  message.exercises.isNotEmpty &&
                  widget.onStartWorkout != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final onStartWorkout = widget.onStartWorkout;
                      if (onStartWorkout == null) return;
                      final exercises = message.exercises
                          .map(
                            (exercise) => Map<String, dynamic>.from(exercise),
                          )
                          .toList();
                      Navigator.of(context).pop();
                      onStartWorkout(exercises);
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('INICIAR TREINO SUGERIDO'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachMessage {
  const _CoachMessage._(this.text, this.isUser, this.exercises);

  factory _CoachMessage.user(String text) =>
      _CoachMessage._(text, true, const []);

  factory _CoachMessage.assistant(
    String text, [
    List<Map<String, String>> exercises = const [],
  ]) => _CoachMessage._(text, false, exercises);

  final String text;
  final bool isUser;
  final List<Map<String, String>> exercises;
}
