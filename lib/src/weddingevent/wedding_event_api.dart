import '../api/api_client.dart';
import '../api/api_config.dart';

/// Types d'événement de mariage (mêmes valeurs que `WeddingEventType` côté backend).
enum WeddingEventType {
  civilCeremony,
  religiousCeremony,
  reception,
  afterParty,
  other,
}

extension WeddingEventTypeMapper on WeddingEventType {
  String get wireValue => switch (this) {
        WeddingEventType.civilCeremony => 'CIVIL_CEREMONY',
        WeddingEventType.religiousCeremony => 'RELIGIOUS_CEREMONY',
        WeddingEventType.reception => 'RECEPTION',
        WeddingEventType.afterParty => 'AFTER_PARTY',
        WeddingEventType.other => 'OTHER',
      };
}

WeddingEventType? weddingEventTypeFromWire(String? raw) {
  if (raw == null) return null;
  return switch (raw.toUpperCase()) {
        'CIVIL_CEREMONY' => WeddingEventType.civilCeremony,
        'RELIGIOUS_CEREMONY' => WeddingEventType.religiousCeremony,
        'RECEPTION' => WeddingEventType.reception,
        'AFTER_PARTY' => WeddingEventType.afterParty,
        _ => WeddingEventType.other,
      };
}

/// Événement d'un mariage (`WeddingEventResponse`).
class WeddingEvent {
  const WeddingEvent({
    required this.id,
    required this.weddingId,
    required this.name,
    this.type,
    this.description,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.displayOrder,
    required this.active,
  });

  final int id;
  final int weddingId;
  final String name;
  final String? type;
  final String? description;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final int? displayOrder;
  final bool active;

  WeddingEventType? get typeEnum => weddingEventTypeFromWire(type);

  factory WeddingEvent.fromJson(Map<String, dynamic> json) => WeddingEvent(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        name: json['name'] as String? ?? '',
        type: json['type'] as String?,
        description: json['description'] as String?,
        eventDate: json['eventDate'] as String?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        venueName: json['venueName'] as String?,
        venueAddress: json['venueAddress'] as String?,
        city: json['city'] as String?,
        displayOrder: (json['displayOrder'] as num?)?.toInt(),
        active: json['active'] as bool? ?? true,
      );
}

/// Requête de création d'un événement (`CreateWeddingEventRequest`).
class CreateWeddingEventRequest {
  CreateWeddingEventRequest({
    required this.name,
    required this.type,
    this.description,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.venueName,
    this.venueAddress,
    this.city,
    this.displayOrder,
  });

  final String name;
  final WeddingEventType type;
  final String? description;
  final String? eventDate;
  final String? startTime;
  final String? endTime;
  final String? venueName;
  final String? venueAddress;
  final String? city;
  final int? displayOrder;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.wireValue,
        if (description != null) 'description': description,
        if (eventDate != null) 'eventDate': eventDate,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (city != null) 'city': city,
        if (displayOrder != null) 'displayOrder': displayOrder,
      };
}

/// Client API du module événements de mariage.
class WeddingEventApi {
  WeddingEventApi({required this.api});

  final ApiClient api;

  /// Liste paginée (`GET .../sessions` — alias des anciens wedding-events).
  Future<List<WeddingEvent>> list(int weddingId, {int page = 0, int size = 25}) async {
    final raw = await api.getList(
      '${ApiConfig.eventsPath}/$weddingId/sessions',
      queryParameters: {'page': page, 'size': size},
    );
    return raw.whereType<Map<String, dynamic>>().map((e) => WeddingEvent.fromJson(e)).toList();
  }

  /// Création (`POST .../sessions`).
  Future<WeddingEvent> create(int weddingId, CreateWeddingEventRequest request) async {
    final json = await api.postJson(
      '${ApiConfig.eventsPath}/$weddingId/sessions',
      request.toJson(),
    );
    return WeddingEvent.fromJson(json);
  }

  /// Détail (`GET .../sessions/{sessionId}`).
  Future<WeddingEvent> getById(int weddingId, int eventId) async {
    final json = await api.getJson(
      '${ApiConfig.eventsPath}/$weddingId/sessions/$eventId',
    );
    return WeddingEvent.fromJson(json);
  }

  /// Suppression logique (`DELETE .../sessions/{sessionId}`).
  Future<void> delete(int weddingId, int eventId) async {
    await api.deleteRequest('${ApiConfig.eventsPath}/$weddingId/sessions/$eventId');
  }
}