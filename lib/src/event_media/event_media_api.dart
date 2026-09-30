import 'dart:io';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Galerie, boissons et exports d'un événement.
class EventMediaApi {
  EventMediaApi({required this.api});

  final ApiClient api;

  String _gallery(int eventId) => '${ApiConfig.eventsPath}/$eventId/gallery';
  String _drinks(int eventId) => '${ApiConfig.eventsPath}/$eventId/drinks';
  String _export(int eventId) => '${ApiConfig.eventsPath}/$eventId/export';

  Future<EventGallery> gallery(int eventId) async {
    final json = await api.getJson(_gallery(eventId));
    return EventGallery.fromJson(json);
  }

  Future<EventGallery> updateGallery(
    int eventId, {
    String? title,
    String? description,
    bool? enabled,
  }) async {
    final json = await api.putJson(_gallery(eventId), {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (enabled != null) 'enabled': enabled,
    });
    return EventGallery.fromJson(json);
  }

  Future<void> deletePhoto(int eventId, int photoId) async {
    await api.deleteRequest('${_gallery(eventId)}/photos/$photoId');
  }

  Future<List<EventDrink>> drinks(int eventId) async {
    final raw = await api.getList(_drinks(eventId));
    return raw.whereType<Map<String, dynamic>>().map(EventDrink.fromJson).toList();
  }

  Future<EventDrink> createDrink(int eventId, String name, {String? description}) async {
    final json = await api.postJson(_drinks(eventId), {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return EventDrink.fromJson(json);
  }

  Future<void> deleteDrink(int eventId, int drinkId) async {
    await api.deleteRequest('${_drinks(eventId)}/$drinkId');
  }

  /// Enregistre un export dans le dossier temporaire et renvoie le fichier.
  Future<File> downloadExport(int eventId, String kind) async {
    final bytes = await api.getBytes('${_export(eventId)}/$kind');
    final name = kind.replaceAll('/', '-');
    final file = File('${Directory.systemTemp.path}/eventia-$eventId-$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<List<int>> publicCard(String publicToken) {
    return api.getBytes('${ApiConfig.publicInvitationsPath}/$publicToken/card');
  }
}

class EventGallery {
  const EventGallery({
    required this.title,
    required this.enabled,
    required this.photos,
    this.description,
  });

  final String title;
  final String? description;
  final bool enabled;
  final List<GalleryPhoto> photos;

  factory EventGallery.fromJson(Map<String, dynamic> json) => EventGallery(
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        enabled: json['enabled'] as bool? ?? false,
        photos: ((json['photos'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GalleryPhoto.fromJson)
            .toList(),
      );
}

class GalleryPhoto {
  const GalleryPhoto({required this.id, this.caption});

  final int id;
  final String? caption;

  factory GalleryPhoto.fromJson(Map<String, dynamic> json) => GalleryPhoto(
        id: (json['id'] as num).toInt(),
        caption: json['caption'] as String?,
      );
}

class EventDrink {
  const EventDrink({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory EventDrink.fromJson(Map<String, dynamic> json) => EventDrink(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
      );
}
