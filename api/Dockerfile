# Multi-stage Dockerfile cho .NET 10 Web API
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy file csproj và restore dependencies
COPY ["WebBanHang.Api.csproj", "./"]
RUN dotnet restore "WebBanHang.Api.csproj"

# Copy toàn bộ mã nguồn và build
COPY . .
RUN dotnet publish "WebBanHang.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Stage runtime nhẹ nhàng
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "WebBanHang.Api.dll"]
