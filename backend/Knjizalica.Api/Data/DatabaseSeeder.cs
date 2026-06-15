using Knjizalica.Api.Data.Entities;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Data;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context, UserManager<ApplicationUser> userManager, RoleManager<ApplicationRole> roleManager)
    {
        await context.Database.MigrateAsync();

        await SeedRolesAsync(roleManager);
        await SeedReferenceDataAsync(context);
        await SeedUsersAsync(userManager, context);
        await SeedAuthorsAndBooksAsync(context);
        await SeedLoansAndReservationsAsync(context);
        await SeedNewsAndNotificationsAsync(context);
        await SeedSearchHistoryAsync(context);
        await SeedActivityLogsAsync(context);

        await context.SaveChangesAsync();
    }

    private static async Task SeedRolesAsync(RoleManager<ApplicationRole> roleManager)
    {
        foreach (var role in new[] { RoleNames.Admin, RoleNames.User })
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new ApplicationRole { Name = role });
            }
        }
    }

    private static async Task SeedReferenceDataAsync(ApplicationDbContext context)
    {
        if (await context.Countries.AnyAsync())
        {
            return;
        }

        context.Countries.Add(new Country { Name = "Bosnia and Herzegovina" });
        await context.SaveChangesAsync();

        var countryId = (await context.Countries.FirstAsync()).Id;
        context.Cities.AddRange(
            new City { Name = "Sarajevo", CountryId = countryId },
            new City { Name = "Mostar", CountryId = countryId },
            new City { Name = "Tuzla", CountryId = countryId });

        context.Genres.AddRange(
            new Genre { Name = "Dystopia" },
            new Genre { Name = "Classic" },
            new Genre { Name = "Historical Fiction" },
            new Genre { Name = "Adventure" });

        context.BookCategories.AddRange(
            new BookCategory { Name = "Fiction" },
            new BookCategory { Name = "Non-Fiction" },
            new BookCategory { Name = "Science" });

        context.Languages.AddRange(
            new Language { Name = "Bosnian" },
            new Language { Name = "English" },
            new Language { Name = "Spanish" });

        context.Publishers.AddRange(
            new Publisher { Name = "Svjetlost" },
            new Publisher { Name = "Penguin Classics" },
            new Publisher { Name = "Alfa" });

        context.MembershipStatuses.AddRange(
            new MembershipStatus { Name = MembershipStatusNames.Active },
            new MembershipStatus { Name = MembershipStatusNames.Blocked },
            new MembershipStatus { Name = MembershipStatusNames.Expired });

        context.LoanStatuses.AddRange(
            new LoanStatus { Name = LoanStatusNames.Pending },
            new LoanStatus { Name = LoanStatusNames.Confirmed },
            new LoanStatus { Name = LoanStatusNames.Completed },
            new LoanStatus { Name = LoanStatusNames.Cancelled },
            new LoanStatus { Name = LoanStatusNames.Overdue });

        context.ReservationStatuses.AddRange(
            new ReservationStatus { Name = ReservationStatusNames.Pending },
            new ReservationStatus { Name = ReservationStatusNames.Confirmed },
            new ReservationStatus { Name = ReservationStatusNames.Completed },
            new ReservationStatus { Name = ReservationStatusNames.Cancelled });

        context.ActivityTypes.AddRange(
            new ActivityType { Name = "Book Created" },
            new ActivityType { Name = "Book Updated" },
            new ActivityType { Name = "Book Deleted" },
            new ActivityType { Name = "Loan Created" },
            new ActivityType { Name = "Loan Returned" },
            new ActivityType { Name = "Member Created" },
            new ActivityType { Name = "Reservation Created" },
            new ActivityType { Name = "Login" });

        await context.SaveChangesAsync();
    }

    private static async Task SeedUsersAsync(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
    {
        if (await userManager.Users.AnyAsync())
        {
            return;
        }

        var sarajevo = await context.Cities.FirstAsync(c => c.Name == "Sarajevo");
        var activeStatus = await context.MembershipStatuses.FirstAsync(s => s.Name == MembershipStatusNames.Active);

        var admin = new ApplicationUser
        {
            UserName = "desktop",
            NormalizedUserName = "DESKTOP",
            Email = "desktop@knjizalica.local",
            NormalizedEmail = "DESKTOP@KNJIZALICA.LOCAL",
            FirstName = "Library",
            LastName = "Admin",
            EmailConfirmed = true,
            PhoneNumber = "+38761100001",
            SecurityStamp = Guid.NewGuid().ToString()
        };

        var member = new ApplicationUser
        {
            UserName = "mobile",
            NormalizedEmail = "MOBILE@KNJIZALICA.LOCAL",
            NormalizedUserName = "MOBILE",
            Email = "mobile@knjizalica.local",
            FirstName = "Kenan",
            LastName = "Mehic",
            EmailConfirmed = true,
            PhoneNumber = "+38761123456",
            SecurityStamp = Guid.NewGuid().ToString()
        };

        var adminResult = await userManager.CreateAsync(admin, "test");
        if (!adminResult.Succeeded)
        {
            throw new InvalidOperationException(string.Join("; ", adminResult.Errors.Select(e => e.Description)));
        }

        await userManager.AddToRoleAsync(admin, RoleNames.Admin);

        var memberResult = await userManager.CreateAsync(member, "test");
        if (!memberResult.Succeeded)
        {
            throw new InvalidOperationException(string.Join("; ", memberResult.Errors.Select(e => e.Description)));
        }

        await userManager.AddToRoleAsync(member, RoleNames.User);

        context.MemberProfiles.Add(new MemberProfile
        {
            UserId = member.Id,
            MemberCardNumber = "K-123456",
            MembershipStatusId = activeStatus.Id,
            CityId = sarajevo.Id,
            RegistrationDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            ExpiryDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            ProfileImagePath = "/uploads/seed/default-member.png"
        });

        await context.SaveChangesAsync();
    }

    private static async Task SeedAuthorsAndBooksAsync(ApplicationDbContext context)
    {
        if (await context.Books.AnyAsync())
        {
            return;
        }

        var dystopia = await context.Genres.FirstAsync(g => g.Name == "Dystopia");
        var classic = await context.Genres.FirstAsync(g => g.Name == "Classic");
        var historical = await context.Genres.FirstAsync(g => g.Name == "Historical Fiction");
        var adventure = await context.Genres.FirstAsync(g => g.Name == "Adventure");
        var fiction = await context.BookCategories.FirstAsync(c => c.Name == "Fiction");
        var english = await context.Languages.FirstAsync(l => l.Name == "English");
        var bosnian = await context.Languages.FirstAsync(l => l.Name == "Bosnian");
        var spanish = await context.Languages.FirstAsync(l => l.Name == "Spanish");
        var penguin = await context.Publishers.FirstAsync(p => p.Name == "Penguin Classics");
        var svjetlost = await context.Publishers.FirstAsync(p => p.Name == "Svjetlost");
        var alfa = await context.Publishers.FirstAsync(p => p.Name == "Alfa");

        var orwell = new Author { FirstName = "George", LastName = "Orwell" };
        var cervantes = new Author { FirstName = "Miguel de", LastName = "Cervantes" };
        var andric = new Author { FirstName = "Ivo", LastName = "Andric" };
        var selimovic = new Author { FirstName = "Mesa", LastName = "Selimovic" };

        context.Authors.AddRange(orwell, cervantes, andric, selimovic);
        await context.SaveChangesAsync();

        var books = new[]
        {
            new Book
            {
                Title = "1984",
                Edition = "1st",
                Description = "A dystopian social science fiction novel.",
                CoverImagePath = "/uploads/seed/1984.png",
                GenreId = dystopia.Id,
                BookCategoryId = fiction.Id,
                LanguageId = english.Id,
                PublisherId = penguin.Id
            },
            new Book
            {
                Title = "Don Quijote",
                Edition = "Classic",
                Description = "The story of a noble who reads too many chivalric romances.",
                CoverImagePath = "/uploads/seed/don-quijote.png",
                GenreId = adventure.Id,
                BookCategoryId = fiction.Id,
                LanguageId = spanish.Id,
                PublisherId = alfa.Id
            },
            new Book
            {
                Title = "Na Drini cuprija",
                Edition = "Standard",
                Description = "Historical novel about life in Bosnia under Ottoman and Austro-Hungarian rule.",
                CoverImagePath = "/uploads/seed/na-drini-cuprija.png",
                GenreId = historical.Id,
                BookCategoryId = fiction.Id,
                LanguageId = bosnian.Id,
                PublisherId = svjetlost.Id
            },
            new Book
            {
                Title = "Travnicka hronika",
                Edition = "Standard",
                Description = "Novel set in Travnik during the Napoleonic era.",
                CoverImagePath = "/uploads/seed/travnicka-hronika.png",
                GenreId = historical.Id,
                BookCategoryId = fiction.Id,
                LanguageId = bosnian.Id,
                PublisherId = svjetlost.Id
            },
            new Book
            {
                Title = "Prokleto pleme",
                Edition = "Standard",
                Description = "A classic Bosnian novel.",
                CoverImagePath = "/uploads/seed/prokleto-pleme.png",
                GenreId = classic.Id,
                BookCategoryId = fiction.Id,
                LanguageId = bosnian.Id,
                PublisherId = svjetlost.Id
            },
            new Book
            {
                Title = "Dervis i smrt",
                Edition = "Standard",
                Description = "Philosophical novel about life choices and destiny.",
                CoverImagePath = "/uploads/seed/dervis-i-smrt.png",
                GenreId = classic.Id,
                BookCategoryId = fiction.Id,
                LanguageId = bosnian.Id,
                PublisherId = svjetlost.Id
            }
        };

        context.Books.AddRange(books);
        await context.SaveChangesAsync();

        context.BookAuthors.AddRange(
            new BookAuthor { BookId = books[0].Id, AuthorId = orwell.Id },
            new BookAuthor { BookId = books[1].Id, AuthorId = cervantes.Id },
            new BookAuthor { BookId = books[2].Id, AuthorId = andric.Id },
            new BookAuthor { BookId = books[3].Id, AuthorId = andric.Id },
            new BookAuthor { BookId = books[4].Id, AuthorId = selimovic.Id },
            new BookAuthor { BookId = books[5].Id, AuthorId = selimovic.Id });

        foreach (var book in books)
        {
            context.BookCopies.Add(new BookCopy
            {
                BookId = book.Id,
                InventoryCode = $"BC-{book.Id:D4}-01",
                IsAvailable = book.Title != "Prokleto pleme"
            });
            context.BookCopies.Add(new BookCopy
            {
                BookId = book.Id,
                InventoryCode = $"BC-{book.Id:D4}-02",
                IsAvailable = true
            });
        }

        await context.SaveChangesAsync();
    }

    private static async Task SeedLoansAndReservationsAsync(ApplicationDbContext context)
    {
        if (await context.Loans.AnyAsync())
        {
            return;
        }

        var member = await context.MemberProfiles.FirstAsync();
        var confirmed = await context.LoanStatuses.FirstAsync(s => s.Name == LoanStatusNames.Confirmed);
        var completed = await context.LoanStatuses.FirstAsync(s => s.Name == LoanStatusNames.Completed);
        var overdue = await context.LoanStatuses.FirstAsync(s => s.Name == LoanStatusNames.Overdue);
        var reservationConfirmed = await context.ReservationStatuses.FirstAsync(s => s.Name == ReservationStatusNames.Confirmed);

        var copies = await context.BookCopies.Include(c => c.Book).ToListAsync();
        var copy1984 = copies.First(c => c.Book.Title == "1984" && c.InventoryCode.EndsWith("-01"));
        var copyDrina = copies.First(c => c.Book.Title == "Na Drini cuprija" && c.InventoryCode.EndsWith("-01"));
        var copyTravnik = copies.First(c => c.Book.Title == "Travnicka hronika" && c.InventoryCode.EndsWith("-01"));
        var copyDonQuijote = copies.First(c => c.Book.Title == "Don Quijote" && c.InventoryCode.EndsWith("-01"));
        var today = DateTime.UtcNow.Date;

        context.Loans.AddRange(
            new Loan
            {
                MemberProfileId = member.Id,
                BookCopyId = copy1984.Id,
                LoanStatusId = completed.Id,
                BorrowedAt = DateTime.UtcNow.AddDays(-30),
                DueDate = DateTime.UtcNow.AddDays(-16),
                ReturnedAt = DateTime.UtcNow.AddDays(-18)
            },
            new Loan
            {
                MemberProfileId = member.Id,
                BookCopyId = copyDrina.Id,
                LoanStatusId = confirmed.Id,
                BorrowedAt = DateTime.UtcNow.AddDays(-5),
                DueDate = DateTime.UtcNow.AddDays(9)
            },
            new Loan
            {
                MemberProfileId = member.Id,
                BookCopyId = copyTravnik.Id,
                LoanStatusId = overdue.Id,
                BorrowedAt = DateTime.UtcNow.AddDays(-20),
                DueDate = today
            });

        context.Reservations.Add(new Reservation
        {
            MemberProfileId = member.Id,
            BookCopyId = copyDonQuijote.Id,
            ReservationStatusId = reservationConfirmed.Id,
            FromDate = today,
            ToDate = today.AddDays(7)
        });

        await context.SaveChangesAsync();
    }

    private static async Task SeedNewsAndNotificationsAsync(ApplicationDbContext context)
    {
        if (await context.News.AnyAsync())
        {
            return;
        }

        var memberUser = await context.Users.FirstAsync(u => u.UserName == "mobile");

        context.News.Add(new News
        {
            Title = "Welcome to Knjizalica",
            Content = "Our digital library system is now live. Browse, reserve, and track your loans from your mobile device.",
            ImagePath = "/uploads/seed/news-welcome.png",
            PublishedAt = DateTime.UtcNow.AddDays(-7),
            IsActive = true
        });

        context.Notifications.Add(new Notification
        {
            UserId = memberUser.Id,
            Title = "Return reminder",
            Message = "Your loan for Travnicka hronika is overdue. Please return the book as soon as possible.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow.AddHours(-2)
        });

        await context.SaveChangesAsync();
    }

    private static async Task SeedSearchHistoryAsync(ApplicationDbContext context)
    {
        if (await context.SearchHistories.AnyAsync())
        {
            return;
        }

        var memberUser = await context.Users.FirstAsync(u => u.UserName == "mobile");

        context.SearchHistories.AddRange(
            new SearchHistory { UserId = memberUser.Id, Query = "1984", CreatedAt = DateTime.UtcNow.AddDays(-10) },
            new SearchHistory { UserId = memberUser.Id, Query = "Orwell", CreatedAt = DateTime.UtcNow.AddDays(-8) },
            new SearchHistory { UserId = memberUser.Id, Query = "Andric", CreatedAt = DateTime.UtcNow.AddDays(-5) },
            new SearchHistory { UserId = memberUser.Id, Query = "historical", CreatedAt = DateTime.UtcNow.AddDays(-3) });

        await context.SaveChangesAsync();
    }

    private static async Task SeedActivityLogsAsync(ApplicationDbContext context)
    {
        if (await context.ActivityLogs.AnyAsync())
        {
            return;
        }

        var admin = await context.Users.FirstAsync(u => u.UserName == "desktop");
        var loginType = await context.ActivityTypes.FirstAsync(t => t.Name == "Login");
        var bookCreated = await context.ActivityTypes.FirstAsync(t => t.Name == "Book Created");

        context.ActivityLogs.AddRange(
            new ActivityLog
            {
                UserId = admin.Id,
                ActivityTypeId = loginType.Id,
                EntityName = "User",
                EntityId = admin.Id,
                Description = "Administrator logged in.",
                CreatedAt = DateTime.UtcNow.AddHours(-1)
            },
            new ActivityLog
            {
                UserId = admin.Id,
                ActivityTypeId = bookCreated.Id,
                EntityName = "Book",
                EntityId = 1,
                Description = "Book '1984' was added to the catalog.",
                CreatedAt = DateTime.UtcNow.AddDays(-14)
            });

        await context.SaveChangesAsync();
    }
}
