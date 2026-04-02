#!/usr/bin/env bash
set -euo pipefail

env DOTNET_CLI_HOME=/tmp dotnet restore CbetaTranslator.App.csproj --locked-mode --configfile NuGet.Config
env DOTNET_CLI_HOME=/tmp dotnet restore CbetaTranslator.Tests/CbetaTranslator.Tests.csproj --locked-mode --configfile NuGet.Config
env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.App.csproj --no-restore
env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.Tests/CbetaTranslator.Tests.csproj --no-restore
