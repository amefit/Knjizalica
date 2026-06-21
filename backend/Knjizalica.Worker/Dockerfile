FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Directory.Build.props Directory.Packages.props ./
COPY Knjizalica.Shared/Knjizalica.Shared.csproj Knjizalica.Shared/
COPY Knjizalica.Api/Knjizalica.Api.csproj Knjizalica.Api/
COPY Knjizalica.Worker/Knjizalica.Worker.csproj Knjizalica.Worker/
RUN dotnet restore Knjizalica.Worker/Knjizalica.Worker.csproj

COPY . .
RUN dotnet publish Knjizalica.Worker/Knjizalica.Worker.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/runtime:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "Knjizalica.Worker.dll"]
