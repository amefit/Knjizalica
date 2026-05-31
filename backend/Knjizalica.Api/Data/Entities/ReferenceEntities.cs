namespace Knjizalica.Api.Data.Entities;

public sealed class Country
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<City> Cities { get; set; } = [];
}

public sealed class City
{
    public int Id { get; set; }
    public required string Name { get; set; }
    public int CountryId { get; set; }

    public Country Country { get; set; } = null!;
    public ICollection<MemberProfile> MemberProfiles { get; set; } = [];
}

public sealed class Genre
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Book> Books { get; set; } = [];
}

public sealed class BookCategory
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Book> Books { get; set; } = [];
}

public sealed class Language
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Book> Books { get; set; } = [];
}

public sealed class Publisher
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Book> Books { get; set; } = [];
}

public sealed class MembershipStatus
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<MemberProfile> MemberProfiles { get; set; } = [];
}

public sealed class LoanStatus
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Loan> Loans { get; set; } = [];
}

public sealed class ReservationStatus
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<Reservation> Reservations { get; set; } = [];
}

public sealed class ActivityType
{
    public int Id { get; set; }
    public required string Name { get; set; }

    public ICollection<ActivityLog> ActivityLogs { get; set; } = [];
}
