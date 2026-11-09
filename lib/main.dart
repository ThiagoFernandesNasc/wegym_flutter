import 'dart:async';
import 'dart:math' as math;
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'ai_coach_sheet.dart';
import 'dashboard.dart';
import 'workout_builder.dart';
import 'figma_modules.dart';
import 'stitch_design_system.dart';
import 'device_frame_preview.dart';
import 'payment_return_link.dart';
import 'integration_return_link.dart';
import 'gps_session_page.dart';
import 'modality_session_page.dart';
import 'training_modalities.dart';
import 'ble_monitor_page.dart';
import 'legal_document_page.dart';
import 'onboarding_tour.dart';
import 'profile_avatar.dart';

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
  18: 'Atividade GPS',
  19: 'Wearables & Sensores',
  20: 'Conquistas',
};

double? _heightCentimeters(String raw) {
  final value = double.tryParse(raw.trim().replaceAll(',', '.'));
  if (value == null) return null;
  return value <= 3 ? value * 100 : value;
}

void main() => runApp(const WegymApp());

class WegymApp extends StatefulWidget {
  const WegymApp({super.key});

  @override
  State<WegymApp> createState() => _WegymAppState();
}

class _WegymAppState extends State<WegymApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && isPaymentReturnUri(Uri.base)) {
      paymentReturnLink.value = Uri.base;
    }
    if (kIsWeb && isIntegrationReturnUri(Uri.base)) {
      integrationReturnLink.value = Uri.base;
    }
    final links = AppLinks();
    _linkSubscription = links.uriLinkStream.listen((uri) {
      if (isPaymentReturnUri(uri)) paymentReturnLink.value = uri;
      if (isIntegrationReturnUri(uri)) integrationReturnLink.value = uri;
    });
    unawaited(
      links
          .getInitialLink()
          .then((uri) {
            if (uri != null && isPaymentReturnUri(uri)) {
              paymentReturnLink.value = uri;
            }
            if (uri != null && isIntegrationReturnUri(uri)) {
              integrationReturnLink.value = uri;
            }
          })
          .catchError((_) {}),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WEGYM',
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          DeviceFramePreview(child: child ?? const SizedBox.shrink()),
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
  bool _usingDemoData = false;

  @override
  void initState() {
    super.initState();
    if (_loadingDemoRole) {
      if (const bool.fromEnvironment('PREVIEW_REQUIRE_LOGIN')) {
        unawaited(_prepareDemoLogin());
      } else {
        _restoreDemoRole();
      }
    }
  }

  Future<void> _prepareDemoLogin() async {
    try {
      await Api.restoreDemoSession();
      final token = await Api.token();
      if (token != null && !Api.isDemoSession) {
        final profile = await Api.profile();
        final role = profile['role']?.toString();
        if (role == 'atleta' || role == 'personal') {
          await Api.setPreviewRole(role);
          if (!mounted) return;
          setState(() {
            _demoRole = role;
            _usingDemoData = false;
            _loadingDemoRole = false;
          });
          return;
        }
      }
    } catch (_) {
      await Api.logout();
    }
    try {
      await Api.setPreviewRole(null);
      await Api.setDemoSession(false);
    } catch (_) {
      // A tela de login permanece disponÃƒÆ’Ã‚Â­vel se o armazenamento estiver bloqueado.
    }
    if (!mounted) return;
    setState(() {
      _demoRole = null;
      _usingDemoData = false;
      _loadingDemoRole = false;
    });
  }

  Future<void> _restoreDemoRole() async {
    String? savedRole;
    var demoData = false;
    try {
      demoData = await Api.restoreDemoSession();
      savedRole = await Api.previewRole();
      if (!demoData && await Api.token() != null) {
        final profile = await Api.profile();
        savedRole = profile['role']?.toString();
      }
    } catch (_) {
      // A prÃƒÆ’Ã‚Â©via continua disponÃƒÆ’Ã‚Â­vel se o navegador ou o servidor estiver indisponÃƒÆ’Ã‚Â­vel.
    }
    if (!mounted) return;
    setState(() {
      _demoRole = savedRole;
      _usingDemoData = demoData;
      _loadingDemoRole = false;
    });
  }

  void _refresh() => setState(() => _token = Api.token());

  Future<void> _handleSuccessfulLogin(String role) async {
    await showOnboardingIfNeeded(context, role: role);
    if (!mounted) return;
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      try {
        await Api.setPreviewRole(role);
        await Api.setRegisterMode(false);
      } catch (_) {
        // Keep the presentation login usable if browser storage is unavailable.
      }
      if (mounted) {
        setState(() {
          _demoRole = role;
          _usingDemoData = Api.isDemoSession;
        });
      }
      return;
    }
    _refresh();
  }

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
          onLogin: (selectedRole) =>
              unawaited(_handleSuccessfulLogin(selectedRole)),
        );
      }
      return AppShell(
        demoRole: _usingDemoData ? role : null,
        onLogout: () {
          unawaited(Api.clearPreviewState());
          if (mounted) {
            setState(() {
              _demoRole = null;
              _usingDemoData = false;
            });
          }
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
          return LoginPage(
            onLogin: (role) => unawaited(_handleSuccessfulLogin(role)),
          );
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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageScroll = ScrollController();
  final _parallaxPointer = ValueNotifier<Offset>(Offset.zero);
  late final AnimationController _ambientMotion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();
  late final AnimationController _introMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final AnimationController _formMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _name = TextEditingController();
  final _credential = TextEditingController();
  final _cep = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _injury = TextEditingController();
  final _healthIssues = TextEditingController();
  final _medications = TextEditingController();
  bool _busy = false;
  bool _register = false;
  bool _remember = true;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _acceptData = false;
  bool _showPassword = false;
  bool _verifyingCref = false;
  bool _lookingUpCep = false;
  int _cepLookupGeneration = 0;
  String _cepNotice = '';
  String? _verifiedCrefValue;
  String _userType = 'atleta';
  String? _sex;
  String? _experienceLevel;
  String _error = '';
  double _formSlideDirection = -1;
  bool _switchingRegisterMode = false;
  bool _submitHovered = false;
  bool _submitPressed = false;

  bool get _crefVerified =>
      _verifiedCrefValue == _credential.text.trim().toUpperCase() &&
      _verifiedCrefValue != null;

  @override
  void initState() {
    super.initState();
    _introMotion.forward();
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
    if (_register == register || _switchingRegisterMode) return;
    unawaited(_animateRegisterMode(register));
  }

  Future<void> _animateRegisterMode(bool register) async {
    _switchingRegisterMode = true;
    _formSlideDirection = register ? 1 : -1;
    await _formMotion.reverse();
    if (!mounted) return;
    setState(() {
      _register = register;
      _error = '';
      _verifiedCrefValue = null;
      _acceptTerms = false;
      _acceptPrivacy = false;
      _acceptData = false;
    });
    if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
      unawaited(Api.setRegisterMode(register).catchError((_) {}));
    }
    await _formMotion.forward();
    if (!mounted) return;
    setState(() => _switchingRegisterMode = false);
    if (_pageScroll.hasClients) {
      await _pageScroll.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
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

  Future<void> _lookupCep(String value) async {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return;
    final generation = ++_cepLookupGeneration;
    setState(() {
      _lookingUpCep = true;
      _cepNotice = '';
    });
    try {
      final address = await Api.lookupAddressByCep(digits);
      if (!mounted ||
          generation != _cepLookupGeneration ||
          _cep.text.replaceAll(RegExp(r'\D'), '') != digits) {
        return;
      }
      if (address == null) {
        setState(
          () => _cepNotice = 'CEP n\u00e3o encontrado. Confira o n\u00famero.',
        );
        return;
      }
      setState(() {
        _city.text = address['city']?.toString() ?? '';
        _state.text = address['state']?.toString() ?? '';
        _cepNotice = _city.text.isEmpty
            ? 'Preencha a cidade e o estado manualmente.'
            : 'Cidade e estado preenchidos pelo CEP.';
      });
    } catch (_) {
      if (mounted && generation == _cepLookupGeneration) {
        setState(
          () => _cepNotice = 'Busca indispon\u00edvel; preencha manualmente.',
        );
      }
    } finally {
      if (mounted && generation == _cepLookupGeneration) {
        setState(() => _lookingUpCep = false);
      }
    }
  }

  Future<void> _verifyCref() async {
    final cref = _credential.text.trim().toUpperCase();
    if (cref.isEmpty) {
      setState(() => _error = 'Informe o CREF para validar.');
      return;
    }
    setState(() {
      _verifyingCref = true;
      _verifiedCrefValue = null;
      _error = '';
    });
    try {
      final result = await Api.validateCref(cref);
      if (result['valid'] != true) {
        final errors = result['errors'];
        throw Exception(
          errors is List && errors.isNotEmpty
              ? errors.first.toString()
              : 'CREF inválido.',
        );
      }
      if (mounted) {
        setState(() {
          _verifiedCrefValue = result['normalizedCref']?.toString() ?? cref;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _verifyingCref = false);
    }
  }

  Future<void> _submit() async {
    if (_register && _userType == 'personal' && !_crefVerified) {
      setState(() => _error = 'Valide o CREF antes de continuar.');
      return;
    }
    if (_register && !(_acceptTerms && _acceptPrivacy && _acceptData)) {
      setState(
        () => _error =
            'Aceite separadamente os Termos, a Pol\u00edtica de Privacidade e o tratamento de dados.',
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
          if (_userType == 'atleta') ...{
            'cpf': _credential.text.replaceAll(RegExp(r'\D'), ''),
            'cep': _cep.text.trim(),
            'city': _city.text.trim(),
            'state': _state.text.trim().toUpperCase(),
            'age': int.parse(_age.text),
            'sex': _sex,
            'height': _heightCentimeters(_height.text)!,
            'weight': double.parse(_weight.text.replaceAll(',', '.')),
            'experienceLevel': _experienceLevel,
            'injury': _injury.text.trim().isEmpty ? null : _injury.text.trim(),
            'healthIssues': _healthIssues.text.trim().isEmpty
                ? null
                : _healthIssues.text.trim(),
            'medications': _medications.text.trim().isEmpty
                ? null
                : _medications.text.trim(),
          },
          'termsAccepted': _acceptTerms,
          'privacyAccepted': _acceptPrivacy,
          'dataConsentAccepted': _acceptData,
        });
        if (!mounted) return;
        await showOnboardingIfNeeded(context, role: _userType);
        if (!mounted) return;
        setState(() {
          _register = false;
          _error = 'Cadastro conclu\u00eddo. Entre com sua conta.';
        });
        return;
      }
      if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
        final email = _email.text.trim().toLowerCase();
        final demoRole = switch (email) {
          'joao@wegym.com.br' => 'atleta',
          'personal@wegym.com.br' => 'personal',
          _ => null,
        };
        try {
          final authenticatedRole = await Api.login(email, _password.text);
          widget.onLogin(authenticatedRole ?? _userType);
          return;
        } catch (error) {
          if (demoRole != null && _password.text == _demoPassword) {
            // MantÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©m os acessos de demonstraÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â§ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â£o disponÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­veis sem o backend.
            await Api.logout();
            await Api.setDemoSession(true);
            widget.onLogin(demoRole);
            return;
          }
          rethrow;
        }
      }
      final authenticatedRole = await Api.login(
        _email.text.trim(),
        _password.text,
      );
      widget.onLogin(authenticatedRole ?? _userType);
    } catch (error) {
      final duplicateEmail =
          _register &&
          error is ApiResponseException &&
          error.statusCode == 409 &&
          error.message.toLowerCase().contains('cadastro');
      if (duplicateEmail) {
        setState(() {
          _register = false;
          _error =
              'Este e-mail j\u00e1 est\u00e1 cadastrado. Entre com o e-mail e a senha informados.';
        });
        if (const bool.fromEnvironment('PREVIEW_DASHBOARD')) {
          unawaited(Api.setRegisterMode(false));
        }
      } else {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _ambientMotion.dispose();
    _introMotion.dispose();
    _formMotion.dispose();
    _parallaxPointer.dispose();
    _pageScroll.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _name.dispose();
    _credential.dispose();
    _cep.dispose();
    _city.dispose();
    _state.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _injury.dispose();
    _healthIssues.dispose();
    _medications.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool secret = false,
    TextInputType? keyboard,
    bool externalLabel = false,
    String? hint,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onFieldSubmitted,
    TextInputAction? textInputAction,
    Key? key,
    String? Function(String?)? validator,
  }) => TextFormField(
    key: key,
    controller: controller,
    onChanged: onChanged,
    onFieldSubmitted: onFieldSubmitted,
    keyboardType: keyboard,
    textInputAction: textInputAction,
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
    validator:
        validator ??
        (value) {
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
          if (_register &&
              (label == 'CPF / CREF' || label == 'CPF' || label == 'CREF') &&
              text.isEmpty) {
            return label == 'CREF' ? 'Informe seu CREF.' : 'Informe seu CPF.';
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
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(ctx).nextFocus(),
              decoration: const InputDecoration(
                labelText: 'Token recebido no e-mail',
              ),
            ),
            TextField(
              controller: password,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) =>
                  Navigator.pop(ctx, [token.text.trim(), password.text]),
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

  Widget _loginForm() => AnimatedBuilder(
    animation: _formMotion,
    child: _loginFormPanel(),
    builder: (context, child) {
      final progress = Curves.easeOutCubic.transform(_formMotion.value);
      return Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(_formSlideDirection * (1 - progress) * 12, 0),
          child: child,
        ),
      );
    },
  );

  Widget _loginFormPanel() => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF19191D),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 28),
      child: Material(
        color: Colors.transparent,
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
                _register ? 'CRIE SUA CONTA' : 'LOGIN',
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
                    : 'Pronto para o treino de hoje?',
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
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'atleta', label: Text('Atleta')),
                    ButtonSegment(value: 'personal', label: Text('Personal')),
                  ],
                  selected: {_userType},
                  onSelectionChanged: (v) => setState(() {
                    _userType = v.first;
                    _credential.clear();
                    _verifiedCrefValue = null;
                    _acceptTerms = false;
                    _acceptPrivacy = false;
                    _acceptData = false;
                    _error = '';
                  }),
                ),
                const SizedBox(height: 12),
                if (_userType == 'personal' && !_crefVerified) ...[
                  _field(
                    _credential,
                    'CREF',
                    key: const ValueKey('signup-credential'),
                    onChanged: (value) {
                      if (_verifiedCrefValue != value.trim().toUpperCase()) {
                        setState(() {
                          _verifiedCrefValue = null;
                          _error = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('validate-cref'),
                    onPressed: _busy || _verifyingCref ? null : _verifyCref,
                    icon: _verifyingCref
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user_outlined),
                    label: Text(
                      _verifyingCref ? 'VALIDANDO CREF' : 'VALIDAR CREF',
                    ),
                  ),
                ],
                if (_userType == 'personal' && _crefVerified)
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.check_circle, color: positive),
                    title: Text('CREF validado'),
                  ),
                if (_userType == 'personal' && _crefVerified) ...[
                  _field(_name, 'Nome', key: const ValueKey('signup-name')),
                  const SizedBox(height: 10),
                ],
                if (_userType == 'atleta') ...[
                  _field(_name, 'Nome', key: const ValueKey('signup-name')),
                  const SizedBox(height: 10),
                  _field(
                    _credential,
                    'CPF',
                    key: const ValueKey('signup-credential'),
                    keyboard: TextInputType.number,
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      return digits.length == 11
                          ? null
                          : 'Informe um CPF com 11 d\u00edgitos.';
                    },
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _cep,
                    'CEP',
                    key: const ValueKey('signup-cep'),
                    keyboard: TextInputType.number,
                    validator: (value) {
                      final digits = (value ?? '').replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      return digits.length == 8
                          ? null
                          : 'Informe um CEP v\u00e1lido.';
                    },
                    onChanged: (value) {
                      _cepLookupGeneration++;
                      if (value.replaceAll(RegExp(r'\D'), '').length == 8) {
                        unawaited(_lookupCep(value));
                      } else {
                        setState(() {
                          _lookingUpCep = false;
                          _cepNotice = '';
                        });
                      }
                    },
                  ),
                  if (_lookingUpCep)
                    const LinearProgressIndicator(minHeight: 2),
                  if (_cepNotice.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _cepNotice,
                        style: const TextStyle(color: softText, fontSize: 10),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _field(
                          _city,
                          'Cidade',
                          key: const ValueKey('signup-city'),
                          validator: (value) =>
                              (value?.trim().isNotEmpty ?? false)
                              ? null
                              : 'Informe a cidade.',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          _state,
                          'UF',
                          key: const ValueKey('signup-state'),
                          validator: (value) => (value?.trim().length ?? 0) == 2
                              ? null
                              : 'Use a sigla do estado.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _age,
                          'Idade',
                          key: const ValueKey('signup-age'),
                          keyboard: TextInputType.number,
                          validator: (value) {
                            final age = int.tryParse(value ?? '');
                            return age != null && age >= 12 && age <= 120
                                ? null
                                : 'Use uma idade entre 12 e 120.';
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          _height,
                          'Altura (m ou cm)',
                          key: const ValueKey('signup-height'),
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final height = _heightCentimeters(value ?? '');
                            return height != null &&
                                    height >= 50 &&
                                    height <= 250
                                ? null
                                : 'Informe entre 0,50 e 2,50 m (ou 50 a 250 cm).';
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          _weight,
                          'Peso (kg)',
                          key: const ValueKey('signup-weight'),
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final weight = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            return weight != null &&
                                    weight >= 20 &&
                                    weight <= 400
                                ? null
                                : 'Use peso entre 20 e 400 kg.';
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('signup-sex'),
                    initialValue: _sex,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'masculino',
                        child: Text('Masculino'),
                      ),
                      DropdownMenuItem(
                        value: 'feminino',
                        child: Text('Feminino'),
                      ),
                      DropdownMenuItem(value: 'outro', child: Text('Outro')),
                    ],
                    validator: (value) =>
                        value == null ? 'Selecione uma op\u00e7\u00e3o.' : null,
                    onChanged: (value) => setState(() => _sex = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: const ValueKey('signup-experience'),
                    initialValue: _experienceLevel,
                    decoration: const InputDecoration(
                      labelText: 'Experi\u00eancia',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'iniciante',
                        child: Text('Iniciante'),
                      ),
                      DropdownMenuItem(
                        value: 'intermediario',
                        child: Text('Intermedi\u00e1rio'),
                      ),
                      DropdownMenuItem(
                        value: 'avancado',
                        child: Text('Avan\u00e7ado'),
                      ),
                    ],
                    validator: (value) =>
                        value == null ? 'Selecione o n\u00edvel.' : null,
                    onChanged: (value) =>
                        setState(() => _experienceLevel = value),
                  ),
                  const SizedBox(height: 10),
                  _field(_injury, 'Les\u00f5es (opcional)'),
                  const SizedBox(height: 10),
                  _field(
                    _healthIssues,
                    'Condi\u00e7\u00f5es de sa\u00fade (opcional)',
                  ),
                  const SizedBox(height: 10),
                  _field(_medications, 'Medicamentos (opcional)'),
                ],
              ],
              if (!_register || _userType == 'atleta' || _crefVerified) ...[
                if (!_register)
                  _loginFieldLabel(
                    'E-MAIL INSTITUCIONAL OU MATRÍCULA',
                    trailing: '#WG-CODE',
                  ),
                _field(
                  _email,
                  'E-mail',
                  key: _register ? const ValueKey('signup-email') : null,
                  keyboard: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  externalLabel: !_register,
                  hint: _register ? null : 'ex.: nome@atleta.com ou #WG-9842',
                ),
                const SizedBox(height: 10),
                if (!_register) _loginFieldLabel('CHAVE DE ACESSO / SENHA'),
                _field(
                  _password,
                  'Senha',
                  key: _register ? const ValueKey('signup-password') : null,
                  secret: true,
                  textInputAction: _register
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) => _register
                      ? FocusScope.of(context).nextFocus()
                      : _submit(),
                  externalLabel: !_register,
                  hint: _register
                      ? null
                      : '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                ),
                if (_register) ...[
                  const SizedBox(height: 10),
                  _field(
                    _confirmPassword,
                    'Confirmar senha',
                    key: const ValueKey('signup-confirm-password'),
                    secret: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) => value == _password.text
                        ? null
                        : 'As senhas n\u00e3o coincidem.',
                  ),
                ],
              ],
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
              if (_register && (_userType == 'atleta' || _crefVerified))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                      child: Text(
                        'CONSENTIMENTOS LGPD',
                        style: TextStyle(
                          color: softText,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('consent-terms'),
                      value: _acceptTerms,
                      onChanged: (value) =>
                          setState(() => _acceptTerms = value ?? false),
                      activeColor: accent,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Li e aceito os ',
                            style: TextStyle(color: softText, fontSize: 10),
                          ),
                          const LegalDocumentLink(
                            buttonKey: ValueKey('legal-link-terms-signup'),
                            kind: LegalDocumentKind.terms,
                            label: 'Termos de Uso',
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('consent-privacy'),
                      value: _acceptPrivacy,
                      onChanged: (value) =>
                          setState(() => _acceptPrivacy = value ?? false),
                      activeColor: accent,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Li e aceito a ',
                            style: TextStyle(color: softText, fontSize: 10),
                          ),
                          const LegalDocumentLink(
                            buttonKey: ValueKey('legal-link-privacy-signup'),
                            kind: LegalDocumentKind.privacy,
                            label: 'Pol\u00edtica de Privacidade',
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      key: const ValueKey('consent-data'),
                      value: _acceptData,
                      onChanged: (value) =>
                          setState(() => _acceptData = value ?? false),
                      activeColor: accent,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: const Text(
                        'Autorizo o tratamento dos meus dados pessoais (LGPD)',
                        style: TextStyle(color: softText, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -.12),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _error.isEmpty
                    ? const SizedBox.shrink(key: ValueKey('login-error-empty'))
                    : Padding(
                        key: ValueKey(_error),
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
              ),
              const SizedBox(height: 8),
              if (!_register || _userType != 'personal' || _crefVerified)
                MouseRegion(
                  onEnter: (_) => setState(() => _submitHovered = true),
                  onExit: (_) => setState(() => _submitHovered = false),
                  child: Listener(
                    onPointerDown: (_) => setState(() => _submitPressed = true),
                    onPointerUp: (_) => setState(() => _submitPressed = false),
                    onPointerCancel: (_) =>
                        setState(() => _submitPressed = false),
                    child: AnimatedScale(
                      scale: _submitPressed
                          ? .99
                          : _submitHovered
                          ? 1.01
                          : 1,
                      duration: const Duration(milliseconds: 130),
                      curve: Curves.easeOut,
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _register
                                      ? Icons.person_add_alt_1
                                      : Icons.bolt,
                                ),
                          label: Text(
                            _register ? 'CRIAR CONTA' : 'ENTRAR NO WEGYM OS',
                          ),
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
                    ),
                  ),
                ),
              if (!_register) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () =>
                      _showUnavailableSignIn('Passkey / biometria'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightText,
                    backgroundColor: const Color(0xFF101013),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .05),
                    ),
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
              if (!_register && Api.isDemoSession) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'ACESSOS PARA DEMONSTRA\u00C7\u00C3O',
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
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 2,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Text(
                      'E2E \u00b7 LGPD',
                      style: TextStyle(color: softText, fontSize: 9),
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      LegalDocumentLink(
                        buttonKey: ValueKey('legal-link-terms-login'),
                        kind: LegalDocumentKind.terms,
                        label: 'TERMOS',
                        compact: true,
                      ),
                      Text('?', style: TextStyle(color: softText, fontSize: 9)),
                      LegalDocumentLink(
                        buttonKey: ValueKey('legal-link-privacy-login'),
                        kind: LegalDocumentKind.privacy,
                        label: 'PRIVACIDADE',
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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

  Widget _ambientOrb(Alignment alignment, Color color, double size) => Align(
    alignment: alignment,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 110, spreadRadius: 38)],
      ),
    ),
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

  Widget _introItem(
    Widget child, {
    double begin = 0,
    double end = 0.72,
    double distance = 20,
  }) => AnimatedBuilder(
    animation: _introMotion,
    child: child,
    builder: (context, child) {
      final progress = Interval(
        begin,
        end,
        curve: Curves.easeOutCubic,
      ).transform(_introMotion.value);
      return Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * distance),
          child: child,
        ),
      );
    },
  );

  Widget _animatedBrand() => _introItem(
    AnimatedBuilder(
      animation: _ambientMotion,
      builder: (context, child) {
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        final phase = reducedMotion ? 0.0 : _ambientMotion.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(0, math.sin(phase) * 1.5),
          child: Transform.rotate(angle: math.sin(phase) * .035, child: child),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .28),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.fitness_center,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'WEGYM',
            style: TextStyle(
              color: lightText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    ),
    begin: 0,
    end: .6,
    distance: 20,
  );

  Widget _dumbbellIllustration() => SizedBox(
    width: 220,
    height: 132,
    child: AnimatedBuilder(
      animation: _ambientMotion,
      builder: (context, child) {
        final phase = _ambientMotion.value * math.pi * 2;
        final reducedMotion = MediaQuery.of(context).disableAnimations;
        final float = reducedMotion ? 0.0 : math.sin(phase * 2.4) * 9;
        final rotation = reducedMotion ? 0.0 : phase;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, float),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .001)
                  ..rotateX(.28)
                  ..rotateY(rotation),
                child: child,
              ),
            ),
            const SizedBox(height: 9),
            Transform.scale(
              scaleX: 1 - (float.abs() / 120),
              child: Container(
                width: 110,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .52),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .45),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dumbbellWeights(),
          Container(
            width: 38,
            height: 10,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6D7078),
                  Color(0xFF25262B),
                  Color(0xFF777A82),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          _dumbbellWeights(),
        ],
      ),
    ),
  );

  Widget _dumbbellWeights() => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(
      3,
      (index) => Container(
        width: 9,
        height: 40 - index * 4,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A27), Color(0xFFF45B0A), Color(0xFF9D3105)],
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: const Color(0xFFFFA04F).withValues(alpha: .7),
          ),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .32), blurRadius: 12),
          ],
        ),
      ),
    ),
  );

  Widget _storyPanel() => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: CustomPaint(
      painter: _LoginDotPattern(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252326), Color(0xFF151518), Color(0xFF121A19)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(34, 30, 34, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animatedBrand(),
            const SizedBox(height: 38),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: positive.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: positive.withValues(alpha: .22)),
              ),
              child: const Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(Icons.circle, color: positive, size: 8),
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
                  TextSpan(text: 'SUPERE\nSEUS\n'),
                  TextSpan(
                    text: 'LIMITES',
                    style: TextStyle(color: accent),
                  ),
                  TextSpan(text: '.'),
                ],
              ),
              style: TextStyle(
                color: lightText,
                fontSize: 42,
                height: .98,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sua jornada para a melhor vers\u00e3o de si mesmo come\u00e7a aqui.',
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
            const SizedBox(height: 14),
            _dumbbellIllustration(),
            const Spacer(),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: positive, size: 15),
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
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 850;
          return MouseRegion(
            onHover: (event) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              _parallaxPointer.value = Offset(
                ((event.position.dx / size.width) - .5) * 2,
                ((event.position.dy / size.height) - .5) * 2,
              );
            },
            onExit: (_) => _parallaxPointer.value = Offset.zero,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _ambientMotion,
                    _parallaxPointer,
                  ]),
                  builder: (context, child) {
                    final phase = _ambientMotion.value * math.pi * 2;
                    final reducedMotion = MediaQuery.of(
                      context,
                    ).disableAnimations;
                    final pointer = reducedMotion
                        ? Offset.zero
                        : _parallaxPointer.value;
                    final drift = reducedMotion ? 0.0 : math.sin(phase) * .06;
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: Stack(
                          children: [
                            _ambientOrb(
                              Alignment(
                                .88 + drift + pointer.dx * .12,
                                -.82 - drift + pointer.dy * .12,
                              ),
                              const Color(0xFFEA580C).withValues(alpha: .19),
                              250,
                            ),
                            _ambientOrb(
                              Alignment(
                                -.92 - drift - pointer.dx * .1,
                                .86 + drift + pointer.dy * .1,
                              ),
                              const Color(0xFF16A34A).withValues(alpha: .07),
                              310,
                            ),
                            _ambientOrb(
                              Alignment(
                                .4 - drift + pointer.dx * .08,
                                .7 - drift - pointer.dy * .08,
                              ),
                              const Color(0xFF2563EB).withValues(alpha: .045),
                              210,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SingleChildScrollView(
                  controller: _pageScroll,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                                        Expanded(flex: 4, child: _storyPanel()),
                                        const SizedBox(width: 10),
                                        Expanded(flex: 8, child: _loginForm()),
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
            ),
          );
        },
      ),
    ),
  );
}

class _LoginTilt extends StatefulWidget {
  const _LoginTilt({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_LoginTilt> createState() => _LoginTiltState();
}

class _LoginTiltState extends State<_LoginTilt> {
  Offset _tilt = Offset.zero;
  Alignment _glare = Alignment.center;

  void _onHover(PointerEvent event) {
    if (!widget.enabled) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(event.position);
    final x = (local.dx / box.size.width).clamp(0.0, 1.0);
    final y = (local.dy / box.size.height).clamp(0.0, 1.0);
    setState(() {
      _tilt = Offset(x - .5, y - .5);
      _glare = Alignment(x * 2 - 1, y * 2 - 1);
    });
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onHover: widget.enabled ? _onHover : null,
    onExit: widget.enabled
        ? (_) => setState(() {
            _tilt = Offset.zero;
            _glare = Alignment.center;
          })
        : null,
    child: TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(end: _tilt),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      builder: (context, tilt, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 1 / 900)
          ..rotateX(-tilt.dy * 8 * math.pi / 180)
          ..rotateY(tilt.dx * 8 * math.pi / 180)
          ..scaleByDouble(
            widget.enabled && tilt != Offset.zero ? 1.006 : 1.0,
            widget.enabled && tilt != Offset.zero ? 1.006 : 1.0,
            1,
            1,
          );
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                child!,
                if (widget.enabled)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: _glare,
                            radius: .9,
                            colors: [
                              Colors.white.withValues(alpha: .09),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    ),
  );
}

class _LoginDotPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .045);
    for (var y = 12.0; y < size.height; y += 24) {
      for (var x = 12.0; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
  int _offlinePendingCount = 0;
  bool _syncingPendingWorkouts = false;
  bool _handlingPaymentReturn = false;
  late final AppLifecycleListener _appLifecycleListener;
  WorkoutSessionController? _sessionController;
  String _dashboardGpsActivity = 'Corrida';
  String? _selectedAthleteId;
  String _dashboardModality = 'aerobic';
  final _globalSearch = TextEditingController();
  late Future<List<dynamic>> _data = _load();

  @override
  void initState() {
    super.initState();
    _role = widget.demoRole;
    _appLifecycleListener = AppLifecycleListener(
      onResume: () => unawaited(_refreshOfflineWorkouts(sync: true)),
    );
    _restoreNavigation();
    paymentReturnLink.addListener(_handlePaymentReturn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handlePaymentReturn());
    unawaited(_refreshOfflineWorkouts(sync: true));
  }

  void _handlePaymentReturn() {
    if (_handlingPaymentReturn || !mounted) return;
    final uri = paymentReturnLink.value;
    if (uri == null || !isPaymentReturnUri(uri)) return;
    _handlingPaymentReturn = true;
    paymentReturnLink.value = null;
    final result =
        uri.queryParameters['payment_return'] ??
        uri.queryParameters['status'] ??
        uri.queryParameters['collection_status'];
    unawaited(_verifyPaymentReturn(result));
  }

  Future<void> _verifyPaymentReturn(String? result) async {
    var notice = 'Retorno do pagamento recebido. Verifique sua assinatura.';
    try {
      final response = Map<String, dynamic>.from(
        await Api.get('/api/subscriptions/me') as Map,
      );
      final subscription = response['data'];
      if (subscription is Map && subscription['status'] == 'active') {
        notice =
            'Pagamento confirmado. Sua assinatura WeGYM PRO est\u00e1 ativa.';
      } else if (result == 'success' || result == 'approved') {
        notice =
            'Pagamento aprovado no checkout. A confirma\u00e7\u00e3o da assinatura est\u00e1 aguardando o webhook.';
      } else if (result == 'pending' || result == 'in_process') {
        notice =
            'Pagamento pendente. A assinatura ser\u00e1 ativada ap\u00f3s a confirma\u00e7\u00e3o.';
      } else if (result == 'failure' || result == 'rejected') {
        notice =
            'O pagamento n\u00e3o foi aprovado. Voc\u00ea pode tentar novamente em Planos PRO.';
      }
    } catch (_) {
      notice =
          'N\u00e3o foi poss\u00edvel verificar o pagamento agora. Consulte Planos PRO novamente.';
    } finally {
      _handlingPaymentReturn = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(notice)));
    }
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
        18,
        19,
        21,
      };
      if (index == null || !validPages.contains(index)) return;
      if (index == 7 && _role != 'personal') return;
      setState(() {
        _index = index;
        final restoredModality = saved['modality']?.toString();
        if (restoredModality != null &&
            trainingModalities.containsKey(restoredModality) &&
            !gpsModalityActivities.containsKey(restoredModality) &&
            restoredModality != 'gym') {
          _dashboardModality = restoredModality;
        }
        final restoredGpsActivity = saved['gpsActivity']?.toString();
        if (restoredGpsActivity != null &&
            const {
              'Corrida',
              'Ciclismo',
              'Caminhada',
              'Trilha',
            }.contains(restoredGpsActivity)) {
          _dashboardGpsActivity = restoredGpsActivity;
        }
        _navigationHistory
          ..clear()
          ..addAll(history.where((page) => validPages.contains(page)));
        if (index == 17 && _sessionController == null) {
          _sessionController = WorkoutSessionController();
          _sessionRevision++;
        }
      });
    } catch (_) {
      // Se o estado local estiver indisponÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â­vel, o app permanece na tela inicial.
    }
  }

  void _saveNavigationState() {
    unawaited(
      Api.saveNavigationState(
        _index,
        List<int>.of(_navigationHistory),
        modality: _dashboardModality,
        gpsActivity: _dashboardGpsActivity,
      ).catchError((_) {}),
    );
  }

  Future<void> _refreshOfflineWorkouts({bool sync = false}) async {
    if (Api.isDemoSession) return;
    if (sync) {
      if (_syncingPendingWorkouts) return;
      if (mounted) setState(() => _syncingPendingWorkouts = true);
    }
    try {
      try {
        await _data;
      } catch (_) {
        // Keep the screen usable with cached device data.
      }
      if (sync && Api.currentUserId == null) {
        try {
          await Api.profile();
        } catch (_) {
          // Without an authenticated profile, keep the queue on this device.
        }
      }
      if (sync && Api.currentUserId != null) {
        final result = await Api.syncPendingWorkouts();
        if (result.synced > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.synced == 1
                    ? '1 treino sincronizado com o servidor.'
                    : '${result.synced} treinos sincronizados com o servidor.',
              ),
            ),
          );
        }
      }
      final ownerId = Api.currentUserId;
      final count = ownerId == null
          ? 0
          : await Api.pendingWorkoutCount(userId: ownerId);
      if (!mounted) return;
      setState(() {
        _offlinePendingCount = count;
        _syncingPendingWorkouts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _syncingPendingWorkouts = false);
    }
  }

  Widget _offlineStatusBanner() => Container(
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: stitchOrange.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: stitchOrange.withValues(alpha: .24)),
    ),
    child: Row(
      children: [
        Icon(
          _offlinePendingCount > 0
              ? Icons.cloud_upload_outlined
              : Icons.wifi_off,
          color: stitchOrange,
          size: 17,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            _offlinePendingCount > 0
                ? '$_offlinePendingCount treino(s) aguardando sincroniza\u00e7\u00e3o.'
                : 'Sem conex\u00e3o. Os dados salvos neste dispositivo continuam dispon\u00edveis.',
            style: const TextStyle(color: stitchPeach, fontSize: 12),
          ),
        ),
        if (_offlinePendingCount > 0)
          TextButton.icon(
            onPressed: _syncingPendingWorkouts
                ? null
                : () => _refreshOfflineWorkouts(sync: true),
            icon: _syncingPendingWorkouts
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 17),
            label: const Text('SINCRONIZAR'),
          ),
      ],
    ),
  );
  Map<int, String> get _visibleModules => Map.fromEntries(
    appModules.entries.where(
      (entry) => (entry.key != 7 || _role == 'personal'),
    ),
  );

  void _setRole(dynamic role) {
    final nextRole = role?.toString();
    if (_role == nextRole) return;
    _role = nextRole;
    if (mounted) setState(() {});
  }

  Future<List<dynamic>> _load() async {
    if (Api.isDemoSession) {
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
              'name': 'Jo\u00E3o Silva',
              'experienceLevel': 'intermediate',
            },
        },
        {
          'totalSessions': 4,
          'totalVolume': 14280,
          'totalLiftedVolumeKg': 38450,
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
        [
          {
            'id': 'preview-goal',
            'title': 'Treinar 16 vezes no mês',
            'category': 'workout',
            'metric': 'sessions',
            'targetValue': 16,
            'currentValue': 12,
            'status': 'active',
          },
        ],
      ];
    }
    final profile = await Api.profile();
    _setRole(profile['role']);
    if (profile['role'] == 'personal') {
      final athletes = await Api.athletes().catchError(
        (_) => <Map<String, dynamic>>[],
      );
      _selectedAthleteId ??= athletes.isEmpty
          ? null
          : athletes.first['id']?.toString();
      final feed = Api.feed().catchError((_) => <String, dynamic>{'posts': []});
      final goals = Api.get(
        '/api/goals?status=active',
      ).catchError((_) => <dynamic>[]);
      return [
        profile,
        <String, dynamic>{},
        <String, dynamic>{},
        <Map<String, dynamic>>[],
        <Map<String, dynamic>>[],
        await feed,
        await goals,
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
    final goals = Api.get(
      '/api/goals?status=active',
    ).catchError((_) => <dynamic>[]);
    final values = await Future.wait<dynamic>([
      Api.stats('week'),
      Api.stats('month'),
      Api.sessions(),
      plans,
      feed,
      goals,
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

  void _startDashboardModality(String modality) {
    switch (modality) {
      case 'gym':
        _startWorkout();
        return;
      case 'running':
        _dashboardGpsActivity = 'Corrida';
        _navigateTo(18);
        return;
      case 'cycling':
        _dashboardGpsActivity = 'Ciclismo';
        _navigateTo(18);
        return;
      case 'walking':
        _dashboardGpsActivity = 'Caminhada';
        _navigateTo(18);
        return;
      case 'hiking':
        _dashboardGpsActivity = 'Trilha';
        _navigateTo(18);
        return;
      default:
        if (!trainingModalities.containsKey(modality)) {
          _openWorkoutBuilder();
          return;
        }
        _dashboardModality = modality;
        setState(() {
          _navigationHistory.add(_index);
          _index = 21;
        });
        _saveNavigationState();
    }
  }

  void _startWorkoutWithExercises(List<Map<String, dynamic>>? exercises) {
    final current = _sessionController;
    if (current == null || current.saved) {
      current?.dispose();
      _sessionController = WorkoutSessionController(
        plannedExercises: exercises,
        athleteId: _role == 'personal' ? _selectedAthleteId : null,
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
    unawaited(_refreshOfflineWorkouts());
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
        onStartModality: _startDashboardModality,
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
    paymentReturnLink.removeListener(_handlePaymentReturn);
    _appLifecycleListener.dispose();
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
          if (!wide) ...[
            const Brand(),
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Menu de navegação',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                icon: const Icon(Icons.menu, color: softText),
              ),
            ),
          ] else
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
                    hintText: 'Buscar uma \u00E1rea do WeGYM...',
                    hintStyle: TextStyle(color: softText, fontSize: 11),
                    prefixIcon: Icon(Icons.search, color: softText, size: 18),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
            ),
          const Spacer(),
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
              final locationProfile = profile['role'] == 'personal'
                  ? personal
                  : athlete;
              final location =
                  [
                        locationProfile['city']?.toString().trim(),
                        locationProfile['state']
                            ?.toString()
                            .trim()
                            .toUpperCase(),
                      ]
                      .whereType<String>()
                      .where((part) => part.isNotEmpty)
                      .join(' • ');
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
                    Text(
                      location.isEmpty
                          ? 'Localização não informada'
                          : 'WeGYM Club • $location',
                      style: const TextStyle(color: lightText, fontSize: 11),
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
                    onSelected: (value) {
                      if (value == -1) {
                        unawaited(_logoutFromProfileMenu());
                      } else {
                        _navigateTo(value);
                      }
                    },
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
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: -1,
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18),
                            SizedBox(width: 10),
                            Text('Sair da conta'),
                          ],
                        ),
                      ),
                    ],
                    child: ProfileAvatar(
                      name: name,
                      imageUrl:
                          (profile['avatarUrl'] ?? profile['avatarPlaceholder'])
                              ?.toString(),
                      radius: 15,
                    ),
                  ),
                ],
              );
            },
          ),
          if (wide)
            Builder(
              builder: (drawerContext) => IconButton(
                tooltip: 'Menu de navega\u00e7\u00e3o',
                onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                icon: const Icon(Icons.menu, color: softText),
              ),
            ),
        ],
      ),
    ),
  );
  Widget _navigationDrawer() {
    final routes = _DesktopSidebar.routes.where(
      (route) => (route.page != 7 || _role == 'personal'),
    );
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 18),
            child: Row(
              children: [
                const Expanded(child: Brand()),
                IconButton(
                  tooltip: 'Fechar menu',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: softText),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 42,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openWorkoutBuilder();
                },
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
              children: routes.map((route) {
                final selected = route.page == _index;
                return ListTile(
                  dense: true,
                  minLeadingWidth: 24,
                  selected: selected,
                  selectedTileColor: stitchSurfaceHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  leading: Icon(
                    route.icon,
                    size: 18,
                    color: selected ? accent : softText,
                  ),
                  title: Text(
                    route.label,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected ? lightText : softText,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateTo(route.page);
                  },
                );
              }).toList(),
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
    );
  }

  Future<void> _logoutFromProfileMenu() async {
    await Api.logout();
    if (!mounted) return;
    _navigationHistory.clear();
    setState(() => _index = 0);
    widget.onLogout();
  }

  Widget _page() {
    if (_index == 0) return _homePage();
    if (_index == 1) {
      return HistoryPage(key: ValueKey(_revision), preview: Api.isDemoSession);
    }
    if (_index == 2) {
      return WorkoutBuilderPage(
        onStartSession: _startWorkout,
        onStartPlannedSession: _startWorkoutWithExercises,
        onSessionSaved: () => setState(() => _revision++),
        onAthleteSelected: (id) => _selectedAthleteId = id,
      );
    }
    if (_index == 18) {
      return GpsSessionPage(
        preview: Api.isDemoSession,
        initialActivity: _dashboardGpsActivity,
        athleteId: _role == 'personal' ? _selectedAthleteId : null,
        onSaved: () => setState(() => _revision++),
        onBack: _goBack,
      );
    }
    if (_index == 21) {
      return ModalitySessionPage(
        preview: Api.isDemoSession,
        initialModality: _dashboardModality,
        athleteId: _role == 'personal' ? _selectedAthleteId : null,
        onSaved: () => setState(() => _revision++),
      );
    }
    if (_index == 19) return const BleMonitorPage();
    if (_index == 17) {
      final controller = _sessionController;
      if (controller == null) return _homePage();
      return WorkoutSessionPage(
        key: ValueKey('session-$_sessionRevision'),
        preview: Api.isDemoSession,
        controller: controller,
        onExit: _exitWorkout,
        onSaved: () => unawaited(_reload()),
      );
    }
    if (_visibleModules.containsKey(_index)) {
      return FigmaModulePage(
        key: ValueKey(_index),
        module: _visibleModules[_index]!,
        onNavigate: _navigateTo,
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
        drawer: Drawer(
          key: const ValueKey('navigation-drawer'),
          width: 288,
          backgroundColor: stitchSidebar,
          child: _navigationDrawer(),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Row(
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
                        if (_offlinePendingCount > 0 || Api.isOfflineMode)
                          _offlineStatusBanner(),
                        if (_sessionController != null &&
                            !_sessionController!.saved &&
                            _index != 17)
                          _activeSessionBanner(_sessionController!),
                        Expanded(child: _page()),
                      ],
                    ),
                  ),
                ],
              ),
              if (!wide || _index == 2)
                DraggableAiAssistant(
                  onPressed: () => showAiCoachSheet(
                    context,
                    onStartWorkout: _role == 'atleta'
                        ? _startWorkoutWithExercises
                        : null,
                  ),
                ),
            ],
          ),
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
    _SidebarRoute('Atividade GPS', Icons.location_on_outlined, 18),
    _SidebarRoute('Wearables & Sensores', Icons.bluetooth_searching, 19),
    _SidebarRoute('Conquistas', Icons.military_tech, 20),
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
                key: const ValueKey('desktop-sidebar-scroll'),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: routes
                    .where((route) => (route.page != 7 || personalAccount))
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
                      _HistoryPageState._sessionModality(
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

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.preview = false});
  final bool preview;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  bool _isPersonal = false;
  String? _athleteId;
  String _athleteName = '';
  String? _error;
  List<Map<String, dynamic>> _athletes = [];
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.preview) {
        _isPersonal = await Api.previewRole() == 'personal';
        if (_isPersonal) {
          _athletes = [
            {'id': 'preview-athlete-mariana', 'name': 'Mariana Costa'},
            {'id': 'preview-athlete-pedro', 'name': 'Pedro Almeida'},
          ];
          _athleteId ??= _athletes.first['id'] as String;
          _athleteName =
              _athletes.firstWhere((a) => a['id'] == _athleteId)['name']
                  as String;
        }
        _sessions = [
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
            'completedAt': 'H\u00e1 2 dias',
          },
        ];
      } else {
        final profile = await Api.profile();
        _isPersonal = profile['role'] == 'personal';
        if (_isPersonal) {
          _athletes = await Api.athletes();
          if (_athletes.isEmpty) {
            _athleteId = null;
            _sessions = [];
          } else {
            if (!_athletes.any((a) => a['id']?.toString() == _athleteId)) {
              _athleteId = _athletes.first['id']?.toString();
            }
            final selected = _athletes.firstWhere(
              (a) => a['id']?.toString() == _athleteId,
            );
            _athleteName = selected['name']?.toString() ?? 'Atleta';
            _sessions = await Api.sessions(athleteId: _athleteId);
          }
        } else {
          _sessions = await Api.sessions();
        }
      }
    } catch (error) {
      _error = error.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _selectAthlete(String? id) async {
    if (id == null || id == _athleteId) return;
    setState(() {
      _athleteId = id;
      _athleteName =
          _athletes
              .firstWhere((a) => a['id']?.toString() == id)['name']
              ?.toString() ??
          'Atleta';
      _loading = true;
    });
    if (!widget.preview) {
      try {
        _sessions = await Api.sessions(athleteId: id);
        _error = null;
      } catch (error) {
        _error = error.toString();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: accent));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'N\u00e3o foi poss\u00edvel carregar o hist\u00f3rico: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: softText),
          ),
        ),
      );
    }
    final totalSeconds = _sessions.fold<int>(
      0,
      (sum, item) => sum + amount(item['durationSec']).round(),
    );
    final lastSession = _sessions.isEmpty
        ? '\u2014'
        : _sessionDate(_sessions.first['completedAt']);
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
                  eyebrow: 'WEGYM PERFORMANCE OS  \u2022  ATIVIDADE',
                  title: 'Hist\u00f3rico de treinos',
                  subtitle:
                      'Acompanhe sess\u00f5es conclu\u00eddas e a consist\u00eancia da rotina.',
                ),
                if (_isPersonal) ...[
                  const SizedBox(height: 12),
                  StitchSection(
                    title: 'ATLETA',
                    icon: Icons.person_search,
                    child: _athletes.isEmpty
                        ? const Text(
                            'Vincule um aluno para consultar o hist\u00f3rico de atividades.',
                            style: TextStyle(color: softText),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: _athleteId,
                            decoration: const InputDecoration(
                              labelText: 'Consultar hist\u00f3rico de',
                            ),
                            items: _athletes
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a['id']?.toString(),
                                    child: Text(
                                      a['name']?.toString() ?? 'Atleta',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _selectAthlete,
                          ),
                  ),
                ],
                if (_isPersonal && _athleteId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Exibindo atividades de $_athleteName.',
                      style: const TextStyle(color: stitchMuted, fontSize: 11),
                    ),
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
                            label: 'SESS\u00d5ES REGISTRADAS',
                            value: _sessions.length.toString(),
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
                            label: 'SESS\u00c3O MAIS RECENTE',
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
                  title: 'Sess\u00f5es recentes',
                  icon: Icons.history,
                  child: _sessions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Center(
                            child: Text(
                              _isPersonal && _athleteId == null
                                  ? 'Nenhum aluno vinculado a este Personal.'
                                  : 'As sess\u00f5es aparecer\u00e3o aqui depois que o atleta concluir um treino.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: softText),
                            ),
                          ),
                        )
                      : Column(
                          children: _sessions.map((session) {
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
                                          _sessionDate(session['completedAt']),
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
  }

  static String _sessionModality(dynamic value) =>
      switch ((value ?? '').toString().trim().toLowerCase()) {
        'musculacao' ||
        'muscula\u00e7\u00e3o' ||
        'strength' => 'Muscula\u00e7\u00e3o',
        'corrida' || 'running' => 'Corrida',
        'cycling' || 'ciclismo' => 'Ciclismo',
        'walking' || 'caminhada' => 'Caminhada',
        final value when value.isEmpty => 'Treino',
        final value => value[0].toUpperCase() + value.substring(1),
      };
  static String _sessionDate(dynamic value) {
    final raw = (value ?? '').toString();
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return raw.isEmpty ? 'Data n\u00e3o informada' : raw;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

class DraggableAiAssistant extends StatefulWidget {
  const DraggableAiAssistant({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<DraggableAiAssistant> createState() => _DraggableAiAssistantState();
}

class _DraggableAiAssistantState extends State<DraggableAiAssistant> {
  Offset? _position;
  bool _compact = false;

  static const double _expandedWidth = 204;
  static const double _compactWidth = 104;
  static const double _height = 56;
  static const double _edge = 12;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = _compact ? _compactWidth : _expandedWidth;
      final maxLeft = (constraints.maxWidth - width - _edge)
          .clamp(_edge, double.infinity)
          .toDouble();
      final maxTop = (constraints.maxHeight - _height - _edge)
          .clamp(72.0, double.infinity)
          .toDouble();
      final position = _position ?? Offset(maxLeft, maxTop);
      final left = position.dx.clamp(_edge, maxLeft).toDouble();
      final top = position.dy.clamp(72.0, maxTop).toDouble();

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: left,
            top: top,
            child: GestureDetector(
              key: const ValueKey('wegym-ai-coach-drag-handle'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) => setState(() {
                _position = Offset(
                  left + details.delta.dx,
                  top + details.delta.dy,
                );
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _compact ? 56 : 156,
                    height: _height,
                    child: Material(
                      color: accent,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 7,
                      shadowColor: accent.withValues(alpha: .35),
                      child: InkWell(
                        key: const ValueKey('wegym-ai-coach-button'),
                        onTap: widget.onPressed,
                        borderRadius: BorderRadius.circular(18),
                        child: Center(
                          child: _compact
                              ? const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.black,
                                  size: 22,
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.black,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'ASSISTENTE IA',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: stitchSurfaceLow,
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: const ValueKey('wegym-ai-coach-resize'),
                      tooltip: _compact
                          ? 'Ampliar bot\u00e3o do assistente'
                          : 'Diminuir bot\u00e3o do assistente',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 42,
                        height: 42,
                      ),
                      onPressed: () => setState(() {
                        _compact = !_compact;
                        _position = Offset(left, top);
                      }),
                      icon: Icon(
                        _compact ? Icons.open_in_full : Icons.remove,
                        color: lightText,
                        size: 18,
                      ),
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
}
