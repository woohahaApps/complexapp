# https://hub.docker.com/_/microsoft-dotnet
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /source

# copy csproj and restore as distinct layers
#COPY complexapp/*.csproj complexapp/
#COPY libfoo/*.csproj libfoo/
#COPY libbar/*.csproj libbar/
#RUN dotnet restore complexapp/complexapp.csproj

# copy and build app and libraries
COPY complexapp/ complexapp/
COPY libfoo/ libfoo/
COPY libbar/ libbar/
RUN dotnet restore complexapp/*.csproj
RUN dotnet restore libfoo/*.csproj
RUN dotnet restore libbar/*.csproj
WORKDIR /source/complexapp
RUN dotnet build -c Release --no-restore

# test stage -- exposes optional entrypoint
# target entrypoint with: docker build --target test
FROM build AS test
WORKDIR /source/tests

#COPY tests/*.csproj .
#RUN dotnet restore tests.csproj

COPY tests/ .
RUN dotnet restore *.csproj
RUN dotnet build --no-restore

ENTRYPOINT ["dotnet", "test", "--logger:trx", "--no-restore", "--no-build"]

FROM build AS publish
RUN dotnet publish -c Release --no-build -o /app

# final stage/image
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "complexapp.dll"]
