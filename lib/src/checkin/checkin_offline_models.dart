class OfflinePackInvitation {
  OfflinePackInvitation({
    required this.publicToken,
    required this.invitationCode,
    this.guestId,
    this.guestName,
    this.invitationStatus,
    this.rsvpStatus,
    required this.expectedAttendees,
    required this.checkedInAttendees,
    required this.remainingAttendees,
    required this.canCheckIn,
    this.tableName,
    this.drinkChoice,
    required this.hasCard,
    this.phone,
    this.email,
  });

  final String publicToken;
  final String invitationCode;
  final int? guestId;
  final String? guestName;
  final String? invitationStatus;
  final String? rsvpStatus;
  final int expectedAttendees;
  final int checkedInAttendees;
  final int remainingAttendees;
  final bool canCheckIn;
  final String? tableName;
  final String? drinkChoice;
  final bool hasCard;
  final String? phone;
  final String? email;

  factory OfflinePackInvitation.fromJson(Map<String, dynamic> json) =>
      OfflinePackInvitation(
        publicToken: json['publicToken'] as String? ?? '',
        invitationCode: json['invitationCode'] as String? ?? '',
        guestId: (json['guestId'] as num?)?.toInt(),
        guestName: json['guestName'] as String?,
        invitationStatus: json['invitationStatus'] as String?,
        rsvpStatus: json['rsvpStatus'] as String?,
        expectedAttendees: (json['expectedAttendees'] as num?)?.toInt() ?? 0,
        checkedInAttendees: (json['checkedInAttendees'] as num?)?.toInt() ?? 0,
        remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
        canCheckIn: json['canCheckIn'] as bool? ?? false,
        tableName: json['tableName'] as String?,
        drinkChoice: json['drinkChoice'] as String?,
        hasCard: json['hasCard'] as bool? ?? false,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'publicToken': publicToken,
        'invitationCode': invitationCode,
        'guestId': guestId,
        'guestName': guestName,
        'invitationStatus': invitationStatus,
        'rsvpStatus': rsvpStatus,
        'expectedAttendees': expectedAttendees,
        'checkedInAttendees': checkedInAttendees,
        'remainingAttendees': remainingAttendees,
        'canCheckIn': canCheckIn,
        'tableName': tableName,
        'drinkChoice': drinkChoice,
        'hasCard': hasCard,
        'phone': phone,
        'email': email,
      };
}

class OfflinePackTableAssignment {
  OfflinePackTableAssignment({this.guestId, this.guestName});

  final int? guestId;
  final String? guestName;

  factory OfflinePackTableAssignment.fromJson(Map<String, dynamic> json) =>
      OfflinePackTableAssignment(
        guestId: (json['guestId'] as num?)?.toInt(),
        guestName: json['guestName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'guestId': guestId,
        'guestName': guestName,
      };
}

class OfflinePackTable {
  OfflinePackTable({
    required this.tableId,
    required this.name,
    required this.capacity,
    required this.assignedCount,
    required this.remainingCapacity,
    required this.assignments,
  });

  final int tableId;
  final String name;
  final int capacity;
  final int assignedCount;
  final int remainingCapacity;
  final List<OfflinePackTableAssignment> assignments;

  factory OfflinePackTable.fromJson(Map<String, dynamic> json) =>
      OfflinePackTable(
        tableId: (json['tableId'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        assignedCount: (json['assignedCount'] as num?)?.toInt() ?? 0,
        remainingCapacity: (json['remainingCapacity'] as num?)?.toInt() ?? 0,
        assignments: (json['assignments'] as List<dynamic>? ?? const [])
            .map((e) => OfflinePackTableAssignment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'tableId': tableId,
        'name': name,
        'capacity': capacity,
        'assignedCount': assignedCount,
        'remainingCapacity': remainingCapacity,
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };
}

class OfflinePackResponse {
  OfflinePackResponse({
    required this.eventId,
    this.eventName,
    this.eventDate,
    this.eventTime,
    this.eventVenue,
    this.dressColors,
    required this.invitations,
    required this.tables,
    required this.generatedAt,
  });

  final int eventId;
  final String? eventName;
  final String? eventDate;
  final String? eventTime;
  final String? eventVenue;
  final String? dressColors;
  final List<OfflinePackInvitation> invitations;
  final List<OfflinePackTable> tables;
  final int generatedAt;

  factory OfflinePackResponse.fromJson(Map<String, dynamic> json) =>
      OfflinePackResponse(
        eventId: (json['eventId'] as num?)?.toInt() ?? 0,
        eventName: json['eventName'] as String?,
        eventDate: json['eventDate'] as String?,
        eventTime: json['eventTime'] as String?,
        eventVenue: json['eventVenue'] as String?,
        dressColors: json['dressColors'] as String?,
        invitations: (json['invitations'] as List<dynamic>? ?? const [])
            .map((e) => OfflinePackInvitation.fromJson(e as Map<String, dynamic>))
            .toList(),
        tables: (json['tables'] as List<dynamic>? ?? const [])
            .map((e) => OfflinePackTable.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedAt: (json['generatedAt'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': eventName,
        'eventDate': eventDate,
        'eventTime': eventTime,
        'eventVenue': eventVenue,
        'dressColors': dressColors,
        'invitations': invitations.map((e) => e.toJson()).toList(),
        'tables': tables.map((e) => e.toJson()).toList(),
        'generatedAt': generatedAt,
      };
}

class QueuedOfflineScan {
  QueuedOfflineScan({
    required this.qrToken,
    required this.numberOfAttendees,
    this.scannedAt,
    this.deviceId,
    this.sequence,
  });

  final String qrToken;
  final int numberOfAttendees;
  final String? scannedAt;
  final String? deviceId;
  final int? sequence;

  factory QueuedOfflineScan.fromJson(Map<String, dynamic> json) =>
      QueuedOfflineScan(
        qrToken: json['qrToken'] as String? ?? '',
        numberOfAttendees: (json['numberOfAttendees'] as num?)?.toInt() ?? 0,
        scannedAt: json['scannedAt'] as String?,
        deviceId: json['deviceId'] as String?,
        sequence: (json['sequence'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'qrToken': qrToken,
        'numberOfAttendees': numberOfAttendees,
        'scannedAt': scannedAt,
        'deviceId': deviceId,
        'sequence': sequence,
      };
}
