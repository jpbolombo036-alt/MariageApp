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
    this.city,
    this.country,
    required this.status,
    required this.organizationId,
    this.weddingDetails,
  });

  final int id;
  final String name;
  final String type;
  final String? description;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? city;
  final String? country;
  final String status;
  final int organizationId;
  final WeddingDetails? weddingDetails;

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
    return Wedding(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'WEDDING',
      description: json['description'] as String?,
      eventDate: json['eventDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      venueName: json['venueName'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      status: json['status'] as String? ?? 'DRAFT',
      organizationId: ((json['organizationId'] as num?) ?? 0).toInt(),
      weddingDetails:
          detailsJson == null ? null : WeddingDetails.fromJson(detailsJson),
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
    this.groomFirstName,
    this.groomLastName,
    this.brideFirstName,
    this.brideLastName,
  });

  final String name;
  final EventType eventType;
  final String? description;
  final String? groomFirstName;
  final String? groomLastName;
  final String? brideFirstName;
  final String? brideLastName;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': eventType.wireValue,
        if (description != null) 'description': description,
        if (eventType == EventType.wedding)
          'weddingDetails': {
            'groomFirstName': groomFirstName,
            'groomLastName': groomLastName,
            'brideFirstName': brideFirstName,
            'brideLastName': brideLastName,
          },
      };
}

/// Client API du module événements (nouvelle racine unifiée).
class WeddingApi {
  WeddingApi({required this.api});

  final ApiClient api;

  /// Liste paginée des événements (`GET /api/events`).
  Future<List<Wedding>> list({int page = 0, int size = 25}) async {
    final rawList = await api.getList(
      ApiConfig.eventsPath,
      queryParameters: {'page': page, 'size': size},
    );
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => Wedding.fromJson(e))
        .toList();
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
}