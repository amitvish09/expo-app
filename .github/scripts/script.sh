#!/bin/bash

set -e

WEBHOOK_URL="$1"

if [[ -z "$WEBHOOK_URL" ]]; then
  echo "❌ SLACK_WEBHOOK_URL not provided"
  exit 1
fi

if [[ "$GITHUB_REF" == refs/heads/* ]]; then
  REF="${GITHUB_REF#refs/heads/}"
elif [[ "$GITHUB_REF" == refs/tags/* ]]; then
  REF="${GITHUB_REF#refs/tags/}"
else
  REF="$GITHUB_REF"
fi

if [[ "$REF" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-.*-release$ ]]; then
  BUILD_TYPE="Production"
else
  BUILD_TYPE="Preview"
fi

COMMIT="${GITHUB_SHA::7}"
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
APP_NAME=$(jq -r '.expo.name // "unknown"' app.json 2>/dev/null || echo "unknown")
VERSION=$(jq -r '.expo.version // "unknown"' app.json 2>/dev/null || echo "unknown")
RECENT_COMMITS=$(git log -3 --pretty=format:"- %s (%an)" 2>/dev/null || echo "No recent commits")
BUILD_URL="https://expo.dev/accounts/rn-amit/projects/expo-app/builds"

TEXT="🚀 *New $BUILD_TYPE Build Triggered!*\n"
TEXT+="📱 *App:* $APP_NAME\n"
TEXT+="📱 *App:* $APP_NAME\n"
TEXT+="🏷️ *Version:* $VERSION\n"
TEXT+="🔧 *Build Type:* $BUILD_TYPE\n"
TEXT+="🌿 *Branch/Tag:* $REF\n"
TEXT+="🧱 *Commit:* \`$COMMIT\`\n"
TEXT+="🕒 *Time:* $TIMESTAMP\n"
TEXT+="$AFFECTED_LINE"
TEXT+="📋 *Recent Commits:*\n$RECENT_COMMITS\n"
TEXT+="🔗 *CI Logs:* <$BUILD_URL|View Build Logs>"

curl -X POST -H "Content-type: application/json" \
  --data "{\"text\": \"$TEXT\"}" \
  "$WEBHOOK_URL"
