import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'stitch_design_system.dart';

class BleMonitorPage extends StatefulWidget {
  const BleMonitorPage({super.key});

  @override
  State<BleMonitorPage> createState() => _BleMonitorPageState();
}

enum _BlePhase { idle, scanning, connecting, connected, disconnected }

class _BleMonitorPageState extends State<BleMonitorPage> {
  static final _heartRateService = Guid('180D');
  static final _heartRateMeasurement = Guid('2A37');
  static final _batteryService = Guid('180F');
  static final _batteryLevel = Guid('2A19');

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _device;
  final Map<String, ScanResult> _devices = {};
  final List<int> _history = [];
  _BlePhase _phase = _BlePhase.idle;
  int? _bpm;
  int? _battery;
  bool? _sensorContact;
  String _deviceName = '';
  String? _error;

  bool get _scanning => _phase == _BlePhase.scanning;
  bool get _connected => _phase == _BlePhase.connected;

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _connectionSubscription?.cancel();
    final device = _device;
    if (device != null) unawaited(device.disconnect());
    super.dispose();
  }

  Future<void> _scan() async {
    if (_scanning || _phase == _BlePhase.connecting) return;
    setState(() {
      _phase = _BlePhase.scanning;
      _devices.clear();
      _history.clear();
      _bpm = null;
      _battery = null;
      _sensorContact = null;
      _deviceName = '';
      _error = null;
    });

    try {
      if (!kIsWeb) {
        if (!await FlutterBluePlus.isSupported) {
          throw StateError(
            'Este dispositivo não oferece Bluetooth Low Energy.',
          );
        }
        var adapter = await FlutterBluePlus.adapterState
            .where((state) => state != BluetoothAdapterState.unknown)
            .first
            .timeout(const Duration(seconds: 8));
        if (adapter != BluetoothAdapterState.on &&
            defaultTargetPlatform == TargetPlatform.android) {
          await FlutterBluePlus.turnOn();
          adapter = await FlutterBluePlus.adapterState
              .where((state) => state == BluetoothAdapterState.on)
              .first
              .timeout(const Duration(seconds: 12));
        }
        if (adapter != BluetoothAdapterState.on) {
          throw StateError(
            'Ative o Bluetooth e permita o acesso para procurar sensores.',
          );
        }
      }

      final previousScan = _scanSubscription;
      if (previousScan != null) unawaited(previousScan.cancel());
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        _mergeScanResults,
        onError: (Object error) {
          if (mounted) setState(() => _error = _friendlyError(error));
        },
      );
      FlutterBluePlus.cancelWhenScanComplete(_scanSubscription!);

      await FlutterBluePlus.startScan(
        withServices: [_heartRateService],
        timeout: const Duration(seconds: 12),
        webOptionalServices: [_heartRateService, _batteryService, Guid('1800')],
      );
      await FlutterBluePlus.isScanning
          .where((scanning) => !scanning)
          .first
          .timeout(const Duration(seconds: 20));
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted && _scanning) setState(() => _phase = _BlePhase.idle);
    }
  }

  void _mergeScanResults(List<ScanResult> results) {
    if (!mounted || results.isEmpty) return;
    setState(() {
      for (final result in results) {
        _devices[result.device.remoteId.toString()] = result;
      }
    });
  }

  Future<void> _connect(ScanResult result) async {
    if (_phase == _BlePhase.connecting) return;
    setState(() {
      _phase = _BlePhase.connecting;
      _error = null;
    });
    try {
      if (!kIsWeb && FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      final device = result.device;
      _device = device;
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 25),
      );
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (!mounted) return;
        if (state == BluetoothConnectionState.disconnected) {
          _heartRateSubscription?.cancel();
          setState(() {
            _phase = _BlePhase.disconnected;
            _bpm = null;
            _battery = null;
            _sensorContact = null;
          });
        }
      });

      final services = await device.discoverServices();
      BluetoothCharacteristic? measurement;
      BluetoothCharacteristic? batteryCharacteristic;
      for (final service in services) {
        if (service.serviceUuid == _heartRateService) {
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicUuid == _heartRateMeasurement) {
              measurement = characteristic;
            }
          }
        }
        if (service.serviceUuid == _batteryService) {
          for (final characteristic in service.characteristics) {
            if (characteristic.characteristicUuid == _batteryLevel) {
              batteryCharacteristic = characteristic;
            }
          }
        }
      }
      if (measurement == null) {
        throw StateError(
          'O sensor não oferece a medição de frequência cardíaca BLE.',
        );
      }

      _deviceName = result.advertisementData.advName.isNotEmpty
          ? result.advertisementData.advName
          : device.platformName;
      if (batteryCharacteristic != null &&
          batteryCharacteristic.properties.read) {
        try {
          final value = await batteryCharacteristic.read();
          if (value.isNotEmpty) _battery = value.first.clamp(0, 100);
        } catch (_) {
          // A bateria é opcional no perfil BLE.
        }
      }
      await measurement.setNotifyValue(true);
      _heartRateSubscription = measurement.onValueReceived.listen(
        _readHeartRate,
      );
      if (mounted) setState(() => _phase = _BlePhase.connected);
    } catch (error) {
      final device = _device;
      if (device != null) {
        try {
          await device.disconnect();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _phase = _BlePhase.idle;
          _error = _friendlyError(error);
        });
      }
    }
  }

  void _readHeartRate(List<int> value) {
    if (value.length < 2 || !mounted) return;
    final flags = value[0];
    final is16Bit = (flags & 0x01) != 0;
    var offset = 1;
    final bpm = is16Bit
        ? (value[offset] | (value[offset + 1] << 8))
        : value[offset];
    offset += is16Bit ? 2 : 1;
    if ((flags & 0x08) != 0) offset += 2;
    final hasSensorContact = (flags & 0x02) != 0;
    final sensorContact = !hasSensorContact || (flags & 0x04) != 0;
    setState(() {
      _bpm = bpm;
      _sensorContact = sensorContact;
      _history.add(bpm);
      if (_history.length > 60) _history.removeAt(0);
    });
  }

  Future<void> _disconnect() async {
    final device = _device;
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    try {
      await device?.disconnect();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
    if (!mounted) return;
    setState(() {
      _device = null;
      _phase = _BlePhase.idle;
      _bpm = null;
      _battery = null;
      _sensorContact = null;
      _history.clear();
      _deviceName = '';
    });
  }

  Future<void> _stopScan() async {
    if (kIsWeb) return;
    try {
      await FlutterBluePlus.stopScan();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    return message.startsWith('Bad state: ')
        ? message.substring('Bad state: '.length)
        : message;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 820;
      final heartCard = _heartCard();
      final deviceDetails = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_deviceCard(), const SizedBox(height: 14), _historyCard()],
      );
      return ListView(
        padding: EdgeInsets.all(wide ? 24 : 14),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StitchCard(
                    gradient: true,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const StitchKicker(
                          'WEGYM PERFORMANCE OS  \u2022  SENSORES BLE',
                          color: stitchOrange,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'MONITOR CARD\u00cdACO',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: stitchText,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Conecte uma cinta ou sensor BLE e acompanhe seus batimentos em tempo real.',
                          style: TextStyle(color: stitchMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_error != null) ...[
                    _errorCard(_error!),
                    const SizedBox(height: 14),
                  ],
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: heartCard),
                        const SizedBox(width: 14),
                        Expanded(flex: 5, child: deviceDetails),
                      ],
                    )
                  else ...[
                    heartCard,
                    const SizedBox(height: 14),
                    deviceDetails,
                  ],
                  const SizedBox(height: 14),
                  _scanResultsCard(),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _heartCard() => StitchCard(
    padding: const EdgeInsets.all(22),
    child: Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: stitchOrange.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: stitchOrange, size: 46),
        ),
        const SizedBox(height: 14),
        Text(
          _bpm?.toString() ?? '--',
          style: const TextStyle(
            color: stitchOrange,
            fontSize: 64,
            height: 1,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'BATIMENTOS POR MINUTO',
          style: TextStyle(color: stitchMuted, fontSize: 10, letterSpacing: 1),
        ),
        const SizedBox(height: 14),
        _statusChip(),
        if (_connected && _sensorContact != null) ...[
          const SizedBox(height: 8),
          Text(
            _sensorContact!
                ? 'Contato do sensor ativo'
                : 'Confira o contato do sensor',
            style: TextStyle(
              color: _sensorContact! ? stitchGreen : stitchOrange,
              fontSize: 11,
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _connected
                ? _disconnect
                : _scanning
                ? (kIsWeb ? null : _stopScan)
                : _phase == _BlePhase.connecting
                ? null
                : _scan,
            icon: _connected
                ? const Icon(Icons.bluetooth_disabled)
                : _scanning || _phase == _BlePhase.connecting
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(
              _connected
                  ? 'DESCONECTAR SENSOR'
                  : _phase == _BlePhase.connecting
                  ? 'CONECTANDO'
                  : _scanning
                  ? 'PROCURANDO SENSOR'
                  : 'PROCURAR SENSOR BLE',
            ),
          ),
        ),
        if (kIsWeb && _scanning) ...[
          const SizedBox(height: 8),
          const Text(
            'No navegador, escolha um sensor na janela do Bluetooth.',
            textAlign: TextAlign.center,
            style: TextStyle(color: stitchMuted, fontSize: 10),
          ),
        ],
      ],
    ),
  );

  Widget _statusChip() {
    final label = switch (_phase) {
      _BlePhase.idle => 'DESCONECTADO',
      _BlePhase.scanning => 'PROCURANDO',
      _BlePhase.connecting => 'CONECTANDO',
      _BlePhase.connected => 'CONECTADO',
      _BlePhase.disconnected => 'SENSOR DESCONECTADO',
    };
    final color = switch (_phase) {
      _BlePhase.connected => stitchGreen,
      _BlePhase.scanning || _BlePhase.connecting => stitchOrange,
      _ => stitchMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _deviceCard() => StitchCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BleSectionTitle('DISPOSITIVO', Icons.bluetooth),
        const SizedBox(height: 14),
        Text(
          _deviceName.isEmpty ? 'Nenhum sensor conectado' : _deviceName,
          style: const TextStyle(
            color: stitchText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (_connected && _battery != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.battery_std, color: stitchGreen, size: 17),
              const SizedBox(width: 7),
              Text(
                'Bateria: $_battery%',
                style: const TextStyle(color: stitchMuted, fontSize: 12),
              ),
            ],
          ),
        ],
        if (!_connected)
          const Padding(
            padding: EdgeInsets.only(top: 7),
            child: Text(
              'Compatível com sensores que anunciam o serviço Heart Rate (0x180D).',
              style: TextStyle(color: stitchMuted, fontSize: 11, height: 1.35),
            ),
          ),
      ],
    ),
  );

  Widget _historyCard() {
    final sorted = List<int>.of(_history)..sort();
    final min = sorted.isEmpty ? 0 : sorted.first;
    final max = sorted.isEmpty ? 0 : sorted.last;
    final average = sorted.isEmpty
        ? 0
        : (sorted.reduce((left, right) => left + right) / sorted.length)
              .round();
    return StitchCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BleSectionTitle('HISTÓRICO DE BATIMENTOS', Icons.show_chart),
          const SizedBox(height: 14),
          SizedBox(
            height: 88,
            child: _history.length < 2
                ? const Center(
                    child: Text(
                      'Aguardando leituras do sensor...',
                      style: TextStyle(color: stitchMuted, fontSize: 11),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final bpm in _history)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Container(
                              height: (bpm / 220 * 82).clamp(4, 82),
                              decoration: BoxDecoration(
                                color: bpm >= 150
                                    ? const Color(0xFFFF453A)
                                    : bpm >= 110
                                    ? stitchOrange
                                    : stitchGreen,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('MIN', min, stitchGreen),
              _metric('MED', average, stitchOrange),
              _metric('MAX', max, const Color(0xFFFF453A)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value, Color color) => Column(
    children: [
      Text(label, style: const TextStyle(color: stitchMuted, fontSize: 9)),
      const SizedBox(height: 3),
      Text(
        '$value',
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _scanResultsCard() => StitchCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BleSectionTitle(
          'SENSORES POR PERTO',
          Icons.bluetooth_searching,
          trailing: Text(
            '${_devices.length} encontrados',
            style: const TextStyle(color: stitchMuted, fontSize: 10),
          ),
        ),
        const SizedBox(height: 8),
        if (_devices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _scanning
                  ? 'Buscando sensores de frequência cardíaca...'
                  : 'Toque em "Procurar sensor BLE" para encontrar uma cinta compatível.',
              style: const TextStyle(color: stitchMuted, fontSize: 11),
            ),
          )
        else
          ..._devices.values.map((result) {
            final name = result.advertisementData.advName.isNotEmpty
                ? result.advertisementData.advName
                : result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Sensor sem nome';
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: stitchCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: stitchOutline.withValues(alpha: .5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: stitchOrange, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: stitchText,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Sinal ${result.rssi} dBm',
                          style: const TextStyle(
                            color: stitchMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _phase == _BlePhase.connecting
                        ? null
                        : () => _connect(result),
                    child: const Text('CONECTAR'),
                  ),
                ],
              ),
            );
          }),
      ],
    ),
  );

  Widget _errorCard(String message) => StitchCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: stitchOrange, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: stitchPeach, fontSize: 11),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _error = null),
          tooltip: 'Fechar aviso',
          icon: const Icon(Icons.close, size: 16),
        ),
      ],
    ),
  );
}

class _BleSectionTitle extends StatelessWidget {
  const _BleSectionTitle(this.title, this.icon, {this.trailing});

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: stitchOrange, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: stitchPeach,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}
