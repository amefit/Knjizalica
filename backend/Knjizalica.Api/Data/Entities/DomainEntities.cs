namespace Knjizalica.Api.Data.Entities;

public sealed class Author
{
    public int Id { get; set; }
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public string? Biography { get; set; }

    public ICollection<BookAuthor> BookAuthors { get; set; } = [];
}

public sealed class Book
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public string? Edition { get; set; }
    public string? Description { get; set; }
    public string? CoverImagePath { get; set; }
    public int GenreId { get; set; }
    public int BookCategoryId { get; set; }
    public int LanguageId { get; set; }
    public int PublisherId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Genre Genre { get; set; } = null!;
    public BookCategory BookCategory { get; set; } = null!;
    public Language Language { get; set; } = null!;
    public Publisher Publisher { get; set; } = null!;
    public ICollection<BookAuthor> BookAuthors { get; set; } = [];
    public ICollection<BookCopy> BookCopies { get; set; } = [];
}

public sealed class BookAuthor
{
    public int BookId { get; set; }
    public int AuthorId { get; set; }

    public Book Book { get; set; } = null!;
    public Author Author { get; set; } = null!;
}

public sealed class BookCopy
{
    public int Id { get; set; }
    public int BookId { get; set; }
    public required string InventoryCode { get; set; }
    public bool IsAvailable { get; set; } = true;

    public Book Book { get; set; } = null!;
    public ICollection<Loan> Loans { get; set; } = [];
    public ICollection<Reservation> Reservations { get; set; } = [];
}

public sealed class MemberProfile
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public required string MemberCardNumber { get; set; }
    public int MembershipStatusId { get; set; }
    public int CityId { get; set; }
    public string? ProfileImagePath { get; set; }
    public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
    public DateTime ExpiryDate { get; set; }

    public ApplicationUser User { get; set; } = null!;
    public MembershipStatus MembershipStatus { get; set; } = null!;
    public City City { get; set; } = null!;
    public ICollection<Loan> Loans { get; set; } = [];
    public ICollection<Reservation> Reservations { get; set; } = [];
}

public sealed class Loan
{
    public int Id { get; set; }
    public int MemberProfileId { get; set; }
    public int BookCopyId { get; set; }
    public int LoanStatusId { get; set; }
    public DateTime BorrowedAt { get; set; } = DateTime.UtcNow;
    public DateTime DueDate { get; set; }
    public DateTime? ReturnedAt { get; set; }
    public int? ApprovedByUserId { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public string? RejectionReason { get; set; }
    public string? Notes { get; set; }

    public MemberProfile MemberProfile { get; set; } = null!;
    public BookCopy BookCopy { get; set; } = null!;
    public LoanStatus LoanStatus { get; set; } = null!;
    public ApplicationUser? ApprovedByUser { get; set; }
}

public sealed class Reservation
{
    public int Id { get; set; }
    public int MemberProfileId { get; set; }
    public int BookCopyId { get; set; }
    public int ReservationStatusId { get; set; }
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public int? ApprovedByUserId { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public DateTime? CancelledAt { get; set; }
    public int? CancelledByUserId { get; set; }
    public string? CancellationReason { get; set; }

    public MemberProfile MemberProfile { get; set; } = null!;
    public BookCopy BookCopy { get; set; } = null!;
    public ReservationStatus ReservationStatus { get; set; } = null!;
    public ApplicationUser? ApprovedByUser { get; set; }
    public ApplicationUser? CancelledByUser { get; set; }
}

public sealed class Notification
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public required string Title { get; set; }
    public required string Message { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;
}

public sealed class News
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public required string Content { get; set; }
    public string? ImagePath { get; set; }
    public DateTime PublishedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}

public sealed class ActivityLog
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    public int ActivityTypeId { get; set; }
    public required string EntityName { get; set; }
    public int? EntityId { get; set; }
    public required string Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser? User { get; set; }
    public ActivityType ActivityType { get; set; } = null!;
}

public sealed class SearchHistory
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public required string Query { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;
}
