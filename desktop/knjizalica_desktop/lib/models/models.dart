class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  @override
  String toString() => message;
}

class PagedResult<T> {
  PagedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PagedResult(
      items: rawItems.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
}

class LookupItem {
  LookupItem({required this.id, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  final int id;
  final String name;
}

class UserInfo {
  UserInfo({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  String get fullName => '$firstName $lastName';
  bool get isAdmin => roles.contains('Admin');
}

class AuthResponse {
  AuthResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      user: UserInfo.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String token;
  final DateTime expiresAt;
  final UserInfo user;
}

class DashboardKpi {
  DashboardKpi({
    required this.totalBooks,
    required this.totalBookCopies,
    required this.availableCopies,
    required this.activeLoans,
    required this.overdueLoans,
    required this.pendingLoans,
    required this.newMembersThisMonth,
    required this.newMembersThisYear,
    required this.returnedBooksThisMonth,
    required this.totalMembers,
    required this.pendingReservations,
    required this.activeReservations,
  });

  factory DashboardKpi.fromJson(Map<String, dynamic> json) {
    return DashboardKpi(
      totalBooks: json['totalBooks'] as int? ?? 0,
      totalBookCopies: json['totalBookCopies'] as int? ?? 0,
      availableCopies: json['availableCopies'] as int? ?? 0,
      activeLoans: json['activeLoans'] as int? ?? 0,
      overdueLoans: json['overdueLoans'] as int? ?? 0,
      pendingLoans: json['pendingLoans'] as int? ?? 0,
      newMembersThisMonth: json['newMembersThisMonth'] as int? ?? 0,
      newMembersThisYear: json['newMembersThisYear'] as int? ?? 0,
      returnedBooksThisMonth: json['returnedBooksThisMonth'] as int? ?? 0,
      totalMembers: json['totalMembers'] as int? ?? 0,
      pendingReservations: json['pendingReservations'] as int? ?? 0,
      activeReservations: json['activeReservations'] as int? ?? 0,
    );
  }

  final int totalBooks;
  final int totalBookCopies;
  final int availableCopies;
  final int activeLoans;
  final int overdueLoans;
  final int pendingLoans;
  final int newMembersThisMonth;
  final int newMembersThisYear;
  final int returnedBooksThisMonth;
  final int totalMembers;
  final int pendingReservations;
  final int activeReservations;
}

class ChartDataPoint {
  ChartDataPoint({required this.label, required this.value});

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      value: json['value'] as int? ?? 0,
    );
  }

  final String label;
  final int value;
}

class DashboardData {
  DashboardData({required this.kpis, required this.charts});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final chartsJson = json['charts'] as Map<String, dynamic>? ?? {};
    List<ChartDataPoint> parseList(String key) {
      return (chartsJson[key] as List<dynamic>? ?? [])
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return DashboardData(
      kpis: DashboardKpi.fromJson(json['kpis'] as Map<String, dynamic>),
      charts: DashboardCharts(
        loansByMonth: parseList('loansByMonth'),
        topBorrowedBooks: parseList('topBorrowedBooks'),
        membersByCity: parseList('membersByCity'),
        loansByStatus: parseList('loansByStatus'),
        loansLast7Days: parseList('loansLast7Days'),
        topGenres: parseList('topGenres'),
      ),
    );
  }

  final DashboardKpi kpis;
  final DashboardCharts charts;
}

class DashboardCharts {
  DashboardCharts({
    required this.loansByMonth,
    required this.topBorrowedBooks,
    required this.membersByCity,
    required this.loansByStatus,
    required this.loansLast7Days,
    required this.topGenres,
  });

  final List<ChartDataPoint> loansByMonth;
  final List<ChartDataPoint> topBorrowedBooks;
  final List<ChartDataPoint> membersByCity;
  final List<ChartDataPoint> loansByStatus;
  final List<ChartDataPoint> loansLast7Days;
  final List<ChartDataPoint> topGenres;
}

class Author {
  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.biography,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      biography: json['biography'] as String?,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String? biography;

  String get fullName => '$firstName $lastName';
}

class BookCopy {
  BookCopy({
    required this.id,
    required this.inventoryCode,
    required this.isAvailable,
  });

  factory BookCopy.fromJson(Map<String, dynamic> json) {
    return BookCopy(
      id: json['id'] as int,
      inventoryCode: json['inventoryCode'] as String,
      isAvailable: json['isAvailable'] as bool? ?? false,
    );
  }

  final int id;
  final String inventoryCode;
  final bool isAvailable;
}

class BookListItem {
  BookListItem({
    required this.id,
    required this.title,
    this.edition,
    this.coverImagePath,
    required this.genreName,
    required this.categoryName,
    required this.languageName,
    required this.publisherName,
    required this.totalCopies,
    required this.availableCopies,
    required this.authorNames,
  });

  factory BookListItem.fromJson(Map<String, dynamic> json) {
    return BookListItem(
      id: json['id'] as int,
      title: json['title'] as String,
      edition: json['edition'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      genreName: json['genreName'] as String,
      categoryName: json['categoryName'] as String,
      languageName: json['languageName'] as String,
      publisherName: json['publisherName'] as String,
      totalCopies: json['totalCopies'] as int? ?? 0,
      availableCopies: json['availableCopies'] as int? ?? 0,
      authorNames: (json['authorNames'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final int id;
  final String title;
  final String? edition;
  final String? coverImagePath;
  final String genreName;
  final String categoryName;
  final String languageName;
  final String publisherName;
  final int totalCopies;
  final int availableCopies;
  final List<String> authorNames;

  bool get isAvailable => availableCopies > 0;
}

class BookDetail {
  BookDetail({
    required this.id,
    required this.title,
    this.edition,
    this.description,
    this.coverImagePath,
    required this.genreId,
    required this.genreName,
    required this.bookCategoryId,
    required this.categoryName,
    required this.languageId,
    required this.languageName,
    required this.publisherId,
    required this.publisherName,
    required this.createdAt,
    required this.authors,
    required this.copies,
    required this.totalCopies,
    required this.availableCopies,
  });

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    return BookDetail(
      id: json['id'] as int,
      title: json['title'] as String,
      edition: json['edition'] as String?,
      description: json['description'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      genreId: json['genreId'] as int,
      genreName: json['genreName'] as String,
      bookCategoryId: json['bookCategoryId'] as int,
      categoryName: json['categoryName'] as String,
      languageId: json['languageId'] as int,
      languageName: json['languageName'] as String,
      publisherId: json['publisherId'] as int,
      publisherName: json['publisherName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      authors: (json['authors'] as List<dynamic>? ?? [])
          .map((e) => Author.fromJson(e as Map<String, dynamic>))
          .toList(),
      copies: (json['copies'] as List<dynamic>? ?? [])
          .map((e) => BookCopy.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCopies: json['totalCopies'] as int? ?? 0,
      availableCopies: json['availableCopies'] as int? ?? 0,
    );
  }

  final int id;
  final String title;
  final String? edition;
  final String? description;
  final String? coverImagePath;
  final int genreId;
  final String genreName;
  final int bookCategoryId;
  final String categoryName;
  final int languageId;
  final String languageName;
  final int publisherId;
  final String publisherName;
  final DateTime createdAt;
  final List<Author> authors;
  final List<BookCopy> copies;
  final int totalCopies;
  final int availableCopies;
}

class Loan {
  Loan({
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

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
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

  bool get isOverdue =>
      status == 'Overdue' ||
      (returnedAt == null &&
          dueDate.isBefore(DateTime.now().toUtc()) &&
          (status == 'Confirmed' || status == 'Overdue'));
}

class Member {
  Member({
    required this.id,
    required this.userId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.memberCardNumber,
    required this.membershipStatus,
    required this.cityId,
    required this.cityName,
    this.profileImagePath,
    required this.registrationDate,
    required this.expiryDate,
    required this.isActive,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      memberCardNumber: json['memberCardNumber'] as String,
      membershipStatus: json['membershipStatus'] as String,
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      profileImagePath: json['profileImagePath'] as String?,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  final int id;
  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String memberCardNumber;
  final String membershipStatus;
  final int cityId;
  final String cityName;
  final String? profileImagePath;
  final DateTime registrationDate;
  final DateTime expiryDate;
  final bool isActive;

  String get fullName => '$firstName $lastName';
}

class Reservation {
  Reservation({
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

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
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
}

class ActivityLog {
  ActivityLog({
    required this.id,
    this.userId,
    this.userName,
    required this.activityType,
    required this.entityName,
    this.entityId,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as int,
      userId: json['userId'] as int?,
      userName: json['userName'] as String?,
      activityType: json['activityType'] as String,
      entityName: json['entityName'] as String,
      entityId: json['entityId'] as int?,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final int id;
  final int? userId;
  final String? userName;
  final String activityType;
  final String entityName;
  final int? entityId;
  final String description;
  final DateTime createdAt;
}

class Country {
  Country({required this.id, required this.name});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}

class City {
  City({
    required this.id,
    required this.name,
    required this.countryId,
    this.countryName,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
      countryId: json['countryId'] as int,
      countryName: json['countryName'] as String?,
    );
  }

  final int id;
  final String name;
  final int countryId;
  final String? countryName;
}

class FileUploadResult {
  FileUploadResult({
    required this.path,
    required this.fileName,
    required this.contentType,
    required this.sizeBytes,
  });

  factory FileUploadResult.fromJson(Map<String, dynamic> json) {
    return FileUploadResult(
      path: json['path'] as String,
      fileName: json['fileName'] as String,
      contentType: json['contentType'] as String,
      sizeBytes: json['sizeBytes'] as int? ?? 0,
    );
  }

  final String path;
  final String fileName;
  final String contentType;
  final int sizeBytes;
}

class NewsItem {
  NewsItem({
    required this.id,
    required this.title,
    required this.content,
    this.imagePath,
    required this.publishedAt,
    required this.isActive,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      imagePath: json['imagePath'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final int id;
  final String title;
  final String content;
  final String? imagePath;
  final DateTime publishedAt;
  final bool isActive;
}
