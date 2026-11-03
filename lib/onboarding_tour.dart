import 'package:flutter/material.dart';

import 'api.dart';
import 'stitch_design_system.dart';

class _TourStep {
  const _TourStep(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;
}

const _athleteSteps = <_TourStep>[
  _TourStep(
    Icons.fitness_center,
    'Bem-vindo ao WEGYM',
    'Sua plataforma inteligente de treinos: academia, corrida, ciclismo, nata\u00e7\u00e3o e muito mais.',
  ),
  _TourStep(
    Icons.assignment_outlined,
    'Treinos inteligentes',
    'Escolha entre v\u00e1rias modalidades, siga planos semanais e registre cada sess\u00e3o.',
  ),
  _TourStep(
    Icons.auto_awesome,
    'IA e GPS',
    'Use o assistente de IA para gerar treinos personalizados e o GPS para registrar atividades ao ar livre.',
  ),
  _TourStep(
    Icons.insights,
    'Estat\u00edsticas',
    'Acompanhe sua evolu\u00e7\u00e3o, frequ\u00eancia e consist\u00eancia nos treinos.',
  ),
  _TourStep(
    Icons.person_outline,
    'Perfil e WeGYM PRO',
    'Gerencie seus dados, conecte dispositivos compat\u00edveis e conhe\u00e7a os recursos PRO.',
  ),
];

const _personalSteps = <_TourStep>[
  _TourStep(
    Icons.dashboard_outlined,
    'Painel do Personal',
    'Gerencie alunos, planos de treino e hor\u00e1rios em um s\u00f3 lugar.',
  ),
  _TourStep(
    Icons.groups_outlined,
    'Gest\u00e3o de alunos',
    'Cadastre alunos, consulte perfis e acompanhe a evolu\u00e7\u00e3o individual.',
  ),
  _TourStep(
    Icons.auto_awesome,
    'Planos e assistente de IA',
    'Monte fichas personalizadas e use o assistente para criar sugest\u00f5es de treino.',
  ),
  _TourStep(
    Icons.monitor_weight_outlined,
    'Acompanhe a evolu\u00e7\u00e3o',
    'Registre medidas e acompanhe o progresso de cada aluno ao longo do tempo.',
  ),
];

Future<void> showOnboardingIfNeeded(
  BuildContext context, {
  required String role,
}) async {
  try {
    if (await Api.hasCompletedOnboarding()) return;
  } catch (_) {
    // Keep the tour available when secure storage is unavailable.
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => OnboardingTourDialog(role: role),
  );
}

class OnboardingTourDialog extends StatefulWidget {
  const OnboardingTourDialog({super.key, required this.role});

  final String role;

  @override
  State<OnboardingTourDialog> createState() => _OnboardingTourDialogState();
}

class _OnboardingTourDialogState extends State<OnboardingTourDialog> {
  int _stepIndex = 0;
  bool _saving = false;

  List<_TourStep> get _steps =>
      widget.role == 'personal' ? _personalSteps : _athleteSteps;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Api.completeOnboarding();
    } catch (_) {
      // The user can still continue if this device cannot persist preferences.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    final isLast = _stepIndex == _steps.length - 1;
    return PopScope<void>(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: stitchSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .45),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: stitchOrange.withValues(alpha: .14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step.icon, color: stitchOrange, size: 31),
                ),
                const SizedBox(height: 20),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: stitchText,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: stitchMuted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    _steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == _stepIndex ? 20 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _stepIndex
                            ? stitchOrange
                            : stitchSurfaceHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _finish,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: stitchMuted,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text('PULAR'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving
                            ? null
                            : isLast
                            ? _finish
                            : () => setState(() => _stepIndex++),
                        style: FilledButton.styleFrom(
                          backgroundColor: stitchOrange,
                          foregroundColor: stitchOnPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isLast ? 'COME\u00c7AR' : 'PR\u00d3XIMO'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
