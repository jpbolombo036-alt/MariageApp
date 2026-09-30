import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Types d'événement (mêmes valeurs que l'enum Java `EventType`).
enum EventType {
  wedding,
  collation,
  anniversary,
  baptism,
  graduation,
  other,
}

/// Conversion bidirectionnelle avec la chaîne API (majuscules).
extension EventTypeMapper on EventType {
  String get wireValue => switch (this) {
        EventType.wedding => 'WEDDING',
        EventType.collation => 'COLLATION',
        EventType.anniversary => 'ANNIVERSARY',
        EventType.baptism => 'BAPTISM',
        EventType.graduation => 'GRADUATION',
        EventType.other => 'OTHER',
      };
}

/// Parse une chaîne API (ex. "ANNIVERSARY") en [EventType], ou null si inconnue.
EventType? eventTypeFromWire(String? raw) {
  if (raw == null) return null;
  return switch (raw.toUpperCase()) {
    'WEDDING' => EventType.wedding,
    'COLLATION' => EventType.collation,
    'ANNIVERSARY' => EventType.anniversary,
    'BAPTISM' => EventType.baptism,
    'GRADUATION' => EventType.graduation,
    'OTHER' => EventType.other,
    _ => null,
  };
}

/// Fiche de détails spécifiques au mariage (imbriquée, null pour les autres
/// types) — `WeddingDetailsResponse` du backend.
@immutable
class WeddingDetails {
  const WeddingDetails({
    this.id,
    this.groomFirstName = '',
    this.groomLastName = '',
    this.brideFirstName = '',
    this.brideLastName = '',
    this.groomPhotoUrl,
    this.bridePhotoUrl,
    this.couplePhotoUrl,
    this.welcomeMessage,
    this.displayName = '',
  });

  final int? id;
  final String groomFirstName;
  final String groomLastName;
  final String brideFirstName;
  final String brideLastName;
  final String? groomPhotoUrl;
  final String? bridePhotoUrl;
  final String? couplePhotoUrl;
  final String? welcomeMessage;
  final String displayName;

  factory WeddingDetails.fromJson(Map<String, dynamic> json) => WeddingDetails(
        id: (json['id'] as num?)?.toInt(),
        groomFirstName: json['groomFirstName'] as String? ?? '',
        groomLastName: json['groomLastName'] as String? ?? '',
        brideFirstName: json['brideFirstName'] as String? ?? '',
        brideLastName: json['brideLastName'] as String? ?? '',
        groomPhotoUrl: json['groomPhotoUrl'] as String?,
        bridePhotoUrl: json['bridePhotoUrl'] as String?,
        couplePhotoUrl: json['couplePhotoUrl'] as String?,
        welcomeMessage: json['welcomeMessage'] as String?,
        displayName: json['displayName'] as String? ?? '',
      );
}

/// Réponse `EventResponse` du backend (nouvelle racine métier unifiée).
/// Le nom de classe [Wedding] est conservé pour limiter l'impact sur les
/// écrans existants ; les champs couple sont des commodités déléguées à
/// [weddingDetails].
@immutable
class Wedding {
  const Wedding({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.commune,
    this.country,
    this.message,
    required this.status,
    required this.organizationId,
    this.weddingDetails,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.displayOrder,
    // Valeurs par défaut alignées sur `fromJson` (booléens non nullables).
    this.active = true,
    this.hasImage = false,
    this.sessions,
  });

  final int id;
  final String name;
  final String type;
  final String? description;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? commune;
  final String? country;
  final String? message;
  final String status;
  final int organizationId;
  final WeddingDetails? weddingDetails;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final int? displayOrder;
  final bool active;
  final bool hasImage;
  final List<EventSession>? sessions;

  /// Type d'événement, ou null si la valeur est inconnue de l'app.
  EventType? get eventTypeEnum => eventTypeFromWire(type);

  /// Affichage : détails du mariage si présents, sinon le nom de l'événement.
  String get displayName {
    final d = weddingDetails;
    if (d != null && d.displayName.isNotEmpty) return d.displayName;
    return name;
  }

  // Commodités (utilisées par les écrans existants).
  String get groomFirstName => weddingDetails?.groomFirstName ?? '';
  String get groomLastName => weddingDetails?.groomLastName ?? '';
  String get brideFirstName => weddingDetails?.brideFirstName ?? '';
  String get brideLastName => weddingDetails?.brideLastName ?? '';
  String? get groomPhotoUrl => weddingDetails?.groomPhotoUrl;
  String? get bridePhotoUrl => weddingDetails?.bridePhotoUrl;
  String? get couplePhotoUrl => weddingDetails?.couplePhotoUrl;
  String? get welcomeMessage => weddingDetails?.welcomeMessage;

  factory Wedding.fromJson(Map<String, dynamic> json) {
    final detailsJson = json['weddingDetails'] as Map<String, dynamic>?;
    final sessionsJson = json['sessions'] as List<dynamic>?;
    return Wedding(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'WEDDING',
      description: json['description'] as String?,
      eventDate: json['eventDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      venueName: json['venueName'] as String?,
      venueAddress: json['venueAddress'] as String?,
      city: json['city'] as String?,
      commune: json['commune'] as String?,
      country: json['country'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      organizationId: ((json['organizationId'] as num?) ?? 0).toInt(),
      weddingDetails:
          detailsJson == null ? null : WeddingDetails.fromJson(detailsJson),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['mapUrl'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt(),
      active: json['active'] as bool? ?? true,
      hasImage: json['hasImage'] as bool? ?? false,
      sessions: sessionsJson
          ?.whereType<Map<String, dynamic>>()
          .map(EventSession.fromJson)
          .toList(),
    );
  }
}

/// Requête de création d'un événement (`POST /api/events`) — format imbriqué
/// exigé par le backend : `weddingDetails` requis si type = WEDDING, interdit
/// pour les autres types (règle D2).
class CreateWeddingRequest {
  CreateWeddingRequest({
    required this.name,
    required this.eventType,
    this.description,
    this.message,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.commune,
    this.country,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.groomFirstName,
    this.groomLastName,
    this.brideFirstName,
    this.brideLastName,
    this.groomPhotoUrl,
    this.bridePhotoUrl,
    this.couplePhotoUrl,
    this.welcomeMessage,
    this.displayName,
    this.organizationId,
  });

  final String name;
  final EventType eventType;
  final String? description;
  final String? message;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? commune;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? groomFirstName;
  final String? groomLastName;
  final String? brideFirstName;
  final String? brideLastName;
  final String? groomPhotoUrl;
  final String? bridePhotoUrl;
  final String? couplePhotoUrl;
  final String? welcomeMessage;
  final String? displayName;
  final int? organizationId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': eventType.wireValue,
        if (description != null) 'description': description,
        if (message != null) 'message': message,
        if (eventDate != null) 'eventDate': eventDate,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (city != null) 'city': city,
        if (commune != null) 'commune': commune,
        if (country != null) 'country': country,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (mapUrl != null) 'mapUrl': mapUrl,
        if (organizationId != null) 'organizationId': organizationId,
        if (eventType == EventType.wedding)
          'weddingDetails': {
            if (groomFirstName != null) 'groomFirstName': groomFirstName,
            if (groomLastName != null) 'groomLastName': groomLastName,
            if (brideFirstName != null) 'brideFirstName': brideFirstName,
            if (brideLastName != null) 'brideLastName': brideLastName,
            if (groomPhotoUrl != null) 'groomPhotoUrl': groomPhotoUrl,
            if (bridePhotoUrl != null) 'bridePhotoUrl': bridePhotoUrl,
            if (couplePhotoUrl != null) 'couplePhotoUrl': couplePhotoUrl,
            if (welcomeMessage != null) 'welcomeMessage': welcomeMessage,
            if (displayName != null) 'displayName': displayName,
          },
      };
}

/// Client API du module événements (nouvelle racine unifiée).
class WeddingApi {
  WeddingApi({required this.api});

  final ApiClient api;

  /// Liste des événements (`GET /api/events`), toutes les pages Spring.
  Future<List<Wedding>> list({int size = 25}) async {
    final pageSize = size < 25 ? 25 : size;
    final rawList = await api.getAllMaps(ApiConfig.eventsPath, size: pageSize);
    return rawList.map(Wedding.fromJson).toList();
  }

  /// Création (`POST /api/events`) — renvoie l'Event créé.
  Future<Wedding> create(CreateWeddingRequest request) async {
    final json = await api.postJson(ApiConfig.eventsPath, request.toJson());
    return Wedding.fromJson(json);
  }

  /// Détail (`GET /api/events/{id}`) — inclut weddingDetails et sessions.
  Future<Wedding> getById(int id) async {
    final json = await api.getJson('${ApiConfig.eventsPath}/$id');
    return Wedding.fromJson(json);
  }

  /// Changement de statut (`PATCH /api/events/{id}/status`).
  Future<Wedding> updateStatus(int id, String status) async {
    final json = await api.patchJson(
      '${ApiConfig.eventsPath}/$id/status',
      {'status': status},
    );
    return Wedding.fromJson(json);
  }

  /// Suppression logique (`DELETE /api/events/{id}`).
  Future<void> delete(int id) async {
    await api.deleteRequest('${ApiConfig.eventsPath}/$id');
  }
  /// Modification d'un événement (`PUT /api/events/{id}`) — mise à jour
  /// partielle : seuls les champs renseignés sont appliqués côté backend.
  Future<Wedding> update(int id, UpdateEventRequest request) async {
    final json =
        await api.putJson('${ApiConfig.eventsPath}/$id', request.toJson());
    return Wedding.fromJson(json);
  }

  /// Charge la photo de couverture en bytes (null si absente).
  Future<Uint8List?> loadImage(int eventId) async {
    try {
      return await api.getBytes('${ApiConfig.eventsPath}/$eventId/image');
    } on DioException catch (_) {
      return null;
    }
  }

  /// Upload la photo de couverture (`PUT /api/events/{id}/image`).
  Future<void> uploadImage(int eventId, List<int> bytes, String contentType) async {
    await api.postMultipart(
      '${ApiConfig.eventsPath}/$eventId/image',
      bytes: bytes,
      contentType: contentType,
    );
  }

  /// Supprime la photo de couverture (`DELETE /api/events/{id}/image`).
  Future<void> deleteImage(int eventId) async {
    await api.deleteRequest('${ApiConfig.eventsPath}/$eventId/image');
  }

  /// Charge une photo de la fiche mariage en bytes (null si absente).
  Future<Uint8List?> loadDetailPhoto(int eventId, String kind) async {
    try {
      return await api.getBytes('${ApiConfig.eventsPath}/$eventId/photos/$kind');
    } on DioException catch (_) {
      return null;
    }
  }

  /// Upload une photo de la fiche mariage (`PUT /api/events/{id}/photos/{kind}`).
  Future<void> uploadDetailPhoto(int eventId, String kind, List<int> bytes, String contentType) async {
    await api.postMultipart(
      '${ApiConfig.eventsPath}/$eventId/photos/$kind',
      bytes: bytes,
      contentType: contentType,
    );
  }
}
/// Requête de modification d'un événement (`UpdateEventRequest`).
/// Tous les champs sont optionnels : le backend n'applique que les non-null.
class UpdateEventRequest {
  UpdateEventRequest({
    this.name,
    this.description,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.commune,
    this.country,
    this.message,
  });

  final String? name;
  final String? description;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? commune;
  final String? country;
  final String? message;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (eventDate != null) 'eventDate': eventDate,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (city != null) 'city': city,
        if (commune != null) 'commune': commune,
        if (country != null) 'country': country,
        if (message != null) 'message': message,
      };
}

/// Sous-session d'un événement (`EventSessionResponse`).
class EventSession {
  const EventSession({
    this.id,
    this.name,
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

  final int? id;
  final String? name;
  final String? type;
  final String? description;
  final String? sessionDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final String? mapUrl;

  factory EventSession.fromJson(Map<String, dynamic> json) => EventSession(
        id: (json['id'] as num?)?.toInt(),
        name: json['name'] as String?,
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