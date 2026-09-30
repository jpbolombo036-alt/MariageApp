import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';

/// Invité (`GuestResponse`) — champs exacts du backend.
class Guest {
  const Guest({
    required this.id,
    required this.weddingId,
    this.categoryId,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.allowedCompanions,
    this.notes,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int weddingId;
  final int? categoryId;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final int? allowedCompanions;
  final String? notes;
  final bool active;
  final String? createdAt;
  final String? updatedAt;

  /// Nom complet affiché.
  String get displayName => '$firstName $lastName';

  factory Guest.fromJson(Map<String, dynamic> json) => Guest(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        categoryId: (json['categoryId'] as num?)?.toInt(),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        allowedCompanions: (json['allowedCompanions'] as num?)?.toInt(),
        notes: json['notes'] as String?,
        active: json['active'] as bool? ?? true,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );
}

/// Requête de création d'un invité (`CreateGuestRequest`).
class CreateGuestRequest {
  CreateGuestRequest({
    required this.firstName,
    required this.lastName,
    this.phone,
    this.email,
    this.address,
    this.categoryId,
    this.allowedCompanions,
    this.notes,
  });

  final String firstName;
  final String lastName;
  final String? phone;
  final String? email;
  final String? address;
  final int? categoryId;
  final int? allowedCompanions;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (categoryId != null) 'categoryId': categoryId,
        if (allowedCompanions != null) 'allowedCompanions': allowedCompanions,
        if (notes != null) 'notes': notes,
      };
}

/// Catégorie d'invités (`GuestCategoryResponse`).
class GuestCategory {
  const GuestCategory({
    required this.id,
    required this.weddingId,
    required this.name,
    this.description,
    this.displayOrder,
    required this.active,
  });

  final int id;
  final int weddingId;
  final String name;
  final String? description;
  final int? displayOrder;
  final bool active;

  factory GuestCategory.fromJson(Map<String, dynamic> json) => GuestCategory(
        id: (json['id'] as num).toInt(),
        weddingId: ((json['weddingId'] as num?) ?? 0).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        displayOrder: (json['displayOrder'] as num?)?.toInt(),
        active: json['active'] as bool? ?? true,
      );
}

/// Requête de création d'une catégorie (`CreateGuestCategoryRequest`).
class CreateGuestCategoryRequest {
  CreateGuestCategoryRequest({required this.name, this.description, this.displayOrder});

  final String name;
  final String? description;
  final int? displayOrder;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (displayOrder != null) 'displayOrder': displayOrder,
      };
}

/// Client API du module invités + catégories.
class GuestApi {
  GuestApi({required this.api});

  final ApiClient api;

  String _guestsPath(int weddingId) => '${ApiConfig.eventsPath}/$weddingId/guests';
  String _categoriesPath(int weddingId) =>
      '${ApiConfig.eventsPath}/$weddingId/guest-categories';

  /// Liste des invités (`GET .../guests`), toutes les pages Spring.
  Future<List<Guest>> listGuests(int weddingId, {int size = 25}) async {
    final pageSize = size < 25 ? 25 : size;
    final raw = await api.getAllMaps(_guestsPath(weddingId), size: pageSize);
    return raw.map(Guest.fromJson).toList();
  }

  /// Création d'un invité (`POST .../guests`).
  Future<Guest> createGuest(int weddingId, CreateGuestRequest request) async {
    final json = await api.postJson(_guestsPath(weddingId), request.toJson());
    return Guest.fromJson(json);
  }

  /// Liste des catégories (`GET .../guest-categories`), toutes les pages.
  Future<List<GuestCategory>> listCategories(int weddingId, {int size = 25}) async {
    final raw = await api.getAllMaps(_categoriesPath(weddingId), size: size);
    return raw.map(GuestCategory.fromJson).toList();
  }

  /// Création d'une catégorie (`POST .../guest-categories`).
  Future<GuestCategory> createCategory(int weddingId, CreateGuestCategoryRequest request) async {
    final json = await api.postJson(_categoriesPath(weddingId), request.toJson());
    return GuestCategory.fromJson(json);
  }

  /// Modification d'un invité (`PUT .../guests/{guestId}`).
  Future<Guest> updateGuest(int weddingId, int guestId, UpdateGuestRequest request) async {
    final json = await api.putJson('${_guestsPath(weddingId)}/$guestId', request.toJson());
    return Guest.fromJson(json);
  }

  /// Modification d'une catégorie (`PUT .../guest-categories/{id}`).
  Future<GuestCategory> updateCategory(
    int weddingId,
    int categoryId,
    String name, {
    String? description,
  }) async {
    final json = await api.putJson(
      '${_categoriesPath(weddingId)}/$categoryId',
      {
        'name': name,
        if (description != null) 'description': description,
      },
    );
    return GuestCategory.fromJson(json);
  }

  /// Suppression d'une catégorie (`DELETE .../guest-categories/{id}`).
  Future<void> deleteCategory(int weddingId, int categoryId) async {
    await api.deleteRequest('${_categoriesPath(weddingId)}/$categoryId');
  }

  /// Import CSV (`POST .../guests/import`, champ `file`).
  Future<Map<String, dynamic>> importGuestsCsv(int weddingId, String csv) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromString(
        csv,
        filename: 'invites.csv',
        contentType: DioMediaType('text', 'csv'),
      ),
    });
    return api.postForm('${_guestsPath(weddingId)}/import', form);
  }

  /// Suppression logique d'un invité (`DELETE .../guests/{guestId}`).
  Future<void> deleteGuest(int weddingId, int guestId) async {
    await api.deleteRequest('${_guestsPath(weddingId)}/$guestId');
  }
}

/// Requete de modification d'un invite (`UpdateGuestRequest`).
class UpdateGuestRequest {
  UpdateGuestRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.allowedCompanions,
    this.notes,
  });

  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final int? allowedCompanions;
  final String? notes;

  Map<String, dynamic> toJson() => {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (allowedCompanions != null) 'allowedCompanions': allowedCompanions,
        if (notes != null) 'notes': notes,
      };
}