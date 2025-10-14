#!/bin/bash
set +e  # Continue even if a command fails

# --- INPUTS -----------------------------------------------------------------
WEBHOOK_PREVIEW="${ZOHO_WEBHOOK_PREVIEW}"
WEBHOOK_STAGE="${ZOHO_WEBHOOK_STAGE}"
WEBHOOK_LIVE="${ZOHO_WEBHOOK_LIVE}"

MESSAGE="$1"        # e.g. "Deployment"
ENVIRONMENT="$2"    # preview/stage/live
STATUS="$3"         # success/failure
SERVICE="$4"        # admin/server/website
PREVIEW_URL="$5"
STAGE_URL="$6"
LIVE_URL="$7"

# --- STATUS ICONS ------------------------------------------------------------
if [[ "$STATUS" == "success" ]]; then
  STATUS_ICON="✅"
  STATUS_TEXT="SUCCESS"
  THEME="success"
else
  STATUS_ICON="❌"
  STATUS_TEXT="FAILED"
  THEME="danger"
fi

# --- ENVIRONMENT SELECTION ---------------------------------------------------
case "$ENVIRONMENT" in
  preview)
    WEBHOOK_URL="$WEBHOOK_PREVIEW"
    ENV_DISPLAY="Preview"
    SERVICE_URL="${PREVIEW_URL:-https://${SERVICE}.preview.v1.irai.yoga}"
    ;;
  stage)
    WEBHOOK_URL="$WEBHOOK_STAGE"
    ENV_DISPLAY="Stage"
    SERVICE_URL="${STAGE_URL:-https://${SERVICE}.stage.v1.irai.yoga}"
    ;;
  live)
    WEBHOOK_URL="$WEBHOOK_LIVE"
    ENV_DISPLAY="Live"
    SERVICE_URL="${LIVE_URL:-https://${SERVICE}.live.v1.irai.yoga}"
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# --- COMPONENT LABEL ---------------------------------------------------------
case "$SERVICE" in
  admin) COMPONENT="Admin Portal" ;;
  server) COMPONENT="Backend Server" ;;
  website) COMPONENT="Website" ;;
  *) COMPONENT="$SERVICE" ;;
esac

# --- GIT INFO ---------------------------------------------------------------
AUTHOR=$(git log -1 --pretty=format:'%an' 2>/dev/null || echo "${GITHUB_ACTOR:-unknown}")
COMMIT_MESSAGE=$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "no message")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "${GITHUB_SHA:0:7}")
SHORT_COMMIT="(${COMMIT_SHA}) ${COMMIT_MESSAGE}"

# --- TIMESTAMP --------------------------------------------------------------
CURRENT_TIME=$(date '+%I:%M %p')
CURRENT_DATE=$(date '+%d %b, %Y')
TIMESTAMP="${CURRENT_DATE}. ${CURRENT_TIME}"

# --- CARD PAYLOAD -----------------------------------------------------------
PAYLOAD=$(jq -n \
  --arg theme "$THEME" \
  --arg title "$STATUS_ICON Deployment $STATUS_TEXT" \
  --arg env "$ENV_DISPLAY" \
  --arg component "$COMPONENT" \
  --arg status "$STATUS_TEXT" \
  --arg author "@$AUTHOR" \
  --arg timestamp "$TIMESTAMP" \
  --arg url "$SERVICE_URL" \
  --arg message "$SHORT_COMMIT" \
  '{
    card: {
      title: $title,
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
      ]
    }
  }'
)

# --- SEND CARD --------------------------------------------------------------
echo "📤 Sending Zoho Cliq notification for $ENV_DISPLAY..."
RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2 | tr -d '[:space:]')

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✅ Notification sent successfully to Zoho Cliq"
else
  echo "❌ Failed to send notification (HTTP $HTTP_STATUS)"
  echo "Response: $RESPONSE"
fi

exit 0
