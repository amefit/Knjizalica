# Knjizalica

Digital library management system — **Razvoj softvera II** project - IB240333.

## Architecture

| Component | Path | Technology |
|-----------|------|------------|
| REST API | `backend/Knjizalica.Api` | .NET 9, EF Core, JWT, SignalR |
| Worker | `backend/Knjizalica.Worker` | RabbitMQ + MailKit (email) |
| Desktop admin | `desktop/knjizalica_desktop` | Flutter Windows |
| Mobile client | `mobile/knjizalica_mobile` | Flutter Android |

## Prerequisites

- .NET 9 SDK
- Visual Studio 2022 (17.12 preferable) or VS 2026 with **ASP.NET** workload
- SQL Server or LocalDB
- Flutter SDK (for mobile/desktop clients)
- Docker Desktop

## Quick Start — Backend

1. For **LocalDB** (easiest on Windows), set in `.env`:
   ```
   DB_CONNECTION_STRING=Server=(localdb)\MSSQLLocalDB;Database=240333;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true
   ```

2. Open **`Knjizalica.sln`** in Visual Studio, set **Knjizalica.Api** as startup project, press F5.

   Or from terminal:
   ```powershell
   cd to root folder then cd backend\Knjizalica.Api
   dotnet run
   ```

3. Swagger available at: `http://localhost:5000/swagger`

## Test Credentials

| Context | Username | Password | Role |
|---------|----------|----------|------|
| Desktop admin | `desktop` | `Testni0.` | Admin |
| Mobile member | `mobile` | `Testni0.` | User |

## Flutter Clients

Generate platform folders (first time only):
```powershell
cd mobile\knjizalica_mobile
.\setup.ps1
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

```powershell
cd desktop\knjizalica_desktop
.\setup.ps1
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5000
```

## Docker

```powershell
docker compose up -d --build
```

Uses SQL Server container + RabbitMQ + MailHog + API + Worker. Update `.env` connection string for Docker as documented in `.env.example`.

**Test email (MailHog):** After `docker compose up`, open `http://localhost:8025` to read password-reset and other emails.

## API Overview

| Module | Route prefix |
|--------|--------------|
| Auth | `/api/auth` |
| Books | `/api/books` |
| Authors | `/api/authors` |
| Members | `/api/members` |
| Loans | `/api/loans` |
| Reservations | `/api/reservations` |
| Notifications | `/api/notifications` |
| News | `/api/news` |
| Recommendations | `/api/recommendations` |
| Dashboard | `/api/dashboard` |
| Reports (PDF) | `/api/reports` |
| Reference data | `/api/referencedata` |
| Activity logs | `/api/activitylogs` |
| Files | `/api/files` |
| SignalR hub | `/hubs/notifications` |

## Documentation

- Recommendation system: [`recommender-dokumentacija.md`](recommender-dokumentacija.md)

## Database

- Name: **240333**
- Migrations applied automatically on startup
- Seed includes books, members, loans, reservations, reference data