import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Desktop preview with switchable web and mobile layouts.
/// Enable it with --dart-define=DEVICE_FRAME_PREVIEW=true.
class DeviceFramePreview extends StatefulWidget {
  const DeviceFramePreview({super.key, required this.child});

  final Widget child;

  static const _enabled = bool.fromEnvironment('DEVICE_FRAME_PREVIEW');
  static const _viewportSize = Size(390, 844);
  static const _frameSize = Size(406, 860);

  @override
  State<DeviceFramePreview> createState() => _DeviceFramePreviewState();
}

class _DeviceFramePreviewState extends State<DeviceFramePreview> {
  bool _mobileSelected = true;
  late DateTime _now;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _clockLabel {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    return '$hour:${_now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!DeviceFramePreview._enabled) return widget.child;

    final hostMedia = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 900.0;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 1000.0;

        // On a real narrow browser/device, keep the app full-screen.
        if (width < 680) return widget.child;

        final scale = math
            .min(
              1.0,
              math.min(
                (width - 32) / DeviceFramePreview._frameSize.width,
                (height - 100) / DeviceFramePreview._frameSize.height,
              ),
            )
            .clamp(0.1, 1.0)
            .toDouble();

        return ColoredBox(
          color: const Color(0xFF101114),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Web'),
                      icon: Icon(Icons.desktop_windows_outlined),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Mobile'),
                      icon: Icon(Icons.smartphone_outlined),
                    ),
                  ],
                  selected: {_mobileSelected},
                  onSelectionChanged: (selection) {
                    setState(() => _mobileSelected = selection.first);
                  },
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? const Color(0xFF111114)
                          : const Color(0xFFE8D6D0);
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      return states.contains(WidgetState.selected)
                          ? const Color(0xFFFF5A0A)
                          : const Color(0xFF1C1C20);
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: Color(0xFF343438)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _mobileSelected
                    ? Center(
                        child: Transform.scale(
                          scale: scale,
                          child: SizedBox(
                            width: DeviceFramePreview._frameSize.width,
                            height: DeviceFramePreview._frameSize.height,
                            child: _buildPhoneFrame(hostMedia),
                          ),
                        ),
                      )
                    : SizedBox.expand(child: widget.child),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneFrame(MediaQueryData hostMedia) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        borderRadius: BorderRadius.circular(46),
        border: Border.all(color: const Color(0xFF39383C), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaQuery(
                data: hostMedia.copyWith(
                  size: DeviceFramePreview._viewportSize,
                  devicePixelRatio: 1,
                  padding: const EdgeInsets.only(top: 28, bottom: 22),
                  viewPadding: const EdgeInsets.only(top: 28, bottom: 22),
                  viewInsets: EdgeInsets.zero,
                ),
                child: ColoredBox(
                  color: const Color(0xFF121214),
                  child: SafeArea(child: widget.child),
                ),
              ),
              Positioned(
                top: 5,
                left: 23,
                right: 23,
                height: 19,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      Text(
                        _clockLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.signal_cellular_alt, size: 12),
                      const SizedBox(width: 4),
                      const Icon(Icons.wifi, size: 12),
                      const SizedBox(width: 4),
                      const Icon(Icons.battery_full, size: 14),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: (DeviceFramePreview._viewportSize.width - 82) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: 82,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF050505),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: (DeviceFramePreview._viewportSize.width - 108) / 2,
                child: IgnorePointer(
                  child: Container(
                    width: 108,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
