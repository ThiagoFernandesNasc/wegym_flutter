import 'package:flutter/foundation.dart';

final paymentReturnLink = ValueNotifier<Uri?>(null);

bool isPaymentReturnUri(Uri uri) =>
    (uri.scheme == 'wegym' && uri.host == 'payment-return') ||
    uri.queryParameters.containsKey('payment_return');
