#!/bin/bash

set -e

WEBHOOK_URL="$1"

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "❌ SLACK_WEBHOOK_URL not provided"
  exit 1
fi

# Get branch or tag info
if [[ "$GITHUB_REF" == refs/heads/* ]]; then
  BRANCH="${GITHUB_REF#refs/heads/}"
elif [[ "$GITHUB_REF" == refs/tags/* ]]; then
  BRANCH="${GITHUB_REF#refs/tags/}"
else
  BRANCH="$GITHUB_REF"
fi

# Determine build type based on tag pattern or branch
if [[ "$BRANCH" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-.*-release$ ]]; then
  BUILD_TYPE="Production"
else
  BUILD_TYPE="Preview"
fi

# Short commit SHA
COMMIT="${GITHUB_SHA::7}"

# Human-readable timestamp (UTC)
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Get app version from app.json (fallback to 'unknown')
VERSION=$(jq -r '.expo.version // "unknown"' app.json 2>/dev/null || echo "unknown")

# Get recent commits (3 most recent)
RECENT_COMMITS=$(git log -3 --pretty=format:"- %s (%an)" 2>/dev/null || echo "No commit history available")

# Link to the GitHub Actions build logs
BUILD_URL="https://expo.dev/accounts/rn-amit/projects/expo-app/builds"

# Construct Slack message
TEXT="🚀 *New $BUILD_TYPE Build Triggered!*\n"
TEXT+="📱 *App:* expo-app\n"
TEXT+="🏷️ *Version:* $VERSION\n"
TEXT+="🔧 *Build Type:* $BUILD_TYPE\n"
TEXT+="🌿 *Branch/Tag:* $BRANCH\n"
TEXT+="🧱 *Commit:* \`$COMMIT\`\n"
TEXT+="🕒 *Time:* $TIMESTAMP\n"
TEXT+="📋 *Recent Commits:*\n$RECENT_COMMITS\n"
TEXT+="🔗 *CI Logs:* <$BUILD_URL|View Build on GitHub>"

# Send to Slack
curl -X POST -H "Content-type: application/json" \
  --data "{\"text\": \"$TEXT\"}" \
  "$WEBHOOK_URL"
