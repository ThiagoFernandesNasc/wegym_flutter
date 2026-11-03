import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart'
    as platform;

Future<bool> canInstallPwa() => platform.canInstallPwa();
Future<bool> isPwaStandalone() => platform.isPwaStandalone();
Future<bool> installPwa() => platform.installPwa();
