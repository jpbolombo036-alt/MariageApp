import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'invitation_api.dart';

/// Client API invitations (singleton partagé via Riverpod).
final invitationApiProvider = Provider<InvitationApi>((ref) {
  return InvitationApi(api: ref.watch(apiClientProvider));
});