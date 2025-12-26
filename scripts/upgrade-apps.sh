#!/bin/bash
#
# This script automates the upgrade of the installed apps in overlays/x86/kustomization.yaml
#

set -euo pipefail

KUSTOMIZATION_FILE="overlays/x86/kustomization.yaml"

# Pre-fetch linuxserver.io API data to avoid multiple calls
LSIO_API_DATA=$(curl -s "https://api.linuxserver.io/api/v1/images?include_config=false&include_deprecated=false")

# Function to get the latest tag for a Docker image
get_latest_tag() {
    local image_name=$1
    local current_tag=$2
    local tags_url
    local latest_tag

    echo "Fetching tags for $image_name..." >&2

    if [[ "$image_name" == "lscr.io/linuxserver/"* ]] || [[ "$image_name" == "linuxserver/"* ]]; then
        local repo_name
        if [[ "$image_name" == "lscr.io/"* ]]; then
            repo_name=$(echo "$image_name" | cut -d'/' -f3)
        else
            repo_name=$(echo "$image_name" | cut -d'/' -f2)
        fi
        # Use pre-fetched data and parse with jq for the specific repo
        latest_tag=$(echo "$LSIO_API_DATA" | jq -r --arg repo "$repo_name" '.data.repositories.linuxserver[] | select(.name == $repo) | .version')
    elif [[ "$image_name" == */* ]]; then
        local namespace
        local repository
        namespace=$(echo "$image_name" | cut -d'/' -f1)
        repository=$(echo "$image_name" | cut -d'/' -f2)
        tags_url="https://hub.docker.com/v2/repositories/${namespace}/${repository}/tags/?page_size=100"
        # Filter for stable, non-ARM tags
        latest_tag=$(curl -s -L "$tags_url" | jq -r '.results[].name' | grep -v 'latest\|nightly\|testing\|dev\|beta\|version-\|arm' | sort -V | tail -n 1)
    else
        echo "Unsupported image name format: $image_name" >&2
        return 1
    fi

    if [[ -z "$latest_tag" ]] || [[ "$latest_tag" == "null" ]]; then
        echo "Could not find a new stable tag for $image_name. Keeping current tag: $current_tag" >&2
        echo "$current_tag"
    else
        echo "$latest_tag"
    fi
}

# Make a temporary copy to work on
TMP_KUSTOMIZATION_FILE=$(mktemp)
cp "$KUSTOMIZATION_FILE" "$TMP_KUSTOMIZATION_FILE"

image_count=$(yq e '.images | length' "$TMP_KUSTOMIZATION_FILE")

for i in $(seq 0 $((image_count - 1))); do
    name=$(yq e ".images[$i].name" "$TMP_KUSTOMIZATION_FILE")
    current_tag=$(yq e ".images[$i].newTag" "$TMP_KUSTOMIZATION_FILE")

    echo "Processing image: $name with current tag: $current_tag" >&2
    latest_tag=$(get_latest_tag "$name" "$current_tag")

    if [[ -n "$latest_tag" && "$latest_tag" != "$current_tag" ]]; then
        echo "Updating $name from $current_tag to $latest_tag" >&2
        yq -i ".images[$i].newTag = \"$latest_tag\"" "$TMP_KUSTOMIZATION_FILE"
    else
        echo "No update found for $name. Current tag is the latest stable." >&2
    fi
done

# Replace the original file with the updated one
mv "$TMP_KUSTOMIZATION_FILE" "$KUSTOMIZATION_FILE"
echo "Kustomization file updated." >&2
