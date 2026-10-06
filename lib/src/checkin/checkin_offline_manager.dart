import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mariageplus_app/src/api/api_client.dart';
import 'package:mariageplus_app/src/api/api_config.dart';
import 'package:mariageplus_app/src/auth/auth_providers.dart';
import 'package:mariageplus_app/src/checkin/checkin_api.dart';
import 'package:mariageplus_app/src/checkin/checkin_offline_models.dart';

/// Gestionnaire du mode hors ligne avec détection automatique du réseau.
///
/// L'état est un `bool` (`true` = en ligne). Le provider est un
/// `StateNotifierProvider` pour que les écrans puissent réagir aux
/// transitions réseau (ex. déclenchement auto de la sync à la retrouvée).
class OfflineCheckInManager extends StateNotifier<bool> {
  OfflineCheckInManager(this._api, this._connectivity) : super(false) {
    _init();
  }

  final ApiClient _api;
  final Connectivity _connectivity;
  late final CheckInApi _checkInApi = CheckInApi(api: _api);

  void _init() {
    checkConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      final online = _isOnlineFromResults(results);
      if (online != state) {
        state = online;
      }
    });
  }

  bool _isOnlineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Relecture manuelle de l'état réseau (appel au démarrage ou à la demande).
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final online = _isOnlineFromResults(results);
    state = online;
    return online;
  }

  Future<bool> downloadOfflinePack(int eventId) async {
    try {
      final json = await _api.getJson(
        '${ApiConfig.checkinsPath}/event/$eventId/offline-pack',
      );
      await OfflineStorage.saveOfflinePack(eventId, json);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CheckInScan?> lookupLocally(String publicToken, int eventId) async {
    return OfflineStorage.lookupLocally(publicToken, eventId);
  }

  Future<void> queueScan(QueuedOfflineScan scan, int eventId) async {
    await OfflineStorage.queueScan(eventId, scan);
  }

  Future<List<QueuedOfflineScan>> getQueuedScans(int eventId) async {
    return OfflineStorage.getQueuedScans(eventId);
  }

  Future<void> clearQueue(int eventId) async {
    await OfflineStorage.clearQueue(eventId);
  }

  Future<SyncResult> syncQueuedScans(int eventId) async {
    final queued = await getQueuedScans(eventId);
    if (queued.isEmpty) {
      return SyncResult(synced: true, accepted: 0, rejected: 0);
    }

    try {
      final response = await _checkInApi.syncOfflineScans(
        eventId: eventId,
        scans: queued
            .map((s) => OfflineScanItem(
                  qrToken: s.qrToken,
                  numberOfAttendees: s.numberOfAttendees,
                  scannedAt: s.scannedAt,
                  deviceId: s.deviceId,
                  sequence: s.sequence,
                ))
            .toList(),
      );

      await clearQueue(eventId);
      await downloadOfflinePack(eventId);

      return SyncResult(
        synced: true,
        accepted: response.accepted,
        rejected: response.rejected,
      );
    } catch (_) {
      return SyncResult(synced: false, accepted: 0, rejected: 0);
    }
  }
}

class OfflineStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _packPrefix = 'offline_pack_';
  static const String _queuePrefix = 'offline_queue_';

  static Future<void> saveOfflinePack(int eventId, Map<String, dynamic> pack) async {
    await _storage.write(key: '$_packPrefix$eventId', value: jsonEncode(pack));
  }

  static Future<Map<String, dynamic>?> getOfflinePack(int eventId) async {
    final raw = await _storage.read(key: '$_packPrefix$eventId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> queueScan(int eventId, QueuedOfflineScan scan) async {
    final queue = await getQueuedScans(eventId);
    queue.add(scan);
    await _storage.write(
      key: '$_queuePrefix$eventId',
      value: jsonEncode(queue.map((s) => s.toJson()).toList()),
    );
  }

  static Future<List<QueuedOfflineScan>> getQueuedScans(int eventId) async {
    final raw = await _storage.read(key: '$_queuePrefix$eventId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(QueuedOfflineScan.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearQueue(int eventId) async {
    await _storage.write(key: '$_queuePrefix$eventId', value: '[]');
  }

  static Future<CheckInScan?> lookupLocally(String publicToken, int eventId) async {
    final pack = await getOfflinePack(eventId);
    if (pack == null) return null;
    final invitations = (pack['invitations'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    Map<String, dynamic>? inv;
    for (final i in invitations) {
      if (i['publicToken'] == publicToken) {
        inv = i;
        break;
      }
    }
    if (inv == null) return null;

    return CheckInScan(
      guestName: inv['guestName'] as String? ?? '',
      weddingDisplayName: pack['eventName'] as String? ?? '',
      invitationStatus: inv['invitationStatus'] as String? ?? '',
      rsvpStatus: inv['rsvpStatus'] as String?,
      expectedAttendees: (inv['expectedAttendees'] as num?)?.toInt() ?? 0,
      checkedInAttendees: (inv['checkedInAttendees'] as num?)?.toInt() ?? 0,
      remainingAttendees: (inv['remainingAttendees'] as num?)?.toInt() ?? 0,
      canCheckIn: inv['canCheckIn'] as bool? ?? false,
      tableName: inv['tableName'] as String?,
      drinkChoice: inv['drinkChoice'] as String?,
      publicToken: inv['publicToken'] as String?,
      invitationCode: inv['invitationCode'] as String?,
      hasCard: inv['hasCard'] as bool?,
      eventName: pack['eventName'] as String?,
      eventDate: pack['eventDate'] as String?,
      eventTime: pack['eventTime'] as String?,
      eventVenue: pack['eventVenue'] as String?,
    );
  }
}

class SyncResult {
  final bool synced;
  final int accepted;
  final int rejected;
  SyncResult({required this.synced, required this.accepted, required this.rejected});
}

final offlineCheckInManagerProvider =
    StateNotifierProvider<OfflineCheckInManager, bool>((ref) {
  final api = ref.watch(apiClientProvider);
  return OfflineCheckInManager(api, Connectivity());
});