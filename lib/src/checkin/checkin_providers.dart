import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'checkin_api.dart';

/// Client API RSVP public + check-in (singleton partagé via Riverpod).
final checkInApiProvider = Provider<CheckInApi>((ref) {
  return CheckInApi(api: ref.watch(apiClientProvider));
});