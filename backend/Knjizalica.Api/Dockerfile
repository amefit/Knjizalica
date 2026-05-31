FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY Knjizalica.Shared/Knjizalica.Shared.csproj Knjizalica.Shared/
COPY Knjizalica.Api/Knjizalica.Api.csproj Knjizalica.Api/
RUN dotnet restore Knjizalica.Api/Knjizalica.Api.csproj

COPY . .
RUN dotnet publish Knjizalica.Api/Knjizalica.Api.csproj -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 5000
ENTRYPOINT ["dotnet", "Knjizalica.Api.dll"]
