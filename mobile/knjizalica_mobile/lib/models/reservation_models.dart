class ReservationDto {
  ReservationDto({
    required this.id,
    required this.memberProfileId,
    required this.memberName,
    required this.bookCopyId,
    required this.inventoryCode,
    required this.bookId,
    required this.bookTitle,
    this.coverImagePath,
    required this.status,
    required this.fromDate,
    required this.toDate,
    required this.createdAt,
    this.approvedByName,
    this.cancellationReason,
  });

  final int id;
  final int memberProfileId;
  final String memberName;
  final int bookCopyId;
  final String inventoryCode;
  final int bookId;
  final String bookTitle;
  final String? coverImagePath;
  final String status;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime createdAt;
  final String? approvedByName;
  final String? cancellationReason;

  factory ReservationDto.fromJson(Map<String, dynamic> json) {
    return ReservationDto(
      id: json['id'] as int,
      memberProfileId: json['memberProfileId'] as int,
      memberName: json['memberName'] as String,
      bookCopyId: json['bookCopyId'] as int,
      inventoryCode: json['inventoryCode'] as String,
      bookId: json['bookId'] as int,
      bookTitle: json['bookTitle'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      status: json['status'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      approvedByName: json['approvedByName'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}

class CreateReservationRequest {
  CreateReservationRequest({
    required this.bookCopyId,
    required this.fromDate,
    required this.toDate,
  });

  final int bookCopyId;
  final DateTime fromDate;
  final DateTime toDate;

  Map<String, dynamic> toJson() => {
        'bookCopyId': bookCopyId,
        'fromDate': fromDate.toUtc().toIso8601String(),
        'toDate': toDate.toUtc().toIso8601String(),
      };
}

class OccupiedPeriodDto {
  OccupiedPeriodDto({
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.sourceType,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String sourceType;

  factory OccupiedPeriodDto.fromJson(Map<String, dynamic> json) {
    return OccupiedPeriodDto(
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      reason: json['reason'] as String,
      sourceType: json['sourceType'] as String,
    );
  }
}

class DateRangeDto {
  DateRangeDto({required this.fromDate, required this.toDate});

  final DateTime fromDate;
  final DateTime toDate;

  factory DateRangeDto.fromJson(Map<String, dynamic> json) {
    return DateRangeDto(
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
    );
  }
}

class AvailabilityCalendarDto {
  AvailabilityCalendarDto({
    required this.bookCopyId,
    required this.inventoryCode,
    required this.bookId,
    required this.bookTitle,
    required this.fromDate,
    required this.toDate,
    required this.occupiedPeriods,
    required this.freePeriods,
  });

  final int bookCopyId;
  final String inventoryCode;
  final int bookId;
  final String bookTitle;
  final DateTime fromDate;
  final DateTime toDate;
  final List<OccupiedPeriodDto> occupiedPeriods;
  final List<DateRangeDto> freePeriods;

  factory AvailabilityCalendarDto.fromJson(Map<String, dynamic> json) {
    return AvailabilityCalendarDto(
      bookCopyId: json['bookCopyId'] as int,
      inventoryCode: json['inventoryCode'] as String,
      bookId: json['bookId'] as int,
      bookTitle: json['bookTitle'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      occupiedPeriods: (json['occupiedPeriods'] as List<dynamic>? ?? [])
          .map((e) => OccupiedPeriodDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      freePeriods: (json['freePeriods'] as List<dynamic>? ?? [])
          .map((e) => DateRangeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
