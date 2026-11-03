import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'api.dart';

class GpsSessionPage extends StatefulWidget {
  const GpsSessionPage({
    super.key,
    this.preview = false,
    this.onSaved,
    this.onBack,
    this.initialActivity = 'Corrida',
  });

  final bool preview;
  final VoidCallback? onSaved;
  final VoidCallback? onBack;
  final String initialActivity;

  @override
  State<GpsSessionPage> createState() => _GpsSessionPageState();
}

enum _GpsPhase { ready, tracking, paused, result }

class _GpsPoint {
  const _GpsPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  Map<String, double> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class _GpsSessionPageState extends State<GpsSessionPage> {
  static const _orange = Color(0xFFFF5A12);
  static const _canvas = Color(0xFF111113);
  static const _surface = Color(0xFF1B1B1E);
  static const _raised = Color(0xFF222225);
  static const _muted = Color(0xFFB9A49C);
  static const _green = Color(0xFF36D97A);
  static const _activities = <String, IconData>{
    'Corrida': Icons.directions_run,
    'Ciclismo': Icons.directions_bike,
    'Caminhada': Icons.directions_walk,
    'Trilha': Icons.terrain,
  };
  static const _targets = <double>[1, 3, 5, 10, 15, 21.1, 42.2];

  final Stopwatch _stopwatch = Stopwatch();
  final List<_GpsPoint> _points = [];
  Timer? _ticker;
  StreamSubscription<Position>? _positionSubscription;
  _GpsPhase _phase = _GpsPhase.ready;
  String _activity = 'Corrida';
  double _targetKm = 5;
  double _distanceMeters = 0;
  int _lastDemoSecond = -1;
  bool _busy = false;
  String? _notice;

  double get _distanceKm => _distanceMeters / 1000;
  int get _durationSeconds => _stopwatch.elapsed.inSeconds;
  int get _paceSecondsPerKm =>
      _distanceKm > 0 ? (_durationSeconds / _distanceKm).round() : 0;
  int get _steps => (_distanceMeters * 1.3).round();

  @override
  void initState() {
    super.initState();
    if (_activities.containsKey(widget.initialActivity)) {
      _activity = widget.initialActivity;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positionSubscription?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  Future<void> _handleBack() async {
    if (_busy) return;
    if (_phase != _GpsPhase.ready) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _surface,
          title: const Text('Sair da atividade?'),
          content: const Text(
            'O percurso atual será descartado se você voltar agora.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CONTINUAR ATIVIDADE'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('DESCARTAR E VOLTAR'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
      _resetToReady();
    }
    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      _resetSession();
      if (widget.preview) {
        _points.add(const _GpsPoint(-23.5505, -46.6333));
        _notice = 'Demonstração: localização simulada; nada será enviado.';
      } else {
        if (!await Geolocator.isLocationServiceEnabled()) {
          throw Exception('Ative a localização do dispositivo para iniciar.');
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw Exception(
            'Permita o acesso à localização para registrar seu percurso.',
          );
        }

        final firstPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 20),
          ),
        );
        _acceptPosition(firstPosition);
        _listenToLocation();
      }
      if (!mounted) return;
      _stopwatch.start();
      _startTicker();
      setState(() => _phase = _GpsPhase.tracking);
    } catch (error) {
      if (mounted) setState(() => _notice = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _listenToLocation() {
    _positionSubscription?.cancel();
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen(
          _acceptPosition,
          onError: (Object error) {
            if (mounted) setState(() => _notice = _friendlyError(error));
          },
        );
  }

  void _acceptPosition(Position position) {
    if (position.accuracy > 60) return;
    final next = _GpsPoint(position.latitude, position.longitude);
    if (_points.isNotEmpty) {
      final previous = _points.last;
      final segment = Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        next.latitude,
        next.longitude,
      );
      if (segment > 0 && segment < 250) _distanceMeters += segment;
    }
    _points.add(next);
    if (_points.length > 2500) _points.removeAt(0);
    if (mounted) setState(() {});
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final seconds = _stopwatch.elapsed.inSeconds;
      if (widget.preview &&
          seconds > 0 &&
          seconds.isEven &&
          seconds != _lastDemoSecond) {
        _lastDemoSecond = seconds;
        _appendDemoPoint();
      }
      setState(() {});
    });
  }

  void _appendDemoPoint() {
    final previous = _points.isEmpty
        ? const _GpsPoint(-23.5505, -46.6333)
        : _points.last;
    final step = _points.length + 1;
    _points.add(
      _GpsPoint(
        previous.latitude + 0.000018,
        previous.longitude + 0.000022 * math.sin(step / 3),
      ),
    );
    _distanceMeters += switch (_activity) {
      'Ciclismo' => 8,
      'Caminhada' || 'Trilha' => 1.2,
      _ => 2.6,
    };
  }

  Future<void> _pause() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _ticker?.cancel();
    _stopwatch.stop();
    if (mounted) setState(() => _phase = _GpsPhase.paused);
  }

  Future<void> _resume() async {
    if (!widget.preview) {
      try {
        if (!await Geolocator.isLocationServiceEnabled()) {
          setState(() => _notice = 'Ative a localização para continuar.');
          return;
        }
        _listenToLocation();
      } catch (error) {
        if (mounted) setState(() => _notice = _friendlyError(error));
        return;
      }
    }
    _stopwatch.start();
    _startTicker();
    if (mounted) setState(() => _phase = _GpsPhase.tracking);
  }

  Future<void> _finish() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _ticker?.cancel();
    _stopwatch.stop();
    if (mounted) setState(() => _phase = _GpsPhase.result);
  }

  Future<void> _save() async {
    if (widget.preview) {
      _showMessage('Sessão demonstrativa concluída. Nenhum dado foi enviado.');
      _resetToReady();
      widget.onSaved?.call();
      return;
    }
    if (_distanceKm <= 0 || _durationSeconds <= 0) {
      _showMessage('Registre um percurso antes de salvar.');
      return;
    }

    setState(() {
      _busy = true;
      _notice = null;
    });
    try {
      final coordinates = _sampleCoordinates();
      await Api.post('/api/gps-sessions', {
        'modality': switch (_activity) {
          'Corrida' => 'running',
          'Ciclismo' => 'cycling',
          'Caminhada' => 'walking',
          'Trilha' => 'hiking',
          _ => 'other',
        },
        'distanceKm': double.parse(_distanceKm.toStringAsFixed(3)),
        'durationSec': _durationSeconds,
        'avgPaceSecPerKm': _paceSecondsPerKm,
        'steps': _steps,
        'coordinates': coordinates.map((point) => point.toJson()).toList(),
      });
      if (!mounted) return;
      widget.onSaved?.call();
      _showMessage('Atividade salva no seu histórico.');
      _resetToReady();
    } catch (error) {
      if (mounted) setState(() => _notice = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<_GpsPoint> _sampleCoordinates() {
    if (_points.length <= 800) return _points;
    final stride = (_points.length / 800).ceil();
    return [
      for (var i = 0; i < _points.length; i += stride) _points[i],
      _points.last,
    ];
  }

  void _discard() => _resetToReady();

  void _resetToReady() {
    _ticker?.cancel();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _stopwatch
      ..stop()
      ..reset();
    if (!mounted) return;
    setState(() {
      _phase = _GpsPhase.ready;
      _points.clear();
      _distanceMeters = 0;
      _lastDemoSecond = -1;
      _notice = null;
    });
  }

  void _resetSession() {
    _ticker?.cancel();
    _positionSubscription?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _points.clear();
    _distanceMeters = 0;
    _lastDemoSecond = -1;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _raised,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(int secondsPerKm) => secondsPerKm <= 0
      ? '--:--'
      : '${secondsPerKm ~/ 60}:'
            '${(secondsPerKm % 60).toString().padLeft(2, '0')}';

  String _decimal(double value, {int digits = 2}) =>
      value.toStringAsFixed(digits).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas,
    body: ColoredBox(
      color: _canvas,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(constraints.maxWidth < 560 ? 16 : 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  if (_notice != null) ...[
                    _noticeBanner(_notice!),
                    const SizedBox(height: 14),
                  ],
                  if (_phase == _GpsPhase.ready) _readyContent(),
                  if (_phase == _GpsPhase.tracking ||
                      _phase == _GpsPhase.paused)
                    _trackingContent(),
                  if (_phase == _GpsPhase.result) _resultContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _header() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .05)),
      gradient: const LinearGradient(
        colors: [Color(0xFF24201F), _surface, Color(0xFF17221D)],
      ),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Voltar',
          onPressed: _busy ? null : _handleBack,
          icon: const Icon(Icons.arrow_back, color: _muted),
        ),
        const SizedBox(width: 4),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.route, color: _orange),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WEGYM PERFORMANCE OS • ATIVIDADE AO AR LIVRE',
                style: TextStyle(
                  color: _orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'RASTREIO GPS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Acompanhe distância, ritmo e duração em tempo real.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _readyContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('ESCOLHA A ATIVIDADE', Icons.tune),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _activities.entries.map((entry) {
                final selected = _activity == entry.key;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _activity = entry.key),
                  avatar: Icon(
                    entry.value,
                    size: 17,
                    color: selected ? Colors.black : _muted,
                  ),
                  label: Text(entry.key.toUpperCase()),
                  selectedColor: _orange,
                  backgroundColor: _raised,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  side: BorderSide(color: selected ? _orange : Colors.white12),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _sectionTitle('DISTÂNCIA ALVO', Icons.flag_outlined),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _targets.map((km) {
                final selected = _targetKm == km;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _targetKm = km),
                  label: Text(
                    '${_decimal(km, digits: km % 1 == 0 ? 0 : 1)} km',
                  ),
                  selectedColor: _orange.withValues(alpha: .2),
                  backgroundColor: _raised,
                  labelStyle: TextStyle(
                    color: selected ? _orange : _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                  side: BorderSide(color: selected ? _orange : Colors.white12),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _routePanel(),
      const SizedBox(height: 14),
      const Row(
        children: [
          Icon(Icons.info_outline, color: _muted, size: 17),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'A localização é usada durante a atividade. Mantenha esta tela aberta.',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: _busy ? null : _start,
          icon: _busy
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_busy ? 'AGUARDANDO LOCALIZAÇÃO' : 'INICIAR ATIVIDADE'),
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _trackingContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _metricsPanel(),
      const SizedBox(height: 14),
      _routePanel(),
      const SizedBox(height: 14),
      if (_phase == _GpsPhase.paused)
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _resume,
            icon: const Icon(Icons.play_arrow),
            label: const Text('RETOMAR'),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.black,
            ),
          ),
        )
      else
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: _pause,
              icon: const Icon(Icons.pause),
              label: const Text('PAUSAR'),
            ),
            FilledButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.stop),
              label: const Text('FINALIZAR'),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
    ],
  );

  Widget _resultContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _metricsPanel(),
      const SizedBox(height: 14),
      _routePanel(),
      const SizedBox(height: 14),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: _discard,
            icon: const Icon(Icons.delete_outline),
            label: const Text('DESCARTAR'),
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: _busy
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_busy ? 'SALVANDO' : 'SALVAR NO HISTÓRICO'),
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    ],
  );

  Widget _metricsPanel() => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / 150).floor().clamp(1, 4).toInt();
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      final metrics = [
        ('DISTÂNCIA', '${_decimal(_distanceKm)} km', Icons.route),
        ('DURAÇÃO', _formatDuration(_durationSeconds), Icons.timer_outlined),
        ('RITMO MÉDIO', '${_formatPace(_paceSecondsPerKm)} /km', Icons.speed),
        ('PASSOS ESTIMADOS', '$_steps', Icons.directions_walk),
      ];
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final metric in metrics)
            SizedBox(
              width: width,
              child: _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(metric.$3, size: 16, color: _orange),
                    const SizedBox(height: 8),
                    Text(
                      metric.$1,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      metric.$2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget _routePanel() => _panel(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.map_outlined, color: _green, size: 17),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'TRAJETO DA ATIVIDADE',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_decimal(_distanceKm)} km',
                style: const TextStyle(
                  color: _orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 238,
          child: CustomPaint(
            painter: _RoutePainter(points: List.of(_points)),
            child: Center(
              child: _points.isEmpty
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: _orange, size: 26),
                        SizedBox(height: 8),
                        Text(
                          'O percurso aparecerá aqui',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String text, IconData icon) => Row(
    children: [
      Icon(icon, size: 16, color: _orange),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .5,
        ),
      ),
    ],
  );

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: .05)),
    ),
    child: child,
  );

  Widget _noticeBanner(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _orange.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _orange.withValues(alpha: .25)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: _orange, size: 16),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.points});

  final List<_GpsPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF151518),
    );
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .045)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude).toDouble();
      maxLat = math.max(maxLat, point.latitude).toDouble();
      minLng = math.min(minLng, point.longitude).toDouble();
      maxLng = math.max(maxLng, point.longitude).toDouble();
    }

    final latSpan = math.max(maxLat - minLat, 0.00002).toDouble();
    final lngSpan = math.max(maxLng - minLng, 0.00002).toDouble();
    const inset = 28.0;
    final routeWidth = size.width - inset * 2;
    final routeHeight = size.height - inset * 2;
    Offset toOffset(_GpsPoint point) => Offset(
      inset + ((point.longitude - minLng) / lngSpan) * routeWidth,
      size.height - inset - ((point.latitude - minLat) / latSpan) * routeHeight,
    );

    final route = Path()
      ..moveTo(toOffset(points.first).dx, toOffset(points.first).dy);
    for (final point in points.skip(1)) {
      final offset = toOffset(point);
      route.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0x5536D97A)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFFFF5A12)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    final start = toOffset(points.first);
    final end = toOffset(points.last);
    canvas.drawCircle(start, 7, Paint()..color = const Color(0xFF36D97A));
    canvas.drawCircle(end, 8, Paint()..color = const Color(0xFFFF5A12));
    canvas.drawCircle(
      end,
      13,
      Paint()
        ..color = const Color(0x55FF5A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.points.isEmpty ||
      oldDelegate.points.last.latitude != points.last.latitude ||
      oldDelegate.points.last.longitude != points.last.longitude;
}
