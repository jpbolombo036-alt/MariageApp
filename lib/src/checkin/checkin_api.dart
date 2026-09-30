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
    this.tableName,
    this.drinkChoice,
    this.publicToken,
    this.invitationCode,
    this.hasCard,
    this.checkedInAt,
    this.eventName,
    this.eventDate,
    this.eventTime,
    this.eventVenue,
  });

  final String guestName;
  final String weddingDisplayName;
  final String invitationStatus;
  final String? rsvpStatus;
  final int expectedAttendees;
  final int checkedInAttendees;
  final int remainingAttendees;
  final bool canCheckIn;
  final String? tableName;
  final String? drinkChoice;
  final String? publicToken;
  final String? invitationCode;
  final bool? hasCard;
  final String? checkedInAt;
  final String? eventName;
  final String? eventDate;
  final String? eventTime;
  final String? eventVenue;

  factory CheckInScan.fromJson(Map<String, dynamic> json) => CheckInScan(
        guestName: json['guestName'] as String? ?? '',
        weddingDisplayName: json['weddingDisplayName'] as String? ?? '',
        invitationStatus: json['invitationStatus'] as String? ?? '',
        rsvpStatus: json['rsvpStatus'] as String?,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt() ?? 0,
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt() ?? 0,
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
        canCheckIn: json['canCheckIn'] as bool? ?? false,
        tableName: json['tableName'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        publicToken: json['publicToken'] as String?,
        invitationCode: json['invitationCode'] as String?,
        hasCard: json['hasCard'] as bool?,
        checkedInAt: json['checkedInAt'] as String?,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] as String?,
        eventTime: json['eventTime'] as String?,
        eventVenue: json['eventVenue'] as String?,
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

  /// Scan d'un QR (`POST /api/checkins/scan`). Le mariage est obligatoire.
  Future<CheckInScan> scan({
    required int weddingId,
    required String qrToken,
  }) async {
    final json = await api.postJson(
      '${ApiConfig.checkinsPath}/scan',
      {'weddingId': weddingId, 'qrToken': qrToken},
    );
    return CheckInScan.fromJson(json);
  }

  /// Enregistrement d'un check-in (`POST /api/checkins`).
  Future<CheckInResult> checkIn({
    required int weddingId,
    required String qrToken,
    required int numberOfAttendees,
  }) async {
    final json = await api.postJson(
      ApiConfig.checkinsPath,
      {
        'weddingId': weddingId,
        'qrToken': qrToken,
        'numberOfAttendees': numberOfAttendees,
      },
    );
    return CheckInResult.fromJson(json);
  }

  /// Annule une entrée (`DELETE /api/checkins/{id}`).
  Future<void> cancelCheckIn(int checkInId) async {
    await api.deleteRequest('${ApiConfig.checkinsPath}/$checkInId');
  }

  /// Invités déjà présents (`GET /api/checkins/event/{weddingId}`).
  Future<List<CheckInPresence>> listPresent(int weddingId) async {
    final raw = await api.getList('${ApiConfig.checkinsPath}/event/$weddingId');
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CheckInPresence.fromJson)
        .toList();
  }

  /// Recherche d'un invité à l'accueil (`GET .../search?q=`).
  Future<List<CheckInSearchHit>> searchGuests(int weddingId, String query) async {
    final raw = await api.getList(
      '${ApiConfig.checkinsPath}/event/$weddingId/search',
      queryParameters: {'q': query},
    );
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CheckInSearchHit.fromJson)
        .toList();
  }
}

/// Invité présent dans la salle.
class CheckInPresence {
  const CheckInPresence({
    this.invitationId,
    this.guestId,
    required this.guestName,
    required this.numberOfAttendees,
    this.tableName,
    this.drinkChoice,
    this.lastCheckedInAt,
  });

  final int? invitationId;
  final int? guestId;
  final String guestName;
  final int numberOfAttendees;
  final String? tableName;
  final String? drinkChoice;
  final String? lastCheckedInAt;

  factory CheckInPresence.fromJson(Map<String, dynamic> json) => CheckInPresence(
        invitationId: (json['invitationId'] as num?)?.toInt(),
        guestId: (json['guestId'] as num?)?.toInt(),
        guestName: json['guestName'] as String? ?? '',
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt() ?? 0,
        tableName: json['tableName'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        lastCheckedInAt: json['lastCheckedInAt'] as String?,
      );
}

/// Résultat de recherche agent.
class CheckInSearchHit {
  const CheckInSearchHit({
    required this.guestName,
    this.phone,
    this.invitationCode,
    this.invitationStatus,
    required this.canCheckIn,
    required this.remainingAttendees,
    this.expectedAttendees,
    this.checkedInAttendees,
    this.checkedInAt,
    this.publicToken,
    this.tableName,
    this.rsvpStatus,
    this.drinkChoice,
    this.hasCard,
    this.eventName,
    this.eventDate,
    this.eventTime,
    this.eventVenue,
  });

  final String guestName;
  final String? phone;
  final String? invitationCode;
  final String? invitationStatus;
  final bool canCheckIn;
  final int remainingAttendees;
  final int? expectedAttendees;
  final int? checkedInAttendees;
  final String? checkedInAt;
  final String? publicToken;
  final String? tableName;
  final String? rsvpStatus;
  final String? drinkChoice;
  final bool? hasCard;
  final String? eventName;
  final String? eventDate;
  final String? eventTime;
  final String? eventVenue;

  factory CheckInSearchHit.fromJson(Map<String, dynamic> json) => CheckInSearchHit(
        guestName: json['guestName'] as String? ?? '',
        phone: json['phone'] as String?,
        invitationCode: json['invitationCode'] as String?,
        invitationStatus: json['invitationStatus'] as String?,
        canCheckIn: json['canCheckIn'] as bool? ?? false,
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt(),
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt(),
        checkedInAt: json['checkedInAt'] as String?,
        publicToken: json['publicToken'] as String?,
        tableName: json['tableName'] as String?,
        rsvpStatus: json['rsvpStatus'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        hasCard: json['hasCard'] as bool?,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] as String?,
        eventTime: json['eventTime'] as String?,
        eventVenue: json['eventVenue'] as String?,
      );
}

/// Resultat d'un enregistrement d'entree (CheckInResponse backend).
class CheckInResult {
  CheckInResult({
    this.checkInId,
    this.guestName,
    this.weddingDisplayName,
    this.invitationStatus,
    this.rsvpStatus,
    this.numberOfAttendees,
    this.checkedInAt,
    this.expectedAttendees,
    this.checkedInAttendees,
    this.remainingAttendees,
    this.tableName,
    this.drinkChoice,
    this.publicToken,
    this.invitationCode,
    this.hasCard,
    this.eventDate,
    this.eventTime,
    this.eventVenue,
  });

  final int? checkInId;
  final String? guestName;
  final String? weddingDisplayName;
  final String? invitationStatus;
  final String? rsvpStatus;
  final int? numberOfAttendees;
  final String? checkedInAt;
  final int? expectedAttendees;
  final int? checkedInAttendees;
  final int? remainingAttendees;
  final String? tableName;
  final String? drinkChoice;
  final String? publicToken;
  final String? invitationCode;
  final bool? hasCard;
  final String? eventDate;
  final String? eventTime;
  final String? eventVenue;

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
        checkInId: (json['checkInId'] as num?)?.toInt(),
        guestName: json['guestName'] as String?,
        weddingDisplayName: json['weddingDisplayName'] as String?,
        invitationStatus: json['invitationStatus'] as String?,
        rsvpStatus: json['rsvpStatus'] as String?,
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt(),
        checkedInAt: json['checkedInAt'] as String?,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt(),
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt(),
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt(),
        tableName: json['tableName'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        publicToken: json['publicToken'] as String?,
        invitationCode: json['invitationCode'] as String?,
        hasCard: json['hasCard'] as bool?,
        eventDate: json['eventDate'] as String?,
        eventTime: json['eventTime'] as String?,
        eventVenue: json['eventVenue'] as String?,
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
