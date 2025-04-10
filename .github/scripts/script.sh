#!/bin/bash

set -e

BRANCH="${GITHUB_REF##*/}"
COMMIT="${GITHUB_SHA::7}"
VERSION=$(jq -r '.expo.version' app.json)
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
RECENT_COMMITS=$(git log -3 --pretty=format:"- %s (%an)" || echo "No commit history available")

if [[ "$BRANCH" == "main" ]]; then
  BUILD_TYPE="Production"
else
  BUILD_TYPE="Preview"
fi

TEXT="🚀 *New $BUILD_TYPE Build Triggered!*\n"
TEXT+="📱 *App:* World360\n"
TEXT+="🏷️ *Version:* $VERSION\n"
TEXT+="🔧 *Build Type:* $BUILD_TYPE\n"
TEXT+="🌿 *Branch:* $BRANCH\n"
TEXT+="🧱 *Commit:* \`$COMMIT\`\n"
TEXT+="🕒 *Time:* $TIMESTAMP\n"
TEXT+="📋 *Recent Commits:*\n$RECENT_COMMITS\n"
TEXT+="🔗 *Builds:* <https://expo.dev/accounts/rn-amit/projects/expo-app/builds|Open in EAS Dashboard>"

payload=$(jq -n --arg text "$TEXT" '{text: $text}')

echo "Sending Slack notification..."
response=$(curl -s -w "%{http_code}" -o /tmp/response.txt -X POST -H "Content-type: application/json" \
  --data "$payload" "$SLACK_WEBHOOK_URL")

http_code=$(cat /tmp/response.txt)

if [[ "$response" != "200" ]]; then
  echo "⚠️ Slack notification failed with status $response"
  echo "Response: $http_code"
  exit 1
else
  echo "✅ Slack notification sent successfully"
fi
