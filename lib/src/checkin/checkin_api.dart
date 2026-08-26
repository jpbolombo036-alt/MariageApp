import '../api/api_client.dart';
import '../api/api_config.dart';

/// Invitation publique (`PublicInvitationResponse`) — données minimales.
class PublicInvitation {
  const PublicInvitation({
    required this.guestFirstName,
    required this.guestLastName,
    required this.weddingDisplayName,
    this.eventType,
    required this.status,
    this.rsvpStatus,
    this.rsvpNumberOfAttendees,
  });

  final String? guestFirstName;
  final String? guestLastName;
  final String? weddingDisplayName;
  final String? eventType;
  final String status;
  final String? rsvpStatus;
  final int? rsvpNumberOfAttendees;

  factory PublicInvitation.fromJson(Map<String, dynamic> json) => PublicInvitation(
        guestFirstName: json['guestFirstName'] as String?,
        guestLastName: json['guestLastName'] as String?,
        weddingDisplayName: json['weddingDisplayName'] as String?,
        eventType: json['eventType'] as String?,
        status: json['status'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String?,
        rsvpNumberOfAttendees: (json['rsvpNumberOfAttendees'] as num?)?.toInt(),
      );
}

/// Réponse après soumission d'un RSVP (`PublicRsvpResponse`).
class PublicRsvp {
  const PublicRsvp({
    required this.invitationStatus,
    required this.rsvpStatus,
    required this.numberOfAttendees,
    this.respondedAt,
  });

  final String invitationStatus;
  final String rsvpStatus;
  final int numberOfAttendees;
  final String? respondedAt;

  factory PublicRsvp.fromJson(Map<String, dynamic> json) => PublicRsvp(
        invitationStatus: json['invitationStatus'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String? ?? '',
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt() ?? 0,
        respondedAt: json['respondedAt'] as String?,
      );
}

/// État d'une invitation au scan (`CheckInScanResponse`).
class CheckInScan {
  const CheckInScan({
    required this.guestName,
    required this.weddingDisplayName,
    required this.invitationStatus,
    required this.rsvpStatus,
    required this.expectedAttendees,
    required this.checkedInAttendees,
    required this.remainingAttendees,
    required this.canCheckIn,
  });

  final String guestName;
  final String weddingDisplayName;
  final String invitationStatus;
  final String? rsvpStatus;
  final int expectedAttendees;
  final int checkedInAttendees;
  final int remainingAttendees;
  final bool canCheckIn;

  factory CheckInScan.fromJson(Map<String, dynamic> json) => CheckInScan(
        guestName: json['guestName'] as String? ?? '',
        weddingDisplayName: json['weddingDisplayName'] as String? ?? '',
        invitationStatus: json['invitationStatus'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String?,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt() ?? 0,
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt() ?? 0,
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
        canCheckIn: json['canCheckIn'] as bool? ?? false,
      );
}

/// Résultat d'un enregistrement de check-in (`CheckInResponse`).
class CheckInResult {
  const CheckInResult({
    required this.checkInId,
    required this.guestName,
    required this.weddingDisplayName,
    required this.invitationStatus,
    this.rsvpStatus,
    required this.numberOfAttendees,
    required this.expectedAttendees,
    required this.checkedInAttendees,
    required this.remainingAttendees,
    this.checkedInAt,
  });

  final int checkInId;
  final String guestName;
  final String weddingDisplayName;
  final String invitationStatus;
  final String? rsvpStatus;
  final int numberOfAttendees;
  final int expectedAttendees;
  final int checkedInAttendees;
  final int remainingAttendees;
  final String? checkedInAt;

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
        checkInId: (json['checkInId'] as num?)?.toInt() ?? 0,
        guestName: json['guestName'] as String? ?? '',
        weddingDisplayName: json['weddingDisplayName'] as String? ?? '',
        invitationStatus: json['invitationStatus'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String?,
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt() ?? 0,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt() ?? 0,
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt() ?? 0,
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
        checkedInAt: json['checkedInAt'] as String?,
      );
}

/// Client API du module RSVP public + check-in.
class CheckInApi {
  CheckInApi({required this.api});

  final ApiClient api;

  /// Consultation publique d'une invitation par token.
  Future<PublicInvitation> getPublicInvitation(String publicToken) async {
    final json = await api.getJson(
      '${ApiConfig.publicInvitationsPath}/$publicToken',
    );
    return PublicInvitation.fromJson(json);
  }

  /// Soumission RSVP public (ACCEPTED / DECLINED + nombre).
  Future<PublicRsvp> submitRsvp({
    required String publicToken,
    required String status,
    required int numberOfAttendees,
  }) async {
    final json = await api.postJson(
      '${ApiConfig.publicInvitationsPath}/$publicToken/rsvp',
      {'status': status, 'numberOfAttendees': numberOfAttendees},
    );
    return PublicRsvp.fromJson(json);
  }

  /// Scan d'un QR (`POST /api/checkins/scan`).
  Future<CheckInScan> scan(String qrToken) async {
    final json = await api.postJson(
      '${ApiConfig.checkinsPath}/scan',
      {'qrToken': qrToken},
    );
    return CheckInScan.fromJson(json);
  }

  /// Enregistrement d'un check-in (`POST /api/checkins`).
  Future<CheckInResult> checkIn({
    required String qrToken,
    required int numberOfAttendees,
  }) async {
    final json = await api.postJson(
      ApiConfig.checkinsPath,
      {'qrToken': qrToken, 'numberOfAttendees': numberOfAttendees},
    );
    return CheckInResult.fromJson(json);
  }

  /// Annulation d'un check-in (`DELETE /api/checkins/{checkInId}`) — la place est recréditée.
  Future<void> cancelCheckIn(int checkInId) async {
    await api.deleteRequest('${ApiConfig.checkinsPath}/$checkInId');
  }
}

/// Extrait le jeton public d'un QR : URL (`.../invitations/{token}`) ou jeton brut.
String invitationTokenFromInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }
  return trimmed;
}