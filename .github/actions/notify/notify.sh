#!/bin/bash
set -e

# --- INPUTS -----------------------------------------------------------------
WEBHOOK_PREVIEW="${ZOHO_WEBHOOK_PREVIEW}"
WEBHOOK_STAGE="${ZOHO_WEBHOOK_STAGE}"
WEBHOOK_LIVE="${ZOHO_WEBHOOK_LIVE}"

MESSAGE="$1"         # e.g. "Deployment"
ENVIRONMENT="$2"      # preview/stage/live
STATUS="$3"           # success/failure
SERVICE="$4"          # admin/server/website
PREVIEW_URL="$5"      # Dynamic preview URL
STAGE_URL="$6"        # Dynamic stage URL  
LIVE_URL="$7"         # Dynamic live URL

# --- STATUS ---------------------------------------------------------------
if [[ "$STATUS" == "success" ]]; then
  STATUS_ICON="✅"
  STATUS_TEXT="SUCCESS"
  THEME="success"
else
  STATUS_ICON="❌"
  STATUS_TEXT="FAILED"
  THEME="danger"
fi

# --- ENVIRONMENT SELECTION --------------------------------------------------
case "$ENVIRONMENT" in
  preview)
    WEBHOOK_URL="$WEBHOOK_PREVIEW"
    ENV_DISPLAY="Preview"
    # Use dynamic preview URL if provided, otherwise fallback to default
    if [[ -n "$PREVIEW_URL" && "$PREVIEW_URL" != "null" ]]; then
      SERVICE_URL="$PREVIEW_URL"
    else
      SERVICE_URL="https://admin.preview.v1.irai.yoga"
    fi
    ;;
  stage)
    WEBHOOK_URL="$WEBHOOK_STAGE"
    ENV_DISPLAY="Stage"
    # Use dynamic stage URL if provided, otherwise fallback to default
    if [[ -n "$STAGE_URL" && "$STAGE_URL" != "null" ]]; then
      SERVICE_URL="$STAGE_URL"
    else
      SERVICE_URL="https://admin.stage.v1.irai.yoga"
    fi
    ;;
  live)
    WEBHOOK_URL="$WEBHOOK_LIVE"
    ENV_DISPLAY="Live"
    # Use dynamic live URL if provided, otherwise fallback to default
    if [[ -n "$LIVE_URL" && "$LIVE_URL" != "null" ]]; then
      SERVICE_URL="$LIVE_URL"
    else
      SERVICE_URL="https://admin.live.v1.irai.yoga"
    fi
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# --- COMPONENT MAPPING ------------------------------------------------------
case "$SERVICE" in
  admin)
    COMPONENT="Admin Portal"
    ;;
  server)
    COMPONENT="Backend Server"
    ;;
  website)
    COMPONENT="Website"
    ;;
  *)
    COMPONENT="$SERVICE"
    ;;
esac

# --- GIT INFO ---------------------------------------------------------------
AUTHOR=$(git log -1 --pretty=format:'%an' 2>/dev/null || echo "unknown")
COMMIT_MESSAGE=$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "no message")
COMMIT_BRANCH=$(echo "${GITHUB_REF_NAME:-unknown}")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Format commit message for display (short SHA + message)
SHORT_COMMIT_DISPLAY="(${COMMIT_SHA}) ${COMMIT_MESSAGE}"

# --- TIMESTAMP --------------------------------------------------------------
CURRENT_TIME=$(date '+%I:%M %p')
CURRENT_DATE=$(date '+%d %b, %Y')
TIMESTAMP="${CURRENT_DATE}. ${CURRENT_TIME}"

# --- GITHUB ACTIONS RUN LINK ------------------------------------------------
RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# --- CARD PAYLOAD (NEW STRUCTURE) -------------------------------------------
PAYLOAD=$(jq -n \
  --arg env "$ENV_DISPLAY" \
  --arg component "$COMPONENT" \
  --arg status "$STATUS_ICON $STATUS_TEXT" \
  --arg author "@$AUTHOR" \
  --arg timestamp "$TIMESTAMP" \
  --arg url "$SERVICE_URL" \
  --arg message "$SHORT_COMMIT_DISPLAY" \
  --arg run_url "$RUN_URL" \
  --arg theme "$THEME" \
  '{
    card: {
      title: "Deployment Notification",
      theme: $theme,
      thumbnail: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
      sections: [
        {
          fields: [
            { label: "Environment", value: $env, type: "text" },
            { label: "Component", value: $component, type: "text" },
            { label: "Status", value: $status, type: "text" },
            { label: "Author", value: $author, type: "text" },
            { label: "Timestamp", value: $timestamp, type: "text" },
            { label: "URL", value: $url, type: "link" },
            { label: "Message", value: $message, type: "text" }
          ]
        }
      ],
      buttons: [
        {
          label: "View Deployment Details",
          type: "link",
          value: $run_url
        }
      ]
    }
  }'
)

# --- SEND TO ZOHO CLIQ ------------------------------------------------------
echo "📤 Sending Zoho Cliq notification for $ENV_DISPLAY environment..."
echo "🔗 Service URL: $SERVICE_URL"
echo "👤 Author: $AUTHOR"
echo "💬 Message: $SHORT_COMMIT_DISPLAY"

RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✅ Notification sent successfully to Zoho Cliq"
  echo "📊 Environment: $ENV_DISPLAY"
  echo "🔄 Status: $STATUS_TEXT"
  echo "🌐 URL: $SERVICE_URL"
else
  echo "❌ Failed to send notification (HTTP $HTTP_STATUS)"
  echo "Response: $RESPONSE"
  exit 1
fi
