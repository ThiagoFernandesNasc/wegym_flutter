import 'dart:js_interop';

@JS('window.wegymPwaCanInstall')
external JSBoolean _canInstall();

@JS('window.wegymPwaIsStandalone')
external JSBoolean _isStandalone();

@JS('window.wegymPwaInstall')
external JSPromise<JSBoolean> _install();

Future<bool> canInstallPwa() async => _canInstall().toDart;
Future<bool> isPwaStandalone() async => _isStandalone().toDart;
Future<bool> installPwa() async => (await _install().toDart).toDart;
