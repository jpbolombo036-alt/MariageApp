import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../auth/auth_providers.dart';

/// Réponse RSVP projetée par invité (`RsvpSummaryResponse` du backend).
class GuestRsvp {
  const GuestRsvp({
    required this.invitationId,
    required this.guestId,
    required this.status,
    this.numberOfAttendees,
    this.respondedAt,
  });

  final int invitationId;
  final int guestId;
  final String status;
  final int? numberOfAttendees;
  final String? respondedAt;

  factory GuestRsvp.fromJson(Map<String, dynamic> json) => GuestRsvp(
        invitationId: (json['invitationId'] as num?)?.toInt() ?? 0,
        guestId: (json['guestId'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'PENDING',
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt(),
        respondedAt: json['respondedAt'] as String?,
      );
}

/// Client API des réponses RSVP (lecture seule).
class RsvpApi {
  RsvpApi({required this.api});

  final ApiClient api;

  /// Liste des RSVP d'un événement (`GET /api/events/{id}/rsvps` — alias
  /// de l'ancienne route `/api/weddings/{id}/rsvps`).
  Future<List<GuestRsvp>> listForWedding(int weddingId) async {
    final raw = await api.getList(
      '${ApiConfig.eventsPath}/$weddingId/rsvps',
    );
    return raw
        .whereType<Map<String, dynamic>>()
        .map(GuestRsvp.fromJson)
        .toList();
  }
}

/// Provider du client RSVP.
final rsvpApiProvider = Provider<RsvpApi>((ref) {
  return RsvpApi(api: ref.watch(apiClientProvider));
});