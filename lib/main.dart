import 'dart:async';
import 'package:flutter/material.dart';
import 'api.dart';
import 'dashboard.dart';
import 'workout_builder.dart';
import 'figma_modules.dart';
import 'stitch_design_system.dart';

const background = stitchCanvas;
const surface = stitchSurface;
const accent = stitchOrange;
const lightText = stitchText;
const softText = stitchMuted;
const positive = stitchGreen;
const appModules = <int, String>{
  3: 'Comunidade',
  4: 'Analytics & Performance',
  5: 'Agendamentos',
  6: 'Nutrição',
  7: 'Alunos & Personal',
  8: 'Metas & Desafios',
  9: 'Programas',
  10: 'Chat',
  11: 'Perfil & Configurações',
  12: 'Planos PRO',
  13: 'Medidas',
  14: 'Check-in',
  15: 'Amigos',
  16: 'Aulas',
};

void main() => runApp(const WegymApp());

class WegymApp extends StatelessWidget {
  const WegymApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WEGYM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: positive,
          tertiary: stitchBlue,
          surface: surface,
          onSurface: lightText,
        ),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<String?> _token = Api.token();
  String? _demoRole;
  bool _loadingDemoRole = const bool.fromEnvironment('PREVIEW_DASHBOARD');

  @override
  void initState() {
    super.initState();
    if (_loadingDemoRole) _restoreDemoRole();
  }

  Future<void> _restoreDemoRole() async {
    String? savedRole;
    try {
      savedRole = await Api.previewRole();
    } catch (_) {
      // A prévia continua abrindo mesmo se o navegador bloquear o armazenamento.
    }
    if (!mounted) return;
    setState(() {
      _demoRole = savedRole;
      _loadingDemoRole = false;
    });
  }

  void _refresh() => setState(() => _token = Api.token());
  @override
  Widget build(BuildContext context) {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      if (_loadingDemoRole) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: accent)),
        );
      }
      final role = _demoRole;
      if (role == null) {
        return LoginPage(
          onLogin: (selectedRole) async {
            try {
              await Api.setPreviewRole(selectedRole);
              await Api.setRegisterMode(false);
            } catch (_) {
              // A navegação de demonstração não depende de armazenamento local.
            }
            if (mounted) setState(() => _demoRole = selectedRole);
          },
        );
      }
      return AppShell(
        demoRole: role,
        onLogout: () {
          unawaited(Api.clearPreviewState());
          if (mounted) setState(() => _demoRole = null);
        },
      );
    }
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if ((snapshot.data ?? '').isEmpty) {
          return LoginPage(onLogin: (_) => _refresh());
        }
        return AppShell(onLogout: _refresh);
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});
  final ValueChanged<String> onLogin;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _pageScroll = ScrollController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _credential = TextEditingController();
  bool _busy = false;
  bool _register = false;
  bool _remember = true;
  bool _acceptTerms = false;
  bool _showPassword = false;
  String _userType = 'atleta';
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      Api.registerMode()
          .then((savedMode) {
            if (mounted && savedMode != null) {
              setState(() => _register = savedMode);
            }
          })
          .catchError((_) {});
    }
  }

  void _setRegisterMode(bool register) {
    setState(() {
      _register = register;
      _error = '';
    });
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      unawaited(Api.setRegisterMode(register).catchError((_) {}));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageScroll.hasClients) {
        _pageScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  static const _demoPassword = '123456';

  void _fillDemoAccount(String role) {
    setState(() {
      _userType = role;
      _email.text = role == 'personal'
          ? 'personal@wegym.com.br'
          : 'joao@wegym.com.br';
      _password.text = _demoPassword;
      _error = '';
    });
  }

  Future<void> _submit() async {
    if (_register && !_acceptTerms) {
      setState(
        () => _error =
            'Aceite os Termos de Uso e a Política de Privacidade para continuar.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      if (_register) {
        await Api.register({
          'email': _email.text.trim(),
          'password': _password.text,
          'userType': _userType,
          'name': _name.text.trim(),
          if (_userType == 'personal') 'cref': _credential.text.trim(),
          if (_userType == 'atleta') 'cpf': _credential.text.trim(),
          'termsAccepted': true,
          'privacyAccepted': true,
        });
        setState(() {
          _register = false;
          _error = 'Cadastro concluído. Entre com sua conta.';
        });
        return;
      }
      if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
        final email = _email.text.trim().toLowerCase();
        final role = switch (email) {
          'joao@wegym.com.br' => 'atleta',
          'personal@wegym.com.br' => 'personal',
          _ => null,
        };
        if (role == null || _password.text != _demoPassword) {
          throw Exception(
            'Use um dos acessos de demonstração exibidos abaixo.',
          );
        }
        try {
          await Api.login(email, _password.text);
        } catch (_) {
          // A prévia de apresentação deve abrir mesmo sem o Next.js local.
          // As credenciais já foram validadas contra as contas de demonstração acima.
          await Api.logout();
        }
        widget.onLogin(role);
        return;
      }
      await Api.login(_email.text.trim(), _password.text);
      widget.onLogin(_userType);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _pageScroll.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _credential.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    TextInputType? keyboard,
    bool externalLabel = false,
    String? hint,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    obscureText: secret && !_showPassword,
    style: const TextStyle(color: lightText),
    decoration: InputDecoration(
      labelText: externalLabel ? null : label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF77747A), fontSize: 12),
      labelStyle: const TextStyle(color: softText, fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF111114),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(
        secret
            ? Icons.lock_outline
            : label == 'E-mail'
            ? Icons.alternate_email
            : Icons.badge_outlined,
        color: softText,
        size: 18,
      ),
      suffixIcon: secret
          ? IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: accent, width: 1.3),
      ),
    ),
    validator: (value) {
      final text = value?.trim() ?? '';
      if (secret && text.length < (_register ? 8 : 6)) {
        return _register
            ? 'Use pelo menos 8 caracteres.'
            : 'Informe sua senha.';
      }
      if (!secret && label == 'E-mail' && !text.contains('@')) {
        return 'Informe um e-mail válido.';
      }
      if (_register && label == 'Nome' && text.length < 3) {
        return 'Informe seu nome completo.';
      }
      if (_register && label == 'CPF / CREF' && text.isEmpty) {
        return 'Informe seu CPF ou CREF.';
      }
      return null;
    },
  );

  Future<void> _recover() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Digite seu e-mail para receber a recuperação.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    try {
      await Api.forgotPassword(email);
      if (mounted) {
        setState(
          () => _error =
              'Se a conta existir, enviaremos as instruções de recuperação.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPasswordWithToken() async {
    final token = TextEditingController();
    final password = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Redefinir senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: token,
              decoration: const InputDecoration(
                labelText: 'Token recebido no e-mail',
              ),
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nova senha (mínimo 8 caracteres)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, [token.text.trim(), password.text]),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
    if (values == null) {
      token.dispose();
      password.dispose();
      return;
    }
    try {
      if (values[0].isEmpty || values[1].length < 8) {
        throw Exception(
          'Informe um token válido e uma senha com pelo menos 8 caracteres.',
        );
      }
      await Api.post('/api/auth/reset-password', {
        'token': values[0],
        'password': values[1],
      });
      if (mounted) {
        setState(() => _error = 'Senha redefinida. Entre com sua nova senha.');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      token.dispose();
      password.dispose();
    }
  }

  Widget _roleAccessSelector() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFF101013),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: Colors.white.withValues(alpha: .05)),
    ),
    child: Row(
      children: [
        _roleAccessOption('atleta', 'SOU ATLETA', Icons.fitness_center),
        _roleAccessOption('personal', 'COACH / TRAINER', Icons.sports),
      ],
    ),
  );

  Widget _roleAccessOption(String role, String label, IconData icon) {
    final selected = _userType == role;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
            _fillDemoAccount(role);
          } else {
            setState(() => _userType = role);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: .2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? stitchOnPrimaryContainer : softText,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? stitchOnPrimaryContainer : softText,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginFieldLabel(String label, {String? trailing}) => Padding(
    padding: const EdgeInsets.only(left: 3, bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: softText,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .55,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
      ],
    ),
  );

  void _showUnavailableSignIn(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider ainda não está conectado ao backend.')),
    );
  }

  Widget _providerButton(String label, IconData icon, Color color) => Expanded(
    child: OutlinedButton.icon(
      onPressed: () => _showUnavailableSignIn(label),
      icon: Icon(icon, color: color, size: 17),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        backgroundColor: const Color(0xFF202024),
        side: BorderSide(color: Colors.white.withValues(alpha: .035)),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _loginForm() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF19191D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_register) ...[
              _roleAccessSelector(),
              const SizedBox(height: 18),
            ],
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: const [
                Tag('PORTAL DO ATLETA WEGYM'),
                Text(
                  'AUTH V2.4',
                  style: TextStyle(
                    color: softText,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _register ? 'CRIE SUA CONTA' : 'ENTRE NO WEGYM OS',
              style: const TextStyle(
                color: lightText,
                fontSize: 29,
                height: 1.05,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _register
                  ? 'Comece seu acompanhamento no WeGYM.'
                  : 'Use suas credenciais para sincronizar sua carga de treino.',
              style: const TextStyle(
                color: softText,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            if (!_register) ...[
              const SizedBox(height: 12),
              const Text(
                'Escolha o perfil de acesso e use os dados da conta correspondente.',
                style: TextStyle(color: softText, fontSize: 11),
              ),
            ],
            if (!_register) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  _providerButton(
                    'Google Account',
                    Icons.g_mobiledata,
                    Colors.lightBlue,
                  ),
                  const SizedBox(width: 10),
                  _providerButton('Apple ID', Icons.apple, lightText),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white12)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OU COM IDENTIFICAÇÃO WEGYM',
                      style: TextStyle(
                        color: softText,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white12)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_register) ...[
              _field(_name, 'Nome'),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'atleta', label: Text('Atleta')),
                  ButtonSegment(value: 'personal', label: Text('Personal')),
                ],
                selected: {_userType},
                onSelectionChanged: (v) => setState(() => _userType = v.first),
              ),
              const SizedBox(height: 10),
              _field(_credential, 'CPF / CREF'),
              const SizedBox(height: 10),
            ],
            if (!_register)
              _loginFieldLabel(
                'E-MAIL INSTITUCIONAL OU MATRÍCULA',
                trailing: '#WG-CODE',
              ),
            _field(
              _email,
              'E-mail',
              keyboard: TextInputType.emailAddress,
              externalLabel: !_register,
              hint: _register ? null : 'ex.: nome@atleta.com ou #WG-9842',
            ),
            const SizedBox(height: 10),
            if (!_register) _loginFieldLabel('CHAVE DE ACESSO / SENHA'),
            _field(
              _password,
              'Senha',
              secret: true,
              externalLabel: !_register,
              hint: _register ? null : '••••••••••••',
            ),
            if (!_register)
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    activeColor: accent,
                    onChanged: (v) => setState(() => _remember = v ?? true),
                  ),
                  const Expanded(
                    child: Text(
                      'Permanecer conectado',
                      style: TextStyle(color: softText, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _recover,
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            if (!_register &&
                (_error.startsWith('Se a conta') ||
                    _error.startsWith('Exception: Token')))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _resetPasswordWithToken,
                  child: const Text('Já tenho o token de redefinição'),
                ),
              ),
            if (_register)
              CheckboxListTile(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: accent,
                title: const Text(
                  'Aceito os Termos de Uso e a Política de Privacidade',
                  style: TextStyle(color: softText, fontSize: 10),
                ),
              ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error,
                  style: TextStyle(
                    color:
                        _error.startsWith('Se a conta') ||
                            _error.startsWith('Cadastro')
                        ? positive
                        : Colors.redAccent,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_register ? Icons.person_add_alt_1 : Icons.bolt),
                label: Text(_register ? 'CRIAR CONTA' : 'ENTRAR NO WEGYM OS'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: stitchOnPrimaryContainer,
                  elevation: 8,
                  shadowColor: accent.withValues(alpha: .28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            if (!_register) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => _showUnavailableSignIn('Passkey / biometria'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: lightText,
                  backgroundColor: const Color(0xFF101013),
                  side: BorderSide(color: Colors.white.withValues(alpha: .05)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.fingerprint, color: positive, size: 21),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passkey / Biometria Facial',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'FIDO2 WebAuthn compatível',
                            style: TextStyle(color: softText, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'USAR CHAVE',
                      style: TextStyle(
                        color: softText,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    leading: const Icon(
                      Icons.desktop_windows_outlined,
                      color: softText,
                      size: 16,
                    ),
                    title: const Text(
                      'Primeiro acesso na academia?',
                      style: TextStyle(
                        color: softText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Crie seu perfil para começar a usar o WeGYM.',
                          style: TextStyle(color: softText, fontSize: 10),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () => _setRegisterMode(true),
                          child: const Text('CRIAR CONTA'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(color: Colors.white12),
            if (!_register &&
                const bool.fromEnvironment('PREVIEW_DASHBOARD')) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACESSOS PARA DEMONSTRAÇÃO',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _demoCredentialCard(
                    'ATLETA',
                    'joao@wegym.com.br',
                    onTap: () => _fillDemoAccount('atleta'),
                  ),
                  _demoCredentialCard(
                    'PERSONAL',
                    'personal@wegym.com.br',
                    onTap: () => _fillDemoAccount('personal'),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Senha para ambas as contas: 123456',
                  style: TextStyle(color: softText, fontSize: 10),
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'E2E • LGPD',
                  style: TextStyle(color: softText, fontSize: 9),
                ),
                Text(
                  'TERMOS  •  PRIVACIDADE',
                  style: TextStyle(color: softText, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _demoCredentialCard(
    String role,
    String email, {
    required VoidCallback onTap,
  }) => ActionChip(
    avatar: Icon(
      role == 'PERSONAL' ? Icons.fitness_center : Icons.person_outline,
      color: accent,
      size: 16,
    ),
    label: Text('$role  •  $email', style: const TextStyle(fontSize: 10)),
    onPressed: onTap,
    backgroundColor: stitchSidebar,
    side: const BorderSide(color: Colors.white12),
  );

  Widget _loginStatusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: positive.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: positive.withValues(alpha: .18)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 7, color: positive),
        SizedBox(width: 6),
        Text(
          'ACESSO SEGURO',
          style: TextStyle(
            color: positive,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
      ],
    ),
  );

  Widget _storyPanel() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF252326), Color(0xFF151518), Color(0xFF121A19)],
      ),
    ),
    padding: const EdgeInsets.fromLTRB(34, 30, 34, 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Brand(),
        const SizedBox(height: 38),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: positive.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: positive.withValues(alpha: .22)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: positive, size: 8),
              SizedBox(width: 8),
              Text(
                'ECOSSISTEMA ONLINE  •  RTT 18MS',
                style: TextStyle(
                  color: positive,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'MOTOR DE ALTA PERFORMANCE',
          style: TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 9),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'A TECNOLOGIA QUE\nTRANSFORMA SUOR\nEM DADOS '),
              TextSpan(
                text: 'MILIMÉTRICOS.',
                style: TextStyle(color: accent),
              ),
            ],
          ),
          style: TextStyle(
            color: lightText,
            fontSize: 30,
            height: 1.02,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Algoritmos de periodização, telemetria muscular e sincronização em tempo real para atletas e treinadores.',
          style: TextStyle(color: softText, fontSize: 13, height: 1.6),
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .07)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Color(0x29F66018),
                child: Icon(Icons.fitness_center, color: accent, size: 21),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '142 atletas ativos',
                      style: TextStyle(
                        color: lightText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Evolução acompanhada em tempo real',
                      style: TextStyle(color: softText, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+14,2%',
                    style: TextStyle(
                      color: positive,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Icon(Icons.show_chart, color: positive, size: 22),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .045),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: .045)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF101013),
                child: Icon(Icons.person, color: stitchPeach, size: 19),
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"Cada treino vira evolu\u00e7\u00e3o."',
                      style: TextStyle(
                        color: lightText,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'MARCOS VIANNA  •  HEAD COACH',
                      style: TextStyle(
                        color: accent,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const Divider(color: Colors.white12),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.shield_outlined, color: positive, size: 15),
            SizedBox(width: 8),
            Text(
              'ACESSO SEGURO  •  PRIVACIDADE PROTEGIDA',
              style: TextStyle(
                color: softText,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 850;
          return Stack(
            children: [
              Positioned(
                top: -180,
                right: -130,
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: .045),
                  ),
                ),
              ),
              Positioned(
                bottom: -220,
                left: -170,
                child: Container(
                  width: 460,
                  height: 460,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: positive.withValues(alpha: .035),
                  ),
                ),
              ),
              SingleChildScrollView(
                controller: _pageScroll,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1260),
                    child: Padding(
                      padding: EdgeInsets.all(wide ? 28 : 14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xCC17171A),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .38),
                              blurRadius: 50,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: wide
                            ? IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(flex: 5, child: _storyPanel()),
                                    const SizedBox(width: 10),
                                    Expanded(flex: 7, child: _loginForm()),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      10,
                                      12,
                                      18,
                                    ),
                                    child: Row(
                                      children: [
                                        const Brand(),
                                        const Spacer(),
                                        if (!_register) _loginStatusBadge(),
                                      ],
                                    ),
                                  ),
                                  _loginForm(),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_register)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: const Color(0xFF242428),
                    borderRadius: BorderRadius.circular(12),
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => _setRegisterMode(false),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('VOLTAR AO LOGIN'),
                      style: TextButton.styleFrom(
                        foregroundColor: lightText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onLogout, this.demoRole});
  final VoidCallback onLogout;
  final String? demoRole;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final List<int> _navigationHistory = <int>[];
  int _revision = 0;
  int _sessionRevision = 0;
  String? _role;
  WorkoutSessionController? _sessionController;
  final _globalSearch = TextEditingController();
  late Future<List<dynamic>> _data = _load();

  @override
  void initState() {
    super.initState();
    _role = widget.demoRole;
    _restoreNavigation();
  }

  Future<void> _restoreNavigation() async {
    try {
      await _data;
      final saved = await Api.navigationState();
      if (!mounted || saved == null) return;
      final index = int.tryParse(saved['index']?.toString() ?? '');
      final rawHistory = saved['history'];
      final history = rawHistory is List
          ? rawHistory
                .map((item) => int.tryParse(item.toString()))
                .whereType<int>()
                .toList()
          : <int>[];
      const validPages = <int>{
        0,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
      };
      if (index == null || !validPages.contains(index)) return;
      if (index == 7 && _role != 'personal') return;
      setState(() {
        _index = index;
        _navigationHistory
          ..clear()
          ..addAll(history.where((page) => validPages.contains(page)));
        if (index == 17 && _sessionController == null) {
          _sessionController = WorkoutSessionController();
          _sessionRevision++;
        }
      });
    } catch (_) {
      // Se o estado local estiver indisponível, o app permanece na tela inicial.
    }
  }

  void _saveNavigationState() {
    unawaited(
      Api.saveNavigationState(
        _index,
        List<int>.of(_navigationHistory),
      ).catchError((_) {}),
    );
  }

  Map<int, String> get _visibleModules => Map.fromEntries(
    appModules.entries.where((entry) => entry.key != 7 || _role == 'personal'),
  );

  void _setRole(dynamic role) {
    final nextRole = role?.toString();
    if (_role == nextRole) return;
    _role = nextRole;
    if (mounted) setState(() {});
  }

  Future<List<dynamic>> _load() async {
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      final demoRole = widget.demoRole ?? 'atleta';
      _role = demoRole;
      final now = DateTime.now();
      final day = const [
        'Seg',
        'Ter',
        'Qua',
        'Qui',
        'Sex',
        'Sáb',
        'Dom',
      ][now.weekday - 1];
      final sessions = List<Map<String, dynamic>>.generate(
        5,
        (i) => {
          'id': 'preview-$i',
          'modality': i.isEven ? 'musculacao' : 'corrida',
          'durationSec': 2700 + i * 180,
          'completedAt': now.subtract(Duration(days: i * 2)).toIso8601String(),
        },
      );
      return [
        {
          'id': 'preview-user',
          'email': demoRole == 'personal'
              ? 'personal@wegym.com.br'
              : 'joao@wegym.com.br',
          'role': demoRole,
          if (demoRole == 'personal')
            'personal': {'id': 'preview-personal', 'name': 'Carlos Personal'}
          else
            'athlete': {
              'id': 'preview-athlete',
              'name': 'João Silva',
              'experienceLevel': 'intermediate',
            },
        },
        {
          'totalSessions': 4,
          'totalVolume': 14280,
          'totalCalories': 2140,
          'totalDistance': 8.4,
          'avgHeartRate': 142,
        },
        {
          'totalSessions': 18,
          'totalVolume': 57000,
          'totalCalories': 14200,
          'totalDistance': 32.6,
          'avgHeartRate': 139,
        },
        sessions,
        [
          {
            'day': day,
            'exercises': [
              {
                'name': 'Supino Reto Barra',
                'sets': '4',
                'reps': '8-10',
                'load': '80 kg',
              },
              {
                'name': 'Supino Inclinado Halteres',
                'sets': '3',
                'reps': '10-12',
                'load': '32 kg',
              },
              {
                'name': 'Crossover Polia Média',
                'sets': '3',
                'reps': '12-15',
                'load': '20 kg',
              },
              {
                'name': 'Tríceps Corda',
                'sets': '4',
                'reps': '12',
                'load': '40 kg',
              },
            ],
          },
        ],
        {
          'posts': [
            {
              'text': 'Novo recorde no levantamento terra: 140 kg!',
              'createdAt': now.toIso8601String(),
              'user': {'displayName': 'Camila Duarte'},
            },
            {
              'text': 'Treino de pernas concluído. Bora manter a consistência!',
              'createdAt': now
                  .subtract(const Duration(hours: 1))
                  .toIso8601String(),
              'user': {'displayName': 'Marcos Silva'},
            },
          ],
        },
      ];
    }
    final profile = await Api.profile();
    _setRole(profile['role']);
    if (profile['role'] == 'personal') {
      final feed = Api.feed().catchError((_) => <String, dynamic>{'posts': []});
      return [
        profile,
        <String, dynamic>{},
        <String, dynamic>{},
        <Map<String, dynamic>>[],
        <Map<String, dynamic>>[],
        await feed,
      ];
    }
    final athlete = profile['athlete'];
    final athleteId = athlete is Map ? athlete['id']?.toString() : null;
    final plans = athleteId == null
        ? Future.value(<Map<String, dynamic>>[])
        : Api.trainingPlan(
            athleteId,
          ).catchError((_) => <Map<String, dynamic>>[]);
    final feed = Api.feed().catchError((_) => <String, dynamic>{'posts': []});
    final values = await Future.wait<dynamic>([
      Api.stats('week'),
      Api.stats('month'),
      Api.sessions(),
      plans,
      feed,
    ]);
    return [profile, ...values];
  }

  Future<void> _reload() async {
    setState(() => _data = _load());
    await _data;
  }

  void _openWorkoutBuilder() => _navigateTo(2);

  void _startWorkout() {
    _startWorkoutWithExercises(null);
  }

  void _startWorkoutWithExercises(List<Map<String, dynamic>>? exercises) {
    final current = _sessionController;
    if (current == null || current.saved) {
      current?.dispose();
      _sessionController = WorkoutSessionController(
        plannedExercises: exercises,
      );
      _sessionRevision++;
    }
    setState(() {
      if (_index != 17) _navigationHistory.add(_index);
      _index = 17;
    });
    _saveNavigationState();
  }

  void _exitWorkout() {
    setState(() {
      _sessionController?.dispose();
      _sessionController = null;
      _index = _navigationHistory.isNotEmpty
          ? _navigationHistory.removeLast()
          : 0;
    });
    _saveNavigationState();
  }

  void _goBack() {
    if (_navigationHistory.isEmpty) {
      if (_index != 0) setState(() => _index = 0);
      _saveNavigationState();
      return;
    }
    setState(() => _index = _navigationHistory.removeLast());
    _saveNavigationState();
  }

  void _navigateTo(int index) {
    if (index == 7 && _role != 'personal') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta área é exclusiva para contas Personal.'),
        ),
      );
      return;
    }
    setState(() {
      if (index == _index && index == 1) {
        _revision++;
        return;
      }
      if (index != _index) _navigationHistory.add(_index);
      _index = index;
    });
    _saveNavigationState();
  }

  int get _selectedDestination => switch (_index) {
    0 => 0,
    1 => 1,
    2 || 17 => 2,
    11 => 4,
    _ => 3,
  };

  void _onDestinationSelected(int destination) {
    const pages = [0, 1, 2, -1, 11];
    if (pages[destination] == -1) {
      _openModulePicker();
      return;
    }
    _navigateTo(pages[destination]);
  }

  Future<void> _openModulePicker() async {
    final page = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'OUTRAS \u00c1REAS',
                style: TextStyle(color: softText, fontWeight: FontWeight.w900),
              ),
            ),
            ..._visibleModules.entries.map(
              (entry) => ListTile(
                leading: const Icon(Icons.circle_outlined, color: accent),
                title: Text(entry.value),
                onTap: () => Navigator.pop(context, entry.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (page != null && mounted) _navigateTo(page);
  }

  Widget _homePage({bool desktop = false}) => FutureBuilder<List<dynamic>>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: accent));
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'N\u00e3o foi poss\u00edvel carregar sua conta: ${snapshot.error}',
            ),
          ),
        );
      }
      final profile = snapshot.data?.first;
      if (profile is Map && profile['role'] == 'personal') {
        return FigmaModulePage(
          key: const ValueKey('personal-home'),
          module: 'Alunos & Personal',
        );
      }
      return FigmaDashboard(
        data: _data,
        onReload: _reload,
        onStart: _startWorkout,
        onNavigate: _navigateTo,
        desktop: desktop,
        personalAccount: _role == 'personal',
      );
    },
  );

  void _submitGlobalSearch(String value) {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;
    final coreRoutes = <String, int>{
      'visão geral': 0,
      'inicio': 0,
      'início': 0,
      'dashboard': 0,
      'atividade': 1,
      'histórico': 1,
      'historico': 1,
      'treino': 2,
      'treinos': 2,
    };
    final exactCore = coreRoutes[query];
    final module = _visibleModules.entries
        .where((entry) => entry.value.toLowerCase().contains(query))
        .firstOrNull;
    final destination = exactCore ?? module?.key;
    if (destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nenhuma área encontrada. Tente buscar por treinos, comunidade ou perfil.',
          ),
        ),
      );
    } else {
      _navigateTo(destination);
    }
    _globalSearch.clear();
  }

  @override
  void dispose() {
    _globalSearch.dispose();
    _sessionController?.dispose();
    super.dispose();
  }

  Widget _topBar(bool wide) => SizedBox(
    height: 64,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 12),
      child: Row(
        children: [
          if (_index != 0)
            IconButton(
              tooltip: 'Voltar para a tela anterior',
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, color: stitchPeach),
            ),
          if (!wide)
            const Brand()
          else
            Expanded(
              flex: 5,
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: stitchSurfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _globalSearch,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submitGlobalSearch,
                  style: const TextStyle(color: lightText, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Buscar uma área do WeGYM...',
                    hintStyle: TextStyle(color: softText, fontSize: 11),
                    prefixIcon: Icon(Icons.search, color: softText, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
          if (wide) const Spacer(),
          FutureBuilder<List<dynamic>>(
            future: _data,
            builder: (context, snapshot) {
              final profile =
                  snapshot.data?.isNotEmpty == true &&
                      snapshot.data!.first is Map
                  ? Map<String, dynamic>.from(snapshot.data!.first as Map)
                  : <String, dynamic>{};
              final athlete = profile['athlete'] is Map
                  ? Map<String, dynamic>.from(profile['athlete'] as Map)
                  : <String, dynamic>{};
              final personal = profile['personal'] is Map
                  ? Map<String, dynamic>.from(profile['personal'] as Map)
                  : <String, dynamic>{};
              final name =
                  (profile['name'] ??
                          athlete['name'] ??
                          personal['name'] ??
                          profile['email'] ??
                          'WeGYM')
                      .toString();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (wide) ...[
                    const Icon(
                      Icons.location_on_outlined,
                      color: stitchPeach,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'WeGYM Club • Jardins',
                      style: TextStyle(color: lightText, fontSize: 11),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        color: lightText,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  PopupMenuButton<int>(
                    tooltip: 'Abrir perfil',
                    onSelected: _navigateTo,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 11,
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 18),
                            const SizedBox(width: 10),
                            Text('Perfil de $name'),
                          ],
                        ),
                      ),
                    ],
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: accent.withValues(alpha: .2),
                      child: Text(
                        name.isEmpty ? 'W' : name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          PopupMenuButton<int>(
            tooltip: 'Abrir outra área',
            icon: const Icon(Icons.apps, color: softText),
            onSelected: _navigateTo,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0, child: Text('Visão Geral')),
              const PopupMenuItem(value: 1, child: Text('Atividade')),
              const PopupMenuItem(value: 2, child: Text('Treinos')),
              ..._visibleModules.entries.map(
                (entry) =>
                    PopupMenuItem(value: entry.key, child: Text(entry.value)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _page() {
    if (_index == 0) return _homePage();
    if (_index == 1) {
      return HistoryPage(
        key: ValueKey(_revision),
        preview: const bool.fromEnvironment('PREVIEW_DASHBOARD'),
      );
    }
    if (_index == 2) {
      return WorkoutBuilderPage(
        onStartSession: _startWorkout,
        onStartPlannedSession: _startWorkoutWithExercises,
      );
    }
    if (_index == 17) {
      final controller = _sessionController;
      if (controller == null) return _homePage();
      return WorkoutSessionPage(
        key: ValueKey('session-$_sessionRevision'),
        preview: const bool.fromEnvironment('PREVIEW_DASHBOARD'),
        controller: controller,
        onExit: _exitWorkout,
      );
    }
    if (_visibleModules.containsKey(_index)) {
      return FigmaModulePage(
        key: ValueKey(_index),
        module: _visibleModules[_index]!,
        onLogout: () async {
          await Api.logout();
          widget.onLogout();
          if (mounted) setState(() => _index = 0);
        },
      );
    }
    return _homePage();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return PopScope<Object?>(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: Row(
          children: [
            if (wide)
              _DesktopSidebar(
                selectedIndex: _index,
                personalAccount: _role == 'personal',
                onSelected: _navigateTo,
                onNewWorkout: _openWorkoutBuilder,
              ),
            Expanded(
              child: Column(
                children: [
                  _topBar(wide),
                  if (_sessionController != null && _index != 17)
                    _activeSessionBanner(_sessionController!),
                  Expanded(child: _page()),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _selectedDestination,
                onDestinationSelected: _onDestinationSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view),
                    label: 'In\u00edcio',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.show_chart),
                    label: 'Atividade',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.fitness_center),
                    label: 'Treinos',
                  ),
                  NavigationDestination(icon: Icon(Icons.apps), label: 'Mais'),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    label: 'Perfil',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _activeSessionBanner(WorkoutSessionController controller) => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: stitchOrange.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: stitchOrange.withValues(alpha: .28)),
    ),
    child: Row(
      children: [
        Icon(
          controller.running ? Icons.fitness_center : Icons.pause_circle,
          color: stitchOrange,
          size: 16,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'TREINO EM ANDAMENTO',
            style: TextStyle(
              color: stitchPeach,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: controller.elapsed,
          builder: (context, seconds, _) => Text(
            formatSessionTime(seconds),
            style: const TextStyle(
              color: stitchText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => _navigateTo(17),
          child: const Text('RETOMAR'),
        ),
      ],
    ),
  );
}

class _SidebarRoute {
  const _SidebarRoute(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final int page;
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.personalAccount,
    required this.onSelected,
    required this.onNewWorkout,
  });
  final int selectedIndex;
  final bool personalAccount;
  final ValueChanged<int> onSelected;
  final VoidCallback onNewWorkout;

  static const routes = <_SidebarRoute>[
    _SidebarRoute('Vis\u00e3o Geral', Icons.grid_view, 0),
    _SidebarRoute('Atividade', Icons.show_chart, 1),
    _SidebarRoute('Treinos', Icons.fitness_center, 2),
    _SidebarRoute('Analytics & Performance', Icons.insights, 4),
    _SidebarRoute('Comunidade', Icons.groups, 3),
    _SidebarRoute('Alunos & Personal', Icons.people, 7),
    _SidebarRoute('Agendamentos', Icons.event, 5),
    _SidebarRoute('Nutri\u00e7\u00e3o', Icons.restaurant, 6),
    _SidebarRoute('Metas & Desafios', Icons.flag, 8),
    _SidebarRoute('Programas', Icons.view_list, 9),
    _SidebarRoute('Chat', Icons.chat, 10),
    _SidebarRoute('Perfil & Configura\u00e7\u00f5es', Icons.tune, 11),
    _SidebarRoute('Planos PRO', Icons.workspace_premium, 12),
    _SidebarRoute('Medidas', Icons.monitor_weight, 13),
    _SidebarRoute('Check-in', Icons.check_circle_outline, 14),
    _SidebarRoute('Amigos', Icons.people_alt_outlined, 15),
    _SidebarRoute('Aulas', Icons.calendar_view_week, 16),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 288,
    child: ColoredBox(
      color: stitchSidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Brand(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 42,
                child: FilledButton.icon(
                  onPressed: onNewWorkout,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('NOVO TREINO'),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: stitchOnPrimaryContainer,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: routes
                    .where((route) => route.page != 7 || personalAccount)
                    .map((route) {
                      final selected = route.page == selectedIndex;
                      return Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        child: ListTile(
                          dense: true,
                          minLeadingWidth: 24,
                          selected: selected,
                          selectedTileColor: stitchSurfaceHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          leading: Icon(
                            route.icon,
                            size: 17,
                            color: selected ? accent : softText,
                          ),
                          title: Text(
                            route.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? lightText : softText,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () => onSelected(route.page),
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Text(
                'WEGYM PERFORMANCE OS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.data,
    required this.onReload,
    required this.onStart,
  });
  final Future<List<dynamic>> data;
  final Future<void> Function() onReload;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: accent));
        }
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final profile = snapshot.data![0] as Map<String, dynamic>;
        final week = snapshot.data![1] as Map<String, dynamic>;
        final month = snapshot.data![2] as Map<String, dynamic>;
        final sessions = snapshot.data![3] as List<Map<String, dynamic>>;
        final athlete = profile['athlete'];
        final name =
            (profile['name'] ??
                    (athlete is Map ? athlete['name'] : null) ??
                    'Atleta')
                .toString();

        return RefreshIndicator(
          onRefresh: onReload,
          color: accent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 4
                  : constraints.maxWidth >= 520
                  ? 2
                  : 1;
              final cardWidth =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              final metrics = [
                MetricCard(
                  'VOLUME SEMANAL',
                  amount(week['totalVolume']).toStringAsFixed(0),
                  'KG',
                  Icons.fitness_center,
                  positive,
                ),
                MetricCard(
                  'TREINOS NO MÊS',
                  amount(month['totalSessions']).toInt().toString(),
                  'sessões',
                  Icons.calendar_month,
                  accent,
                ),
                MetricCard(
                  'TEMPO ATIVO',
                  duration(amount(week['totalActiveTime'])),
                  '',
                  Icons.timer_outlined,
                  Colors.blue,
                ),
                MetricCard(
                  'DISTÂNCIA',
                  amount(week['totalDistance']).toStringAsFixed(1),
                  'KM',
                  Icons.route,
                  positive,
                ),
              ];
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HeroCard(
                            name: name,
                            count: amount(month['totalSessions']).toInt(),
                            onStart: onStart,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: metrics
                                .map(
                                  (item) =>
                                      SizedBox(width: cardWidth, child: item),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          SessionsCard(sessions: sessions, onStart: onStart),
                          const SizedBox(height: 14),
                          GoalCard(month: month, week: week),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.name,
    required this.count,
    required this.onStart,
  });
  final String name;
  final int count;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tag('TEMPORADA 04 • ATIVO'),
            const SizedBox(height: 10),
            Text(
              'BEM-VINDO DE VOLTA, ${name.toUpperCase()}!',
              style: const TextStyle(
                color: lightText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              '$count treinos concluídos este mês.',
              style: const TextStyle(color: softText),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (count / 22).clamp(0.0, 1.0),
              color: accent,
              backgroundColor: Colors.white12,
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('INICIAR SESSÃO'),
                  style: FilledButton.styleFrom(backgroundColor: accent),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('CALENDÁRIO'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
    this.title,
    this.value,
    this.unit,
    this.icon,
    this.tint, {
    super.key,
  });
  final String title, value, unit;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: softText,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(icon, color: tint, size: 17),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$value $unit',
              style: const TextStyle(
                color: lightText,
                fontSize: 25,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              'Resumo atualizado',
              style: TextStyle(color: tint, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionsCard extends StatelessWidget {
  const SessionsCard({
    super.key,
    required this.sessions,
    required this.onStart,
  });
  final List<Map<String, dynamic>> sessions;
  final VoidCallback onStart;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tag('ATIVIDADE RECENTE'),
            const SizedBox(height: 7),
            const Text(
              'SESSÕES DE TREINO',
              style: TextStyle(color: lightText, fontWeight: FontWeight.w900),
            ),
            if (sessions.isEmpty)
              const Text(
                'Comece um treino para registrar sua atividade.',
                style: TextStyle(color: softText),
              ),
            ...sessions
                .take(5)
                .map(
                  (row) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fitness_center, color: accent),
                    title: Text(
                      HistoryPage._sessionModality(
                        row['modality'],
                      ).toUpperCase(),
                    ),
                    subtitle: Text(duration(amount(row['durationSec']))),
                  ),
                ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(backgroundColor: accent),
                child: const Text('COMEÇAR AGORA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.month, required this.week});
  final Map<String, dynamic> month, week;
  @override
  Widget build(BuildContext context) {
    final progress = (amount(month['totalSessions']) / 22).clamp(0.0, 1.0);
    return Card(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text(
              'META DO MÊS',
              style: TextStyle(color: softText, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      color: accent,
                      backgroundColor: Colors.white12,
                      strokeWidth: 10,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: lightText,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${amount(week['totalCalories']).round()} kcal • calorias',
              style: const TextStyle(color: softText),
            ),
            const Text(
              'Referência visual: meta de 22 sessões mensais.',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, this.preview = false});
  final bool preview;

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: preview
        ? Future.value([
            {
              'id': 'h1',
              'modality': 'musculacao',
              'durationSec': 3600,
              'completedAt': 'Hoje',
            },
            {
              'id': 'h2',
              'modality': 'corrida',
              'durationSec': 2400,
              'completedAt': 'Ontem',
            },
            {
              'id': 'h3',
              'modality': 'musculacao',
              'durationSec': 3000,
              'completedAt': 'Há 2 dias',
            },
          ])
        : Api.sessions(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator(color: accent));
      }
      if (snapshot.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: stitchPeach,
                  size: 34,
                ),
                const SizedBox(height: 12),
                Text(
                  'Não foi possível carregar o histórico: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: softText),
                ),
              ],
            ),
          ),
        );
      }

      final sessions = snapshot.data ?? const <Map<String, dynamic>>[];
      final totalSeconds = sessions.fold<int>(
        0,
        (sum, item) => sum + amount(item['durationSec']).round(),
      );
      final lastSession = sessions.isEmpty
          ? '—'
          : _sessionDate(sessions.first['completedAt']);
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const StitchPageHeading(
                    eyebrow: 'WEGYM PERFORMANCE OS  •  ATIVIDADE',
                    title: 'Histórico de treinos',
                    subtitle:
                        'Acompanhe suas sessões concluídas e a consistência da sua rotina.',
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 420
                          ? constraints.maxWidth
                          : constraints.maxWidth < 700
                          ? (constraints.maxWidth - 10) / 2
                          : 220.0;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: width,
                            child: StitchMetric(
                              label: 'SESSÕES REGISTRADAS',
                              value: sessions.length.toString(),
                              icon: Icons.fitness_center,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: StitchMetric(
                              label: 'TEMPO DE TREINO',
                              value: duration(totalSeconds.toDouble()),
                              icon: Icons.timer_outlined,
                              tint: stitchGreen,
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: StitchMetric(
                              label: 'SESSÃO MAIS RECENTE',
                              value: lastSession,
                              icon: Icons.event,
                              tint: stitchBlue,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  StitchSection(
                    title: 'Sessões recentes',
                    icon: Icons.history,
                    child: sessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 22),
                            child: Center(
                              child: Text(
                                'Suas sessões aparecerão aqui depois que você concluir um treino.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: softText),
                              ),
                            ),
                          )
                        : Column(
                            children: sessions.map((session) {
                              final modality = _sessionModality(
                                session['modality'],
                              );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: stitchSurfaceLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: stitchOrange.withValues(
                                          alpha: .14,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.fitness_center,
                                        color: stitchOrange,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            modality,
                                            style: const TextStyle(
                                              color: stitchText,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _sessionDate(
                                              session['completedAt'],
                                            ),
                                            style: const TextStyle(
                                              color: stitchMuted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StitchTag(
                                      duration(amount(session['durationSec'])),
                                      color: stitchPeach,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
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

  static String _sessionModality(dynamic value) =>
      switch ((value ?? '').toString().trim().toLowerCase()) {
        'musculacao' || 'musculação' || 'strength' => 'Musculação',
        'corrida' || 'running' => 'Corrida',
        'cycling' || 'ciclismo' => 'Ciclismo',
        'walking' || 'caminhada' => 'Caminhada',
        final value when value.isEmpty => 'Treino',
        final value => value[0].toUpperCase() + value.substring(1),
      };

  static String _sessionDate(dynamic value) {
    final raw = (value ?? '').toString();
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw.isEmpty ? 'Data não informada' : raw;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onLogout});
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: Api.profile(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text(snapshot.error.toString()));
      }
      final profile = snapshot.data!;
      final athlete = profile['athlete'];
      final name =
          (profile['name'] ??
                  (athlete is Map ? athlete['name'] : null) ??
                  'Atleta')
              .toString();
      return Center(
        child: Card(
          color: surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: accent,
                  child: Text(name[0].toUpperCase()),
                ),
                Text(
                  name,
                  style: const TextStyle(color: lightText, fontSize: 20),
                ),
                Text(
                  (profile['email'] ?? '').toString(),
                  style: const TextStyle(color: softText),
                ),
                OutlinedButton(onPressed: onLogout, child: const Text('SAIR')),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.bolt, color: accent),
      Text(
        'WEGYM',
        style: TextStyle(
          color: lightText,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    ],
  );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: accent,
      fontWeight: FontWeight.w900,
      fontSize: 10,
      letterSpacing: .7,
    ),
  );
}

double amount(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
String duration(double value) {
  final seconds = value.round(),
      hours = seconds ~/ 3600,
      minutes = (seconds % 3600) ~/ 60;
  return hours > 0
      ? '${hours}h${minutes.toString().padLeft(2, '0')}'
      : '$minutes min';
}

String formatClock(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
