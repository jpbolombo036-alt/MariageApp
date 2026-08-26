import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'wedding_api.dart';

/// Client API weddings/événements (singleton partagé via Riverpod).
final weddingApiProvider = Provider<WeddingApi>((ref) {
  return WeddingApi(api: ref.watch(apiClientProvider));
});