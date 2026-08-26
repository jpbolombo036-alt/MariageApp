import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'dashboard_api.dart';

/// Client API dashboard (singleton partagé via Riverpod).
final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(api: ref.watch(apiClientProvider));
});