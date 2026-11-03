import 'package:flutter/material.dart';

import 'pwa_install.dart';
import 'stitch_design_system.dart';

class PwaInstallCard extends StatefulWidget {
  const PwaInstallCard({super.key});

  @override
  State<PwaInstallCard> createState() => _PwaInstallCardState();
}

class _PwaInstallCardState extends State<PwaInstallCard> {
  bool _installable = false;
  bool _standalone = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final values = await Future.wait([canInstallPwa(), isPwaStandalone()]);
    if (!mounted) return;
    setState(() {
      _installable = values[0];
      _standalone = values[1];
      _checking = false;
    });
  }

  Future<void> _install() async {
    if (!_installable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No menu do navegador, escolha Instalar WeGYM ou Adicionar \u00e0 tela inicial.',
          ),
        ),
      );
      return;
    }

    final accepted = await installPwa();
    if (!mounted) return;
    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WeGYM instalado com sucesso.')),
      );
    }
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_standalone || _checking) return const SizedBox.shrink();
    return StitchSection(
      title: 'WEGYM NO SEU DISPOSITIVO',
      icon: Icons.install_mobile,
      child: Material(
        color: stitchSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _install,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.download_for_offline_outlined,
                  color: stitchOrange,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INSTALAR O WEGYM',
                        style: TextStyle(
                          color: stitchText,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Acesse seus treinos como um aplicativo no celular ou computador.',
                        style: TextStyle(
                          color: stitchMuted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _installable ? Icons.install_desktop : Icons.open_in_new,
                  color: stitchOrange,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
