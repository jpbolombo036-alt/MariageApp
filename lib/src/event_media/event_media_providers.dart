import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'event_media_api.dart';

final eventMediaApiProvider = Provider<EventMediaApi>((ref) {
  return EventMediaApi(api: ref.watch(apiClientProvider));
});
