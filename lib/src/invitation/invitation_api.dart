import '../api/api_client.dart';
import '../api/api_config.dart';

/// Invitation administrative (`InvitationResponse`).
/// Le `publicToken` (donnée sensible d'accès public) n'est PAS exposé par le
/// backend dans cette réponse — seul le QR (représentation) est renvoyé.
class Invitation {
  const Invitation({
    required this.id,
    required this.weddingId,
    required this.guestId,
    required this.invitationCode,
    required this.status,
    this.sentAt,
    this.lastSentAt,
    this.reminderCount = 0,
    this.openedAt,
  });

  final int id;
  final int weddingId;
  final int guestId;
  final String invitationCode;
  final String status;
  final String? sentAt;
  final String? lastSentAt;
  final int reminderCount;
  final String? openedAt;

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        guestId: ((json['guestId'] as num?) ?? 0).toInt(),
        invitationCode: json['invitationCode'] as String? ?? '',
        status: json['status'] as String? ?? 'DRAFT',
        sentAt: json['sentAt'] as String?,
        lastSentAt: json['lastSentAt'] as String?,
        reminderCount: (json['reminderCount'] as num?)?.toInt() ?? 0,
        openedAt: json['openedAt'] as String?,
      );
}

/// Requête de création d'une invitation (`CreateInvitationRequest`).
/// Le client fournit uniquement le `guestId`.
class CreateInvitationRequest {
  CreateInvitationRequest({required this.guestId});

  final int guestId;

  Map<String, dynamic> toJson() => {'guestId': guestId};
}

/// QR code (`QrCodeResponse`) : data URI PNG affichable.
class QrCode {
  const QrCode({required this.dataUri});

  final String dataUri;
}

/// Client API du module invitations (+ accès public).
class InvitationApi {
  InvitationApi({required this.api});

  final ApiClient api;

  String _path(int weddingId) =>
      '${ApiConfig.eventsPath}/$weddingId/invitations';

  /// Liste paginée des invitations (`GET .../invitations`).
  Future<List<Invitation>> list(int weddingId, {int page = 0, int size = 25}) async {
    final raw = await api.getList(
      _path(weddingId),
      queryParameters: {'page': page, 'size': size},
    );
    return raw.whereType<Map<String, dynamic>>().map((e) => Invitation.fromJson(e)).toList();
  }

  /// Envoi d'une invitation (`POST .../invitations/{id}/send`).
  Future<SendInvitationResponse> send(int weddingId, int invitationId) async {
    final json = await api.postJson('${_path(weddingId)}/$invitationId/send', {});
    return SendInvitationResponse.fromJson(json);
  }

  /// Renvoi d'une invitation (`POST .../invitations/{id}/resend`).
  Future<SendInvitationResponse> resend(int weddingId, int invitationId) async {
    final json = await api.postJson('${_path(weddingId)}/$invitationId/resend', {});
    return SendInvitationResponse.fromJson(json);
  }

  /// Annulation d'une invitation (`POST .../invitations/{id}/cancel`).
  Future<void> cancel(int weddingId, int invitationId) async {
    await api.postNoContent('${_path(weddingId)}/$invitationId/cancel');
  }

  /// Création d'une invitation (`POST .../invitations`).
  Future<Invitation> create(int weddingId, CreateInvitationRequest request) async {
    final json = await api.postJson(_path(weddingId), request.toJson());
    return Invitation.fromJson(json);
  }

  /// QR code d'une invitation (`GET .../invitations/{id}/qr`).
  Future<QrCode> getQr(int weddingId, int invitationId) async {
    final json = await api.getJson(
      '${_path(weddingId)}/$invitationId/qr',
    );
    return QrCode(dataUri: json['qrDataUri'] as String? ?? '');
  }

  /// Rotation du QR (`POST .../invitations/{id}/qr/rotate`) — invalide
  /// l'ancien token et renvoie le nouveau QR.
  Future<QrCode> rotateQr(int weddingId, int invitationId) async {
    final json =
        await api.postJson('${_path(weddingId)}/$invitationId/qr/rotate', {});
    return QrCode(dataUri: json['qrDataUri'] as String? ?? '');
  }

  /// Suppression d'une invitation (`DELETE .../invitations/{id}`).
  Future<void> delete(int weddingId, int invitationId) async {
    await api.deleteRequest('${_path(weddingId)}/$invitationId');
  }

  String _bulkPath(int weddingId) => '${_path(weddingId)}/send-bulk';

  /// Démarrage d'un envoi en masse WhatsApp (`POST .../send-bulk`) —
  /// répond 202 avec le batch à suivre (traitement asynchrone backend).
  Future<BulkSendBatch> startBulkSend(
      int weddingId, BulkSendRequest request) async {
    final json = await api.postJson(_bulkPath(weddingId), request.toJson());
    return BulkSendBatch.fromJson(json);
  }

  /// Suivi d'un batch (`GET .../send-bulk/{batchId}`).
  Future<BulkSendBatch> getBulkBatch(int weddingId, int batchId) async {
    final json = await api.getJson('${_bulkPath(weddingId)}/$batchId');
    return BulkSendBatch.fromJson(json);
  }

  /// Journal détaillé d'un batch (`GET .../send-bulk/{batchId}/logs`).
  Future<List<BulkSendLog>> getBulkBatchLogs(int weddingId, int batchId,
      {int page = 0, int size = 50}) async {
    final raw = await api.getList('${_bulkPath(weddingId)}/$batchId/logs',
        queryParameters: {'page': page, 'size': size});
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BulkSendLog.fromJson)
        .toList();
  }
}

/// Réponse des endpoints send/resend (`SendInvitationResponse` backend).
class SendInvitationResponse {
  SendInvitationResponse({this.emailSent, this.publicInviteUrl});

  final bool? emailSent;
  final String? publicInviteUrl;

  factory SendInvitationResponse.fromJson(Map<String, dynamic> json) =>
      SendInvitationResponse(
        emailSent: json['emailSent'] as bool?,
        publicInviteUrl: json['publicInviteUrl'] as String?,
      );
}

/// Batch d'envoi en masse (`BulkSendBatchResponse` du backend).
/// Le traitement est asynchrone : suivre [status] jusqu'à
/// COMPLETED / FAILED en interrogeant `GET .../send-bulk/{id}`.
class BulkSendBatch {
  const BulkSendBatch({
    required this.id,
    required this.weddingId,
    required this.status,
    required this.totalCount,
    required this.sentCount,
    required this.failedCount,
    required this.skippedCount,
  });

  final int id;
  final int weddingId;
  final String status;
  final int totalCount;
  final int sentCount;
  final int failedCount;
  final int skippedCount;

  bool get isFinished => status == 'COMPLETED' || status == 'FAILED';

  factory BulkSendBatch.fromJson(Map<String, dynamic> json) => BulkSendBatch(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        status: json['status'] as String? ?? 'PENDING',
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
        sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
        failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
        skippedCount: (json['skippedCount'] as num?)?.toInt() ?? 0,
      );
}

/// Requête d'envoi en masse (`BulkSendRequest`).
/// - `invitationIds` vide = toutes les invitations éligibles ;
/// - `resend = true` = relance des invitations déjà envoyées (plafond 3) ;
/// - `onlyPendingRsvp = true` = uniquement les non-répondants.
class BulkSendRequest {
  BulkSendRequest({
    this.invitationIds = const [],
    this.resend = false,
    this.onlyPendingRsvp = false,
    this.categoryId,
  }) : channel = 'WHATSAPP';

  final String channel;
  final List<int> invitationIds;
  final bool resend;
  final bool onlyPendingRsvp;
  final int? categoryId;

  Map<String, dynamic> toJson() => {
        'channel': channel,
        'invitationIds': invitationIds,
        'resend': resend,
        'onlyPendingRsvp': onlyPendingRsvp,
        if (categoryId != null) 'categoryId': categoryId,
      };
}

/// Ligne du journal d'envoi (`NotificationLogResponse`).
class BulkSendLog {
  const BulkSendLog({
    required this.id,
    required this.invitationId,
    required this.guestId,
    required this.status,
    this.errorMessage,
  });

  final int id;
  final int invitationId;
  final int guestId;
  final String status;
  final String? errorMessage;

  factory BulkSendLog.fromJson(Map<String, dynamic> json) => BulkSendLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        invitationId: (json['invitationId'] as num?)?.toInt() ?? 0,
        guestId: (json['guestId'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? '',
        errorMessage: json['errorMessage'] as String?,
      );
}
