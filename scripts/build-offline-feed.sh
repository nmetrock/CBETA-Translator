#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK_FILE="${1:-$ROOT/packages.lock.json}"
FEED_DIR="${2:-$ROOT/vendor/nuget-feed}"

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "Lock file not found: $LOCK_FILE" >&2
  exit 1
fi

mkdir -p "$FEED_DIR"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

need_cmd jq
need_cmd curl

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Reading locked packages from: $LOCK_FILE"
echo "Writing offline feed to:      $FEED_DIR"

jq -r '
  .dependencies
  | to_entries[]
  | .value
  | to_entries[]
  | "\(.key)\t\(.value.resolved)\t\(.value.type)"
' "$LOCK_FILE" | sort -f -u > "$TMP_DIR/packages.tsv"

TOTAL="$(wc -l < "$TMP_DIR/packages.tsv" | tr -d " ")"
if [[ "$TOTAL" == "0" ]]; then
  echo "No packages found in lock file." >&2
  exit 1
fi

echo "Found $TOTAL locked packages."
echo

have_dotnet_package_download=false
if dotnet package download -h >/dev/null 2>&1; then
  have_dotnet_package_download=true
fi

download_with_dotnet() {
  local package_id="$1"
  local version="$2"

  echo "Downloading with dotnet: $package_id $version"
  dotnet package download "${package_id}@${version}" \
    --output "$FEED_DIR" \
    --source "https://api.nuget.org/v3/index.json" \
    --verbosity minimal >/dev/null
}

download_with_curl() {
  local package_id="$1"
  local version="$2"

  local package_id_lower
  package_id_lower="$(printf '%s' "$package_id" | tr '[:upper:]' '[:lower:]')"

  local version_lower
  version_lower="$(printf '%s' "$version" | tr '[:upper:]' '[:lower:]')"

  local dest="$FEED_DIR/${package_id}.${version}.nupkg"
  local tmp="$TMP_DIR/${package_id}.${version}.nupkg"

  # Prefer the NuGet flat container artifact.
  local url="https://api.nuget.org/v3-flatcontainer/${package_id_lower}/${version_lower}/${package_id_lower}.${version_lower}.nupkg"

  echo "Downloading with curl: $package_id $version"
  curl --fail --location --silent --show-error \
    --output "$tmp" \
    "$url"

  mv "$tmp" "$dest"
}

while IFS=$'\t' read -r package_id version package_type; do
  if [[ -z "$package_id" || -z "$version" || "$version" == "null" ]]; then
    echo "Invalid lock entry: package_id='$package_id' version='$version'" >&2
    exit 1
  fi

  dest="$FEED_DIR/${package_id}.${version}.nupkg"
  if [[ -f "$dest" ]]; then
    echo "Already present: ${package_id}.${version}.nupkg"
    continue
  fi

  if [[ "$have_dotnet_package_download" == true ]]; then
    download_with_dotnet "$package_id" "$version"
  else
    download_with_curl "$package_id" "$version"
  fi
done < "$TMP_DIR/packages.tsv"

jq '
  {
    generatedAtUtc: (now | todateiso8601),
    sourceLockFile: input_filename,
    packages: [
      .dependencies
      | to_entries[]
      | .value
      | to_entries[]
      | {
          id: .key,
          resolved: .value.resolved,
          type: .value.type,
          contentHash: .value.contentHash
        }
    ]
  }
' "$LOCK_FILE" > "$FEED_DIR/offline-feed-manifest.json"

echo
echo "Offline feed complete."
echo "Packages written to: $FEED_DIR"
echo "Manifest written to: $FEED_DIR/offline-feed-manifest.json"
echo
echo "Validate the feed with:"
echo "  env DOTNET_CLI_HOME=/tmp dotnet restore CbetaTranslator.App.sln --locked-mode --configfile NuGet.Config"
echo "  env DOTNET_CLI_HOME=/tmp dotnet build CbetaTranslator.App.sln --no-restore"
