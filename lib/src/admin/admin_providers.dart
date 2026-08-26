import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'admin_api.dart';

/// Client API admin (singleton partagé via Riverpod).
final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(api: ref.watch(apiClientProvider));
});