#!/bin/bash
set -e

WEBHOOK_URL="$1"
MESSAGE="$2"
ENVIRONMENT="$3"
STATUS="$4"
SERVICE="$5"

# Define theme and emoji
if [[ "$STATUS" == "success" ]]; then
  ICON="✅"
  THEME="success"
else
  ICON="❌"
  THEME="danger"
fi

# Set environment URLs
if [[ "$ENVIRONMENT" == "preview" ]]; then
  ADMIN_URL="https://admin.preview.v1.irai.yoga"
  ENV_DISPLAY="Preview 🚀"
elif [[ "$ENVIRONMENT" == "stage" ]]; then
  ADMIN_URL="https://admin.stage.v1.irai.yoga"
  ENV_DISPLAY="Stage 🔧"
else
  ADMIN_URL="https://admin.v1.irai.yoga"
  ENV_DISPLAY="Live 🎯"
fi

# Commit details
AUTHOR=$(git log -1 --pretty=format:'%an' || echo "unknown")
COMMIT_MESSAGE=$(git log -1 --pretty=format:'%s' || echo "no message")
COMMIT_SHA=$(git rev-parse --short HEAD || echo "unknown")
BRANCH_NAME="${GITHUB_REF_NAME:-unknown}"

# Duration (GitHub provides GITHUB_RUN_STARTED_AT)
if [ -n "$GITHUB_RUN_STARTED_AT" ]; then
  START_TIME=$(date -d "$GITHUB_RUN_STARTED_AT" +%s)
  END_TIME=$(date +%s)
  DURATION_SEC=$((END_TIME - START_TIME))
  DURATION_MIN=$((DURATION_SEC / 60))
  DURATION_REMAIN=$((DURATION_SEC % 60))
  DURATION="${DURATION_MIN}m ${DURATION_REMAIN}s"
else
  DURATION="N/A"
fi

# Create Zoho Cliq message JSON
PAYLOAD=$(jq -n \
  --arg text "$ICON **${MESSAGE}**\n🤖 GitHub Actions | $ENV_DISPLAY\n\n🧑‍💻 **Author:** $AUTHOR\n📝 **Commit:** $BRANCH_NAME – \"$COMMIT_MESSAGE\"\n🔢 **SHA:** $COMMIT_SHA\n⏱️ **Duration:** $DURATION\n\n🌐 **Admin:** $ADMIN_URL\n🕒 **Time:** $(date '+%I:%M %p')\n📅 **Date:** $(date '+%b %d, %Y')" \
  --arg title "🚀 Deployment Notification - $ENV_DISPLAY" \
  --arg theme "$THEME" \
  --arg thumb "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png" \
  '{
    text: $text,
    card: {
      title: $title,
      theme: $theme,
      thumbnail: $thumb
    }
  }'
)

# Send message to Zoho Cliq
curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -o /dev/null -w "📨 Notification sent to Zoho Cliq for $ENV_DISPLAY ($STATUS)\n"
