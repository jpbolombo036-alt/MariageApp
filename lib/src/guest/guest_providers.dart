import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'guest_api.dart';

/// Client API invités + catégories (singleton partagé via Riverpod).
final guestApiProvider = Provider<GuestApi>((ref) {
  return GuestApi(api: ref.watch(apiClientProvider));
});