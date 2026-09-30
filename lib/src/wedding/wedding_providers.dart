import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'wedding_api.dart';

/// Client API weddings/événements (singleton partagé via Riverpod).
final weddingApiProvider = Provider<WeddingApi>((ref) {
  return WeddingApi(api: ref.watch(apiClientProvider));
});

/// Incrémenté après une création ou une suppression d'événement.
final weddingListRevisionProvider =
    NotifierProvider<WeddingListRevision, int>(WeddingListRevision.new);

class WeddingListRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}