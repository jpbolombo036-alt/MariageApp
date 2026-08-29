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

  /// Liste paginée des invités (`GET .../guests`).
  Future<List<Guest>> listGuests(int weddingId, {int page = 0, int size = 25}) async {
    final raw = await api.getList(
      _guestsPath(weddingId),
      queryParameters: {'page': page, 'size': size},
    );
    return raw.whereType<Map<String, dynamic>>().map((e) => Guest.fromJson(e)).toList();
  }

  /// Création d'un invité (`POST .../guests`).
  Future<Guest> createGuest(int weddingId, CreateGuestRequest request) async {
    final json = await api.postJson(_guestsPath(weddingId), request.toJson());
    return Guest.fromJson(json);
  }

  /// Liste paginée des catégories (`GET .../guest-categories`).
  Future<List<GuestCategory>> listCategories(int weddingId, {int page = 0, int size = 25}) async {
    final raw = await api.getList(
      _categoriesPath(weddingId),
      queryParameters: {'page': page, 'size': size},
    );
    return raw.whereType<Map<String, dynamic>>().map((e) => GuestCategory.fromJson(e)).toList();
  }

  /// Création d'une catégorie (`POST .../guest-categories`).
  Future<GuestCategory> createCategory(int weddingId, CreateGuestCategoryRequest request) async {
    final json = await api.postJson(_categoriesPath(weddingId), request.toJson());
    return GuestCategory.fromJson(json);
  }
}