import 'package:flutter/material.dart';

import 'api.dart';
import 'stitch_design_system.dart';

const _previewMode = bool.fromEnvironment('PREVIEW_DASHBOARD');

void showPersonalCopilot(
  BuildContext context, {
  Map<String, dynamic>? student,
}) {
  final child = PersonalCopilotSheet(student: student);
  if (MediaQuery.sizeOf(context).width >= 720) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: stitchSurface,
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(width: 620, height: 620, child: child),
      ),
    );
  } else {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: stitchSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(heightFactor: .88, child: child),
    );
  }
}

class PersonalCopilotSheet extends StatefulWidget {
  const PersonalCopilotSheet({super.key, this.student});

  final Map<String, dynamic>? student;

  @override
  State<PersonalCopilotSheet> createState() => _PersonalCopilotSheetState();
}

class _PersonalCopilotSheetState extends State<PersonalCopilotSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_CopilotMessage>[];
  bool _sending = false;

  String get _studentName => widget.student?['name']?.toString().trim() ?? '';

  String get _studentLevel {
    final raw = widget.student?['experienceLevel']
        ?.toString()
        .trim()
        .toLowerCase();
    switch (raw) {
      case 'intermediario':
      case 'intermediário':
        return 'Intermediário';
      case 'avancado':
      case 'avançado':
        return 'Avançado';
      default:
        return 'Iniciante';
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _input.text.trim();
    if (prompt.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _messages.add(_CopilotMessage.user(prompt));
    });
    _scrollToEnd();

    try {
      final contextLabel = _studentName.isEmpty
          ? ''
          : ' (aluno: $_studentName)';
      final response = await Api.generateAIWorkout(
        message: '[Personal Coach] $prompt$contextLabel',
        level: _studentLevel,
        previewDemo: _previewMode,
      );
      final workout = response['workoutData'] is Map
          ? Map<String, dynamic>.from(response['workoutData'] as Map)
          : <String, dynamic>{};
      final answer = _CopilotMessage.assistant(
        response['text']?.toString() ??
            'O Gemini n\u00e3o retornou uma resposta.',
        exercises: workout['exercises'] is List
            ? List<dynamic>.from(workout['exercises'] as List)
            : const [],
      );
      if (!mounted) return;
      setState(() => _messages.add(answer));
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          _CopilotMessage.assistant(
            'N\u00e3o foi poss\u00edvel consultar o Gemini. Verifique a '
            'conex\u00e3o e a chave configurada no backend. Detalhe: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToEnd();
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: stitchOrange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentName.isEmpty
                          ? 'Gemini IA do Personal'
                          : 'Gemini IA · $_studentName',
                      style: const TextStyle(
                        color: stitchText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Gemini conectado ao backend',
                      style: const TextStyle(color: stitchMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar Gemini',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: stitchMuted),
              ),
            ],
          ),
          const Divider(color: stitchOutline),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.psychology_alt_outlined,
                            color: stitchOrange,
                            size: 38,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _studentName.isEmpty
                                ? 'Pergunte sobre treinos, periodização, recuperação ou acompanhamento.'
                                : 'Peça sugestões considerando o nível e o acompanhamento de $_studentName.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: stitchMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_sending && index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return _messageCard(_messages[index]);
                    },
                  ),
          ),
          const Divider(color: stitchOutline),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('personal-copilot-input'),
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Pergunte sobre treino ou periodização...',
                    filled: true,
                    fillColor: stitchCanvas,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: stitchOutline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: stitchOutline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('personal-copilot-send'),
                tooltip: 'Enviar pergunta',
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(
                  backgroundColor: stitchOrange,
                  foregroundColor: stitchOnPrimaryContainer,
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _messageCard(_CopilotMessage message) => Align(
    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 520),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: message.isUser
            ? stitchOrange.withValues(alpha: .15)
            : stitchCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: stitchOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.isUser ? 'VOCÊ' : 'GEMINI IA',
            style: const TextStyle(
              color: stitchOrange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: const TextStyle(color: stitchText, height: 1.4),
          ),
          if (message.exercises.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final raw in message.exercises)
              if (raw is Map) _exerciseLine(raw),
          ],
        ],
      ),
    ),
  );

  Widget _exerciseLine(Map raw) {
    final name = raw['name']?.toString() ?? 'Exercício';
    final sets = raw['sets']?.toString() ?? '?';
    final reps = raw['reps']?.toString() ?? 'repetições';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        '• $name — $sets séries · $reps',
        style: const TextStyle(color: stitchText, fontSize: 12),
      ),
    );
  }
}

class _CopilotMessage {
  const _CopilotMessage({
    required this.isUser,
    required this.text,
    this.exercises = const [],
  });

  factory _CopilotMessage.user(String text) =>
      _CopilotMessage(isUser: true, text: text);

  factory _CopilotMessage.assistant(
    String text, {
    List<dynamic> exercises = const [],
  }) => _CopilotMessage(isUser: false, text: text, exercises: exercises);

  final bool isUser;
  final String text;
  final List<dynamic> exercises;
}
