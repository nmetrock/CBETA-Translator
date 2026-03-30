#!/usr/bin/env bash
set -euo pipefail

env DOTNET_CLI_HOME=/tmp dotnet restore CbetaTranslator.App.sln --locked-mode --configfile NuGet.Config
env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.App.sln --no-restore

