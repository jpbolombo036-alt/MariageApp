import 'package:meta/meta.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Réponse `WeddingResponse` du backend (champs exacts).
@immutable
class Wedding {
  const Wedding({
    required this.id,
    required this.organizationId,
    required this.groomFirstName,
    required this.groomLastName,
    required this.brideFirstName,
    required this.brideLastName,
    this.groomPhotoUrl,
    this.bridePhotoUrl,
    this.couplePhotoUrl,
    this.description,
    this.welcomeMessage,
    required this.status,
    required this.displayName,
    this.createdBy,
    this.updatedBy,
  });

  final int id;
  final int organizationId;
  final String groomFirstName;
  final String groomLastName;
  final String brideFirstName;
  final String brideLastName;
  final String? groomPhotoUrl;
  final String? bridePhotoUrl;
  final String? couplePhotoUrl;
  final String? description;
  final String? welcomeMessage;
  final String status;
  final String displayName;
  final int? createdBy;
  final int? updatedBy;

  factory Wedding.fromJson(Map<String, dynamic> json) => Wedding(
        id: (json['id'] as num).toInt(),
        organizationId: ((json['organizationId'] as num?) ?? 0).toInt(),
        groomFirstName: json['groomFirstName'] as String? ?? '',
        groomLastName: json['groomLastName'] as String? ?? '',
        brideFirstName: json['brideFirstName'] as String? ?? '',
        brideLastName: json['brideLastName'] as String? ?? '',
        groomPhotoUrl: json['groomPhotoUrl'] as String?,
        bridePhotoUrl: json['bridePhotoUrl'] as String?,
        couplePhotoUrl: json['couplePhotoUrl'] as String?,
        description: json['description'] as String?,
        welcomeMessage: json['welcomeMessage'] as String?,
        status: json['status'] as String? ?? 'DRAFT',
        displayName: json['displayName'] as String? ?? '',
        createdBy: (json['createdBy'] as num?)?.toInt(),
        updatedBy: (json['updatedBy'] as num?)?.toInt(),
      );
}

/// Requête de création d'un Wedding (champs envoyés par l'app).
class CreateWeddingRequest {
  CreateWeddingRequest({
    required this.groomFirstName,
    required this.groomLastName,
    required this.brideFirstName,
    required this.brideLastName,
    this.description,
    this.welcomeMessage,
  });

  final String groomFirstName;
  final String groomLastName;
  final String brideFirstName;
  final String brideLastName;
  final String? description;
  final String? welcomeMessage;

  Map<String, dynamic> toJson() => {
        'groomFirstName': groomFirstName,
        'groomLastName': groomLastName,
        'brideFirstName': brideFirstName,
        'brideLastName': brideLastName,
        if (description != null) 'description': description,
        if (welcomeMessage != null) 'welcomeMessage': welcomeMessage,
      };
}

/// Requête de mise à jour d'un Wedding (champs optionnels, mise à jour partielle).
class UpdateWeddingRequest {
  UpdateWeddingRequest({
    this.groomFirstName,
    this.groomLastName,
    this.brideFirstName,
    this.brideLastName,
    this.groomPhotoUrl,
    this.bridePhotoUrl,
    this.couplePhotoUrl,
    this.description,
    this.welcomeMessage,
  });

  final String? groomFirstName;
  final String? groomLastName;
  final String? brideFirstName;
  final String? brideLastName;
  final String? groomPhotoUrl;
  final String? bridePhotoUrl;
  final String? couplePhotoUrl;
  final String? description;
  final String? welcomeMessage;

  Map<String, dynamic> toJson() => {
        if (groomFirstName != null) 'groomFirstName': groomFirstName,
        if (groomLastName != null) 'groomLastName': groomLastName,
        if (brideFirstName != null) 'brideFirstName': brideFirstName,
        if (brideLastName != null) 'brideLastName': brideLastName,
        if (groomPhotoUrl != null) 'groomPhotoUrl': groomPhotoUrl,
        if (bridePhotoUrl != null) 'bridePhotoUrl': bridePhotoUrl,
        if (couplePhotoUrl != null) 'couplePhotoUrl': couplePhotoUrl,
        if (description != null) 'description': description,
        if (welcomeMessage != null) 'welcomeMessage': welcomeMessage,
      };
}

/// Requête de changement de statut (`UpdateWeddingStatusRequest`).
class UpdateWeddingStatusRequest {
  UpdateWeddingStatusRequest({required this.status});

  final String status;

  Map<String, dynamic> toJson() => {'status': status};
}

/// Client API du module mariages/événements.
class WeddingApi {
  WeddingApi({required this.api});

  final ApiClient api;

  /// Liste paginée des weddings/événements (`GET /api/weddings`).
  Future<List<Wedding>> list({int page = 0, int size = 25}) async {
    final rawList = await api.getList(
      ApiConfig.weddingsPath,
      queryParameters: {'page': page, 'size': size},
    );
    return rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => Wedding.fromJson(e))
        .toList();
  }

  /// Création (`POST /api/weddings`) — renvoie le Wedding créé.
  Future<Wedding> create(CreateWeddingRequest request) async {
    final json = await api.postJson(ApiConfig.weddingsPath, request.toJson());
    return Wedding.fromJson(json);
  }

  /// Détail (`GET /api/weddings/{id}`).
  Future<Wedding> getById(int id) async {
    final json = await api.getJson('${ApiConfig.weddingsPath}/$id');
    return Wedding.fromJson(json);
  }

  /// Mise à jour partielle (`PUT /api/weddings/{id}`).
  Future<Wedding> update(int id, UpdateWeddingRequest request) async {
    final json =
        await api.putJson('${ApiConfig.weddingsPath}/$id', request.toJson());
    return Wedding.fromJson(json);
  }

  /// Changement de statut (`PATCH /api/weddings/{id}/status`).
  Future<Wedding> updateStatus(int id, String status) async {
    final json = await api.patchJson(
      '${ApiConfig.weddingsPath}/$id/status',
      UpdateWeddingStatusRequest(status: status).toJson(),
    );
    return Wedding.fromJson(json);
  }

  /// Suppression logique (`DELETE /api/weddings/{id}`).
  Future<void> delete(int id) async {
    await api.deleteRequest('${ApiConfig.weddingsPath}/$id');
  }
}