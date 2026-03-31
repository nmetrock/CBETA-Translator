# Repository instructions

## Validation

This repository uses an offline NuGet workflow.

Do not start validation with:
`env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.App.sln --no-restore`

That command fails in a cold environment because the required restored package state does not exist yet.

Always validate with:

`scripts/validate-codex.sh`

Equivalent manual commands:

`env DOTNET_CLI_HOME=/tmp dotnet restore CbetaTranslator.App.sln --locked-mode --configfile NuGet.Config`
`env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.App.sln --no-restore`

## Build output behavior

A first build in a cold environment performs real compilation and may emit existing warnings.
A second identical build may complete much faster and produce no warnings because MSBuild skips unchanged work.

Do not interpret the absence of warnings on a no-op incremental build as a change in warning state.
