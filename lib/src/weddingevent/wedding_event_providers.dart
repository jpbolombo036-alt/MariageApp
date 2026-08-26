import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'wedding_event_api.dart';

/// Client API événements de mariage (singleton partagé via Riverpod).
final weddingEventApiProvider = Provider<WeddingEventApi>((ref) {
  return WeddingEventApi(api: ref.watch(apiClientProvider));
});