import 'package:flutter/material.dart';
import 'api.dart';
import 'stitch_design_system.dart';

class ProgramDetailPage extends StatefulWidget {
  const ProgramDetailPage({
    super.key,
    required this.programId,
    this.initialProgram,
  });

  final String programId;
  final Map<String, dynamic>? initialProgram;

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  late Future<dynamic> _program = _load();

  Future<dynamic> _load() {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      return Future.value(widget.initialProgram ?? <String, dynamic>{});
    }
    return Api.get('/api/programs/${widget.programId}');
  }

  void _retry() => setState(() => _program = _load());

  Map _programData(dynamic value) {
    if (value is! Map) return const {};
    final data = value['data'];
    return data is Map ? data : value;
  }

  Map<String, Map<String, List<Map>>> _groupExercises(List<dynamic> exercises) {
    final weeks = <String, Map<String, List<Map>>>{};
    for (final raw in exercises) {
      if (raw is! Map) continue;
      final exercise = raw;
      final week = exercise['week']?.toString() ?? '1';
      final day = exercise['day']?.toString() ?? '1';
      weeks.putIfAbsent(week, () => <String, List<Map>>{});
      weeks[week]!.putIfAbsent(day, () => <Map>[]).add(exercise);
    }
    return weeks;
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: _program,
    builder: (context, snapshot) {
      final data = snapshot.hasData ? _programData(snapshot.data) : const {};
      final title = _text(data['title'] ?? data['name'], 'PROGRAMA');
      return Scaffold(
        backgroundColor: stitchCanvas,
        appBar: AppBar(
          backgroundColor: stitchCanvas,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: 'Voltar aos programas',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left, color: stitchOrange),
          ),
          title: Text(
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -.45,
            ),
          ),
        ),
        body: _body(snapshot, data),
      );
    },
  );

  Widget _body(AsyncSnapshot<dynamic> snapshot, Map data) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(
        child: CircularProgressIndicator(color: stitchOrange),
      );
    }
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: stitchMuted, size: 28),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar o programa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: stitchMuted),
              ),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('TENTAR NOVAMENTE'),
              ),
            ],
          ),
        ),
      );
    }
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'Programa não encontrado.',
          style: TextStyle(color: stitchMuted),
        ),
      );
    }

    final rawExercises = data['exercises'];
    final exercises = rawExercises is List ? rawExercises : const <dynamic>[];
    final weeks = _groupExercises(exercises);
    final duration = _text(data['durationWeeks'] ?? data['duration'], '—');
    final days = _text(data['daysPerWeek'], '—');
    final level = _text(data['level'], '—');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (const bool.fromEnvironment('PREVIEW_DASHBOARD'))
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stitchOrange.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PR\u00c9VIA \u00b7 DADOS DE DEMONSTRA\u00c7\u00c3O \u00b7 a\u00e7\u00f5es n\u00e3o s\u00e3o salvas.',
                      style: TextStyle(color: stitchMuted, fontSize: 11),
                    ),
                  ),
                Text(
                  _text(data['description']),
                  style: const TextStyle(
                    color: stitchMuted,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$duration semanas  ·  $days×/semana  ·  Nível: $level',
                  style: const TextStyle(
                    color: stitchMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                if (weeks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: stitchSurface.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Text(
                      'Este programa ainda não possui exercícios detalhados.',
                      style: TextStyle(color: stitchMuted),
                    ),
                  )
                else
                  ...weeks.entries.map((week) => _weekCard(week)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekCard(MapEntry<String, Map<String, List<Map>>> week) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: stitchSurface.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SEMANA ${week.key}',
          style: const TextStyle(
            color: stitchOrange,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 14),
        for (final day in week.value.entries) ...[
          Text(
            'DIA ${day.key}',
            style: const TextStyle(
              color: stitchMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 5),
          for (final exercise in day.value) _exerciseRow(exercise),
          if (day.key != week.value.keys.last) const SizedBox(height: 14),
        ],
      ],
    ),
  );

  Widget _exerciseRow(Map exercise) {
    final sets = _text(exercise['sets']);
    final reps = _text(exercise['reps']);
    final duration = _text(exercise['duration']);
    final prescription = [
      if (sets.isNotEmpty && reps.isNotEmpty) '$sets×$reps',
      if (duration.isNotEmpty) duration,
    ].join('  ·  ');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: stitchMuted, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(exercise['name'], 'Exercício'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (prescription.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    prescription,
                    style: const TextStyle(color: stitchMuted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
