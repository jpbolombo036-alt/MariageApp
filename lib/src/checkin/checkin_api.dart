import '../api/api_client.dart';
import '../api/api_config.dart';

/// Session publique.
class PublicSessionItem {
  const PublicSessionItem({
    required this.name,
    this.type,
    this.description,
    this.sessionDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.mapUrl,
  });

  final String name;
  final String? type;
  final String? description;
  final String? sessionDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? mapUrl;

  factory PublicSessionItem.fromJson(Map<String, dynamic> json) => PublicSessionItem(
        name: json['name'] as String? ?? '',
        type: json['type'] as String?,
        description: json['description'] as String?,
        sessionDate: json['sessionDate'] as String?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        venueName: json['venueName'] as String?,
        venueAddress: json['venueAddress'] as String?,
        city: json['city'] as String?,
        mapUrl: json['mapUrl'] as String?,
      );
}

/// Invitation publique (PublicInvitationResponse)
class PublicInvitation {
  const PublicInvitation({
    required this.guestFirstName,
    required this.guestLastName,
    required this.weddingDisplayName,
    this.couplePhotoUrl,
    this.groomPhotoUrl,
    this.bridePhotoUrl,
    this.message,
    this.eventName,
    this.eventDate,
    this.eventStartTime,
    this.eventVenue,
    this.maxAccepted,
    required this.status,
    this.rsvpStatus,
    this.rsvpNumberOfAttendees,
    this.rsvpDrinkChoice,
    this.rsvpDrinkChoices,
    this.publicToken,
    this.sessions,
  });

  final String? guestFirstName;
  final String? guestLastName;
  final String? weddingDisplayName;
  final String? couplePhotoUrl;
  final String? groomPhotoUrl;
  final String? bridePhotoUrl;
  final String? message;
  final String? eventName;
  final String? eventDate;
  final String? eventStartTime;
  final String? eventVenue;
  final int? maxAccepted;
  final String status;
  final String? rsvpStatus;
  final int? rsvpNumberOfAttendees;
  final String? rsvpDrinkChoice;
  final List<String>? rsvpDrinkChoices;
  final String? publicToken;
  final List<PublicSessionItem>? sessions;

  factory PublicInvitation.fromJson(Map<String, dynamic> json) => PublicInvitation(
        guestFirstName: json['guestFirstName'] as String?,
        guestLastName: json['guestLastName'] as String?,
        weddingDisplayName: json['weddingDisplayName'] as String?,
        couplePhotoUrl: json['couplePhotoUrl'] as String?,
        groomPhotoUrl: json['groomPhotoUrl'] as String?,
        bridePhotoUrl: json['bridePhotoUrl'] as String?,
        message: json['message'] as String?,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] as String?,
        eventStartTime: json['eventStartTime'] as String?,
        eventVenue: json['eventVenue'] as String?,
        maxAccepted: (json['maxAccepted'] as num?)?.toInt(),
        status: json['status'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String?,
        rsvpNumberOfAttendees: (json['rsvpNumberOfAttendees'] as num?)?.toInt(),
        rsvpDrinkChoice: json['rsvpDrinkChoice'] as String?,
        rsvpDrinkChoices: (json['rsvpDrinkChoices'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        publicToken: json['publicToken'] as String?,
        sessions: (json['sessions'] as List<dynamic>?)
            ?.map((e) => PublicSessionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Reponse apres soumission d'un RSVP (PublicRsvpResponse).
class PublicRsvp {
  const PublicRsvp({
    required this.invitationStatus,
    required this.rsvpStatus,
    required this.numberOfAttendees,
    this.respondedAt,
    this.drinkChoice,
    this.drinkChoices,
  });

  final String invitationStatus;
  final String rsvpStatus;
  final int numberOfAttendees;
  final String? respondedAt;
  final String? drinkChoice;
  final List<String>? drinkChoices;

  factory PublicRsvp.fromJson(Map<String, dynamic> json) => PublicRsvp(
        invitationStatus: json['invitationStatus'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String? ?? '',
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt() ?? 0,
        respondedAt: json['respondedAt'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        drinkChoices: (json['drinkChoices'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
}

/// Etat d'une invitation au scan (CheckInScanResponse).
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

  /// Scan d'un QR (POST /api/checkins/scan).
  Future<CheckInScan> scan(String qrToken) async {
    final json = await api.postJson(
      '${ApiConfig.checkinsPath}/scan',
      {'qrToken': qrToken},
    );
    return CheckInScan.fromJson(json);
  }

  /// Enregistrement d'un check-in (POST /api/checkins).
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
}

/// Resultat d'un enregistrement d'entree (CheckInResponse backend).
class CheckInResult {
  CheckInResult({
    required this.success,
    this.message,
    this.guestName,
    this.weddingDisplayName,
    this.invitationStatus,
    this.rsvpStatus,
    this.numberOfAttendees,
    this.expectedAttendees,
    this.checkedInAttendees,
    this.remainingAttendees,
    this.tableName,
  });

  final bool success;
  final String? message;
  final String? guestName;
  final String? weddingDisplayName;
  final String? invitationStatus;
  final String? rsvpStatus;
  final int? numberOfAttendees;
  final int? expectedAttendees;
  final int? checkedInAttendees;
  final int? remainingAttendees;
  final String? tableName;

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
        success: json['success'] as bool? ?? true,
        message: json['message'] as String?,
        guestName: json['guestName'] as String?,
        weddingDisplayName: json['weddingDisplayName'] as String?,
        invitationStatus: json['invitationStatus'] as String?,
        rsvpStatus: json['rsvpStatus'] as String?,
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt(),
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt(),
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt(),
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt(),
        tableName: json['tableName'] as String?,
      );
}

/// Extrait le jeton public d'invitation d'une entree de scan QR brute
/// (URL publique complete ou jeton nu).
String invitationTokenFromInput(String raw) {
  final input = raw.trim();
  final match = RegExp(r'/invitations/([A-Za-z0-9_-]+)').firstMatch(input);
  if (match != null) return match.group(1)!;
  // Sinon on considere que l'entree est deja le jeton.
  return input;
}
