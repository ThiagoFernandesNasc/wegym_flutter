import 'package:flutter/foundation.dart';

final integrationReturnLink = ValueNotifier<Uri?>(null);

bool isIntegrationReturnUri(Uri uri) =>
    (uri.scheme == 'wegym' && uri.host == 'integration-return') ||
    uri.queryParameters.containsKey('integration_result');
