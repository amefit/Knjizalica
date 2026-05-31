namespace Knjizalica.Api.DTOs.Dashboard;

public sealed class DashboardKpiDto
{
    public int TotalBooks { get; init; }
    public int TotalBookCopies { get; init; }
    public int AvailableCopies { get; init; }
    public int ActiveLoans { get; init; }
    public int OverdueLoans { get; init; }
    public int PendingLoans { get; init; }
    public int NewMembersThisMonth { get; init; }
    public int NewMembersThisYear { get; init; }
    public int ReturnedBooksThisMonth { get; init; }
    public int TotalMembers { get; init; }
    public int PendingReservations { get; init; }
    public int ActiveReservations { get; init; }
}

public sealed class ChartDataPointDto
{
    public required string Label { get; init; }
    public int Value { get; init; }
}

public sealed class DashboardChartsDto
{
    public IReadOnlyList<ChartDataPointDto> LoansByMonth { get; init; } = [];
    public IReadOnlyList<ChartDataPointDto> TopBorrowedBooks { get; init; } = [];
    public IReadOnlyList<ChartDataPointDto> MembersByCity { get; init; } = [];
    public IReadOnlyList<ChartDataPointDto> LoansByStatus { get; init; } = [];
    public IReadOnlyList<ChartDataPointDto> LoansLast7Days { get; init; } = [];
    public IReadOnlyList<ChartDataPointDto> TopGenres { get; init; } = [];
}

public sealed class DashboardDto
{
    public required DashboardKpiDto Kpis { get; init; }
    public required DashboardChartsDto Charts { get; init; }
}
