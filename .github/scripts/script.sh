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

# App name passed in from workflow (fallback to "World360")
APP_NAME="${APP_NAME:-Unknown App}"

# Escape commit messages for Slack and get last 3
RECENT_COMMITS=$(git log -3 --pretty=format:"- %s (%an)" 2>/dev/null | sed 's/"/\\"/g' || echo "No commit history available")

# Detect affected packages (optional, useful for monorepos)
AFFECTED_PACKAGES=$(yarn turbo run build --dry=json 2>/dev/null | jq -r '.tasks[].package' | sort -u | paste -sd ", " -)
AFFECTED_LINE=""
if [[ -n "$AFFECTED_PACKAGES" ]]; then
  AFFECTED_LINE="📦 *Affected:* $AFFECTED_PACKAGES\n"
fi

# Link to the GitHub Actions build logs or EAS dashboard
BUILD_URL="https://expo.dev/accounts/fcapps/projects/world360/builds"

# Construct Slack message
TEXT="🚀 *New $BUILD_TYPE Build Triggered!*\n"
TEXT+="📱 *App:* $APP_NAME\n"
TEXT+="🏷️ *Version:* $VERSION\n"
TEXT+="🔧 *Build Type:* $BUILD_TYPE\n"
TEXT+="🌿 *Branch/Tag:* $BRANCH\n"
TEXT+="🧱 *Commit:* \`$COMMIT\`\n"
TEXT+="🕒 *Time:* $TIMESTAMP\n"
TEXT+="$AFFECTED_LINE"
TEXT+="📋 *Recent Commits:*\n$RECENT_COMMITS\n"
TEXT+="🔗 *CI Logs:* <$BUILD_URL|View Build>"

# Send to Slack
curl -X POST -H "Content-type: application/json" \
  --data "{\"text\": \"$TEXT\"}" \
  "$WEBHOOK_URL"
