import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'table_api.dart';

/// Client API tables + affectations (singleton partagé via Riverpod).
final tableApiProvider = Provider<TableApi>((ref) {
  return TableApi(api: ref.watch(apiClientProvider));
});