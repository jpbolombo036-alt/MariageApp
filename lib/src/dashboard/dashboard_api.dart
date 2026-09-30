import '../api/api_client.dart';
import '../api/api_config.dart';
import '../wedding/wedding_api.dart' show EventType, eventTypeFromWire;

/// Statistiques des invités (`GuestStatisticsResponse`).
class GuestStats {
  const GuestStats({required this.total, required this.unassigned});

  final int total;
  final int unassigned;

  factory GuestStats.fromJson(Map<String, dynamic> json) => GuestStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        unassigned: (json['unassigned'] as num?)?.toInt() ?? 0,
      );
}

/// Statistiques des invitations (RSVP) (`InvitationStatisticsResponse`).
class InvitationStats {
  const InvitationStats({
    required this.total,
    required this.accepted,
    required this.declined,
    required this.pending,
    required this.responseRate,
  });

  final int total;
  final int accepted;
  final int declined;
  final int pending;
  final double responseRate;

  factory InvitationStats.fromJson(Map<String, dynamic> json) =>
      InvitationStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        declined: (json['declined'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0,
      );
}

/// Statistiques de présence (check-in) (`AttendanceStatisticsResponse`).
class AttendanceStats {
  const AttendanceStats({
    required this.expected,
    required this.checkedIn,
    required this.remaining,
    required this.checkInRate,
  });

  final int expected;
  final int checkedIn;
  final int remaining;
  final double checkInRate;

  factory AttendanceStats.fromJson(Map<String, dynamic> json) =>
      AttendanceStats(
        expected: (json['expected'] as num?)?.toInt() ?? 0,
        checkedIn: (json['checkedIn'] as num?)?.toInt() ?? 0,
        remaining: (json['remaining'] as num?)?.toInt() ?? 0,
        checkInRate: (json['checkInRate'] as num?)?.toDouble() ?? 0,
      );
}

/// Statistiques des tables (`TableStatisticsResponse`).
class TableStats {
  const TableStats({
    required this.total,
    required this.capacity,
    required this.assignedGuests,
    required this.remainingCapacity,
  });

  final int total;
  final int capacity;
  final int assignedGuests;
  final int remainingCapacity;

  factory TableStats.fromJson(Map<String, dynamic> json) => TableStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        assignedGuests: (json['assignedGuests'] as num?)?.toInt() ?? 0,
        remainingCapacity: (json['remainingCapacity'] as num?)?.toInt() ?? 0,
      );
}

/// Statistique par catégorie d'invités (`CategoryStatisticsResponse`).
class CategoryStats {
  const CategoryStats({
    required this.categoryId,
    required this.name,
    required this.totalGuests,
    required this.accepted,
    required this.declined,
    required this.pending,
    required this.expectedAttendees,
  });

  final int categoryId;
  final String name;
  final int totalGuests;
  final int accepted;
  final int declined;
  final int pending;
  final int expectedAttendees;

  factory CategoryStats.fromJson(Map<String, dynamic> json) =>
      CategoryStats(
        categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        totalGuests: (json['totalGuests'] as num?)?.toInt() ?? 0,
        accepted: (json['accepted'] as num?)?.toInt() ?? 0,
        declined: (json['declined'] as num?)?.toInt() ?? 0,
        pending: (json['pending'] as num?)?.toInt() ?? 0,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt() ?? 0,
      );
}

/// Tableau de bord d'un événement (`WeddingDashboardResponse`).
class Dashboard {
  const Dashboard({
    required this.weddingId,
    required this.weddingName,
    this.eventType,
    required this.guests,
    required this.invitations,
    required this.attendance,
    required this.tables,
    required this.categories,
  });

  final int weddingId;
  final String weddingName;
  final String? eventType;
  final GuestStats guests;
  final InvitationStats invitations;
  final AttendanceStats attendance;
  final TableStats tables;
  final List<CategoryStats> categories;

  EventType? get eventTypeEnum => eventTypeFromWire(eventType);

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
        weddingId: (json['weddingId'] as num?)?.toInt() ?? 0,
        weddingName: json['weddingName'] as String? ?? '',
        eventType: json['eventType'] as String?,
        guests: GuestStats.fromJson(
          (json['guests'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
        invitations: InvitationStats.fromJson(
          (json['invitations'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
        attendance: AttendanceStats.fromJson(
          (json['attendance'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
        tables: TableStats.fromJson(
          (json['tables'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
        categories: ((json['categories'] as List<dynamic>?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((e) => CategoryStats.fromJson(e))
            .toList(),
      );
}

/// Client API du dashboard (`GET /api/events/{id}/dashboard`).
class DashboardApi {
  DashboardApi({required this.api});

  final ApiClient api;

  Future<Dashboard> getForWedding(int weddingId) async {
    final json = await api.getJson(
      '${ApiConfig.eventsPath}/$weddingId/dashboard',
    );
    return Dashboard.fromJson(json);
  }

  /// Prochaine séance (`GET .../dashboard/upcoming-session`), null si aucune.
  Future<UpcomingSession?> upcomingSession(int weddingId) async {
    final json = await api.getJsonOrNull(
      '${ApiConfig.eventsPath}/$weddingId/dashboard/upcoming-session',
    );
    if (json == null || json['id'] == null) return null;
    return UpcomingSession.fromJson(json);
  }

  /// Activité récente (`GET .../dashboard/recent-activity`).
  Future<List<ActivityItem>> recentActivity(int weddingId, {int limit = 8}) async {
    final raw = await api.getList(
      '${ApiConfig.eventsPath}/$weddingId/dashboard/recent-activity',
      queryParameters: {'limit': limit},
    );
    return raw.whereType<Map<String, dynamic>>().map(ActivityItem.fromJson).toList();
  }
}

/// Prochaine séance affichée sur le tableau de bord.
class UpcomingSession {
  const UpcomingSession({
    required this.id,
    required this.name,
    this.sessionDate,
    this.startTime,
    this.venueName,
  });

  final int id;
  final String name;
  final String? sessionDate;
  final String? startTime;
  final String? venueName;

  factory UpcomingSession.fromJson(Map<String, dynamic> json) => UpcomingSession(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        sessionDate: json['sessionDate'] as String?,
        startTime: json['startTime'] as String?,
        venueName: json['venueName'] as String?,
      );
}

/// Ligne d'activité récente.
class ActivityItem {
  const ActivityItem({
    required this.action,
    this.details,
    this.performedAt,
  });

  final String action;
  final String? details;
  final String? performedAt;

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        action: json['action'] as String? ?? '',
        details: json['details'] as String?,
        performedAt: json['performedAt'] as String?,
      );
}