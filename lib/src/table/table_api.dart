import '../api/api_client.dart';
import '../api/api_config.dart';

/// Table d'un événement (`WeddingTableResponse`).
class WeddingTable {
  const WeddingTable({
    required this.id,
    required this.name,
    this.description,
    required this.capacity,
    required this.assignedCount,
    required this.remainingCapacity,
  });

  final int id;
  final String name;
  final String? description;
  final int capacity;
  final int assignedCount;
  final int remainingCapacity;

  factory WeddingTable.fromJson(Map<String, dynamic> json) => WeddingTable(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
        remainingCapacity: (json['remainingCapacity'] as num?)?.toInt() ?? 0,
      );
}

/// Requête de création d'une table (`CreateWeddingTableRequest`).
class CreateWeddingTableRequest {
  CreateWeddingTableRequest({
    required this.name,
    required this.capacity,
    this.description,
  });

  final String name;
  final int capacity;
  final String? description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'capacity': capacity,
        if (description != null) 'description': description,
      };
}

/// Résultat d'affectation / déplacement / retrait (`TableAssignmentResponse`).
class TableAssignment {
  const TableAssignment({
    required this.assignmentId,
    required this.guestId,
    required this.guestName,
    required this.tableId,
    required this.tableName,
    this.assignedAt,
  });

  final int assignmentId;
  final int guestId;
  final String guestName;
  final int tableId;
  final String tableName;
  final String? assignedAt;

  factory TableAssignment.fromJson(Map<String, dynamic> json) => TableAssignment(
        assignmentId: (json['assignmentId'] as num?)?.toInt() ?? 0,
        guestId: (json['guestId'] as num?)?.toInt() ?? 0,
        guestName: json['guestName'] as String? ?? '',
        tableId: (json['tableId'] as num?)?.toInt() ?? 0,
        tableName: json['tableName'] as String? ?? '',
        assignedAt: json['assignedAt'] as String?,
      );
}

/// Client API du module tables + affectations.
class TableApi {
  TableApi({required this.api});

  final ApiClient api;

  String _tablesPath(int weddingId) => '${ApiConfig.eventsPath}/$weddingId/tables';
  String _assignmentsPath(int weddingId) =>
      '${ApiConfig.eventsPath}/$weddingId/assignments';

  /// Liste des tables d'un événement (`GET .../tables`).
  Future<List<WeddingTable>> list(int weddingId) async {
    final raw = await api.getList(_tablesPath(weddingId));
    return raw.whereType<Map<String, dynamic>>().map((e) => WeddingTable.fromJson(e)).toList();
  }
  /// Toutes les affectations d'un événement (`GET .../assignments`).
  ///
  /// Un seul appel pour tout l'événement : l'écran « Invités » affiche ainsi
  /// la table de chaque invité sans multiplier les requêtes.
  Future<List<TableAssignment>> listAllAssignments(int weddingId) async {
    final raw = await api.getList(_assignmentsPath(weddingId));
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TableAssignment.fromJson)
        .toList();
  }


  /// Création d'une table (`POST .../tables`).
  Future<WeddingTable> create(int weddingId, CreateWeddingTableRequest request) async {
    final json = await api.postJson(_tablesPath(weddingId), request.toJson());
    return WeddingTable.fromJson(json);
  }

  /// Modification d'une table (`PUT .../tables/{tableId}`).
  Future<WeddingTable> update(
      int weddingId, int tableId, CreateWeddingTableRequest request) async {
    final json =
        await api.putJson('${_tablesPath(weddingId)}/$tableId', request.toJson());
    return WeddingTable.fromJson(json);
  }

  /// Affecter un invité à une table (`POST .../tables/{id}/assignments`).
  Future<TableAssignment> assign({
    required int weddingId,
    required int tableId,
    required int guestId,
  }) async {
    final json = await api.postJson(
      '${_tablesPath(weddingId)}/$tableId/assignments',
      {'guestId': guestId},
    );
    return TableAssignment.fromJson(json);
  }

  /// Déplacer une affectation (`PUT .../assignments/{assignmentId}`).
  Future<TableAssignment> move({
    required int weddingId,
    required int assignmentId,
    required int targetTableId,
  }) async {
    final json = await api.putJson(
      '${_assignmentsPath(weddingId)}/$assignmentId',
      {'tableId': targetTableId},
    );
    return TableAssignment.fromJson(json);
  }

  /// Retirer un invité d'une table (`DELETE .../assignments/{assignmentId}`).
  Future<void> remove({required int weddingId, required int assignmentId}) async {
    await api.deleteRequest('${_assignmentsPath(weddingId)}/$assignmentId');
  }

  /// Affectations d'une table, filtrées depuis `GET .../assignments`.
  Future<List<TableAssignment>> listAssignments({
    required int weddingId,
    required int tableId,
  }) async {
    final raw = await api.getList(_assignmentsPath(weddingId));
    return raw
        .whereType<Map<String, dynamic>>()
        .map(TableAssignment.fromJson)
        .where((item) => item.tableId == tableId)
        .toList();
  }
}