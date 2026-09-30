import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'dashboard_api.dart';

/// Client API dashboard (singleton partagé via Riverpod).
final dashboardApiProvider = Provider<DashboardApi>((ref) {
  return DashboardApi(api: ref.watch(apiClientProvider));
});

/// Tableau de bord d'un événement (`GET /api/events/{id}/dashboard`).
///
/// Utilisé par les cartes de la liste « Mes événements » pour afficher la
/// progression des confirmations (« 142 / 200 confirmés »). Le résultat est
/// mis en cache par identifiant d'événement : une carte déjà chargée ne
/// redéclenche pas d'appel réseau au rebuild.
final eventDashboardProvider =
    FutureProvider.family<Dashboard, int>((ref, eventId) async {
  return ref.watch(dashboardApiProvider).getForWedding(eventId);
});