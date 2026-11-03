import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'gps_session_page.dart';
import 'training_modalities.dart';
import 'health_platform_integration.dart';
import 'stitch_design_system.dart';

class ModalitySessionPage extends StatefulWidget {
  const ModalitySessionPage({
    super.key,
    this.preview = false,
    this.onSaved,
    this.initialModality = 'swimming',
  });

  final bool preview;
  final VoidCallback? onSaved;
  final String initialModality;

  @override
  State<ModalitySessionPage> createState() => _ModalitySessionPageState();
}

class _ModalitySessionPageState extends State<ModalitySessionPage> {
  static final _modes = <String, (String, IconData)>{
    for (final entry in trainingModalities.entries)
      if (entry.key != 'gym') entry.key: (entry.value.label, entry.value.icon),
  };

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  String _modality = 'swimming';
  int _poolLengthMeters = 25;
  int _laps = 0;
  int _seconds = 0;
  bool _running = false;
  bool _finished = false;
  bool _saving = false;
  String? _notice;
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    if (_modes.containsKey(widget.initialModality)) {
      _modality = widget.initialModality;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _selectModality(String modality) {
    if (_running || _finished) return;
    final gpsActivity = gpsModalityActivities[modality];
    if (gpsActivity != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => GpsSessionPage(
            preview: widget.preview,
            onSaved: widget.onSaved,
            initialActivity: gpsActivity,
          ),
        ),
      );
      return;
    }
    setState(() {
      _modality = modality;
      _notice = null;
    });
  }

  void _startOrResume() {
    if (_finished) return;
    _sessionStartedAt ??= DateTime.now();
    _stopwatch.start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() => _seconds = _stopwatch.elapsed.inSeconds);
    });
    setState(() {
      _running = true;
      _notice = null;
    });
  }

  void _pause() {
    _stopwatch.stop();
    setState(() {
      _running = false;
      _seconds = _stopwatch.elapsed.inSeconds;
    });
  }

  Future<void> _finish() async {
    final elapsed = _stopwatch.elapsed.inSeconds;
    if (elapsed < 1) {
      setState(
        () =>
            _notice = 'Inicie a sess\u00e3o e registre pelo menos um segundo.',
      );
      return;
    }
    _ticker?.cancel();
    _ticker = null;
    _stopwatch.stop();
    setState(() {
      _seconds = elapsed;
      _running = false;
      _finished = true;
      _saving = true;
      _notice = null;
    });

    try {
      if (widget.preview) {
        _notice =
            'Sess\u00e3o demonstrativa conclu\u00edda. Nenhum dado foi enviado.';
      } else {
        await Api.post('/api/workout-sessions', {
          'modality': _modality,
          'durationSec': _seconds,
          if (_modality == 'swimming')
            'distanceKm': _laps * _poolLengthMeters / 1000,
        });
        final startedAt = _sessionStartedAt;
        if (startedAt != null && !Api.hasInjectedRequestHandler) {
          final kind = switch (_modality) {
            'swimming' => NativeWorkoutKind.swimming,
            'combat' => NativeWorkoutKind.martialArts,
            _ => NativeWorkoutKind.other,
          };
          await HealthPlatformIntegration().saveWorkout(
            start: startedAt,
            end: startedAt.add(Duration(seconds: _seconds)),
            kind: kind,
            title: _modes[_modality]?.$1,
            distanceMeters: _modality == 'swimming'
                ? _laps * _poolLengthMeters
                : null,
          );
        }
        _notice = 'Sess\u00e3o salva no hist\u00f3rico.';
      }
      widget.onSaved?.call();
    } catch (error) {
      _notice = 'N\u00e3o foi poss\u00edvel salvar a sess\u00e3o: $error';
      _finished = false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _time {
    final hours = _seconds ~/ 3600;
    final minutes = (_seconds % 3600) ~/ 60;
    final seconds = _seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mode = _modes[_modality]!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('SESS\u00c3O DE ATIVIDADE'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return ListView(
            padding: EdgeInsets.all(compact ? 14 : 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StitchPageHeading(
                        eyebrow: 'TREINO MULTIMODAL',
                        title: mode.$1.toUpperCase(),
                        subtitle:
                            'Registre a dura\u00e7\u00e3o da atividade e acompanhe a sess\u00e3o em tempo real.',
                      ),
                      const SizedBox(height: 14),
                      StitchSection(
                        title: 'ESCOLHA A MODALIDADE',
                        icon: Icons.fitness_center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_modes.length} modalidades dispon\u00edveis',
                              style: const TextStyle(
                                color: stitchMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _modes.entries.map((entry) {
                                final selected = entry.key == _modality;
                                return ChoiceChip(
                                  avatar: Icon(entry.value.$2, size: 17),
                                  label: Text(entry.value.$1),
                                  selected: selected,
                                  onSelected: _running || _finished
                                      ? null
                                      : (_) => _selectModality(entry.key),
                                  selectedColor: stitchOrange,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      StitchSection(
                        title: 'CRON\u00d4METRO',
                        icon: Icons.timer_outlined,
                        child: Column(
                          children: [
                            Text(
                              _time,
                              key: const ValueKey('activity-session-time'),
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono',
                                color: stitchText,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_modality == 'swimming' && !_finished)
                              _swimmingControls(),
                            if (_modality == 'swimming' && _finished)
                              Text(
                                '$_laps voltas  •  ${(_laps * _poolLengthMeters).toString()} m',
                                style: const TextStyle(color: stitchMuted),
                              ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                if (!_finished)
                                  FilledButton.icon(
                                    onPressed: _saving
                                        ? null
                                        : _running
                                        ? _pause
                                        : _startOrResume,
                                    icon: Icon(
                                      _running ? Icons.pause : Icons.play_arrow,
                                    ),
                                    label: Text(
                                      _running ? 'PAUSAR' : 'INICIAR / RETOMAR',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: stitchOrange,
                                      foregroundColor: stitchOnPrimaryContainer,
                                    ),
                                  ),
                                if (!_finished)
                                  OutlinedButton.icon(
                                    onPressed: _saving ? null : _finish,
                                    icon: const Icon(Icons.check),
                                    label: const Text('CONCLUIR E SALVAR'),
                                  ),
                                if (_finished)
                                  FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                    icon: const Icon(Icons.done),
                                    label: const Text('VOLTAR AO TREINO'),
                                  ),
                              ],
                            ),
                            if (_saving) ...[
                              const SizedBox(height: 14),
                              const CircularProgressIndicator(
                                color: stitchOrange,
                              ),
                            ],
                            if (_notice != null) ...[
                              const SizedBox(height: 14),
                              SelectableText(
                                _notice!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: stitchPeach),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const StitchSection(
                        title: 'FREQU\u00caNCIA CARD\u00cdACA',
                        icon: Icons.favorite_outline,
                        child: Text(
                          'Conecte um sensor compat\u00edvel na \u00e1rea Wearables para acompanhar a frequ\u00eancia card\u00edaca. Este registro n\u00e3o inventa dados de sensor.',
                          style: TextStyle(color: stitchMuted, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _swimmingControls() => Wrap(
    spacing: 10,
    runSpacing: 10,
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      DropdownButton<int>(
        value: _poolLengthMeters,
        onChanged: _running || _finished
            ? null
            : (value) {
                if (value != null) setState(() => _poolLengthMeters = value);
              },
        items: const [25, 50]
            .map(
              (meters) => DropdownMenuItem(
                value: meters,
                child: Text('Piscina de $meters m'),
              ),
            )
            .toList(),
      ),
      Text('$_laps voltas  •  ${_laps * _poolLengthMeters} m'),
      OutlinedButton.icon(
        onPressed: _running && !_finished
            ? () => setState(() => _laps++)
            : null,
        icon: const Icon(Icons.add),
        label: const Text('REGISTRAR VOLTA'),
      ),
    ],
  );
}
