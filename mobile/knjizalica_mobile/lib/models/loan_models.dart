class LoanDto {
  LoanDto({
    required this.id,
    required this.memberProfileId,
    required this.memberName,
    required this.memberCardNumber,
    required this.bookCopyId,
    required this.inventoryCode,
    required this.bookId,
    required this.bookTitle,
    this.coverImagePath,
    required this.status,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.notes,
  });

  final int id;
  final int memberProfileId;
  final String memberName;
  final String memberCardNumber;
  final int bookCopyId;
  final String inventoryCode;
  final int bookId;
  final String bookTitle;
  final String? coverImagePath;
  final String status;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? notes;

  bool get isOverdue => status == 'Overdue';

  bool get isActive =>
      status == 'Confirmed' || status == 'Pending' || status == 'Overdue';

  bool get isReturned => status == 'Completed';

  factory LoanDto.fromJson(Map<String, dynamic> json) {
    return LoanDto(
      id: json['id'] as int,
      memberProfileId: json['memberProfileId'] as int,
      memberName: json['memberName'] as String,
      memberCardNumber: json['memberCardNumber'] as String,
      bookCopyId: json['bookCopyId'] as int,
      inventoryCode: json['inventoryCode'] as String,
      bookId: json['bookId'] as int,
      bookTitle: json['bookTitle'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      status: json['status'] as String,
      borrowedAt: DateTime.parse(json['borrowedAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      returnedAt: json['returnedAt'] != null
          ? DateTime.parse(json['returnedAt'] as String)
          : null,
      approvedByName: json['approvedByName'] as String?,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
