import 'package:flutter/material.dart';
import 'api.dart';
import 'stitch_design_system.dart';

class ChallengeLeaderboardPage extends StatefulWidget {
  const ChallengeLeaderboardPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  State<ChallengeLeaderboardPage> createState() =>
      _ChallengeLeaderboardPageState();
}

class _ChallengeLeaderboardPageState extends State<ChallengeLeaderboardPage> {
  late Future<dynamic> _leaderboard = _load();

  Future<dynamic> _load() {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      return Future.value([
        {
          'user': {'displayName': 'Camila Duarte'},
          'currentValue': 2450,
        },
        {
          'user': {'displayName': 'Marcos Silva'},
          'currentValue': 2310,
        },
        {
          'user': {'displayName': 'Ana Souza'},
          'currentValue': 2190,
        },
      ]);
    }
    return Api.get('/api/challenges/${widget.challengeId}/leaderboard');
  }

  void _retry() => setState(() => _leaderboard = _load());

  List<dynamic> _rows(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      final data =
          response['data'] ?? response['leaderboard'] ?? response['rows'];
      if (data is List) return data;
    }
    return const [];
  }

  Map _map(dynamic value) => value is Map ? value : const {};

  String _name(dynamic value) {
    final user = _map(_map(value)['user']);
    final name = user['displayName'] ?? _map(value)['displayName'];
    final text = name?.toString().trim() ?? '';
    return text.isEmpty ? 'Atleta' : text;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: stitchCanvas,
    appBar: AppBar(
      backgroundColor: stitchCanvas,
      scrolledUnderElevation: 0,
      leading: IconButton(
        tooltip: 'Voltar aos desafios',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.chevron_left, color: stitchOrange),
      ),
      title: const Text(
        'RANKING',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -.45,
        ),
      ),
    ),
    body: FutureBuilder<dynamic>(
      future: _leaderboard,
      builder: (context, snapshot) {
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
                    'Não foi possível carregar o ranking.',
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

        final rows = _rows(snapshot.data);
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
                          'PR\u00c9VIA \u00b7 PARTICIPANTES FICT\u00cdCIOS \u00b7 a\u00e7\u00f5es n\u00e3o s\u00e3o salvas.',
                          style: TextStyle(color: stitchMuted, fontSize: 11),
                        ),
                      ),
                    if (rows.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: stitchSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Text(
                          'Ainda não há participantes neste desafio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: stitchMuted),
                        ),
                      )
                    else
                      ...rows.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = _map(entry.value);
                        final value = item['currentValue'] ?? 0;
                        return Container(
                          key: ValueKey('challenge-rank-$index'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: stitchSurface.withValues(alpha: .78),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              _RankBadge(position: index + 1),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _name(item),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$value pontos',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: stitchMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (position) {
      1 => const Color(0xFFFFC928),
      2 => const Color(0xFFB7BEC9),
      3 => const Color(0xFFCD7F32),
      _ => stitchMuted,
    };
    final background = foreground.withValues(alpha: .14);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: position == 1
          ? Icon(Icons.workspace_premium, color: foreground, size: 18)
          : position <= 3
          ? Icon(Icons.military_tech, color: foreground, size: 18)
          : Text(
              '$position',
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
            ),
    );
  }
}
