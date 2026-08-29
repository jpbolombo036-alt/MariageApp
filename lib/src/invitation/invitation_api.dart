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
  });

  final int id;
  final int weddingId;
  final int guestId;
  final String invitationCode;
  final String status;
  final String? sentAt;
  final String? lastSentAt;

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        guestId: ((json['guestId'] as num?) ?? 0).toInt(),
        invitationCode: json['invitationCode'] as String? ?? '',
        status: json['status'] as String? ?? 'DRAFT',
        sentAt: json['sentAt'] as String?,
        lastSentAt: json['lastSentAt'] as String?,
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
