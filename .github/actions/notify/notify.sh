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

# --- STATUS ---------------------------------------------------------------
if [[ "$STATUS" == "success" ]]; then
  STATUS_ICON="✅"
  STATUS_TEXT="DEPLOYMENT SUCCESS"
  THEME="success"
else
  STATUS_ICON="❌"
  STATUS_TEXT="DEPLOYMENT FAILED"
  THEME="danger"
fi

# --- ENVIRONMENT SELECTION --------------------------------------------------
case "$ENVIRONMENT" in
  preview)
    WEBHOOK_URL="$WEBHOOK_PREVIEW"
    ENV_DISPLAY="Preview 🚀"
    ;;
  stage)
    WEBHOOK_URL="$WEBHOOK_STAGE"
    ENV_DISPLAY="Stage 🔧"
    ;;
  live)
    WEBHOOK_URL="$WEBHOOK_LIVE"
    ENV_DISPLAY="Live 🎯"
    ;;
  *)
    echo "❌ Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

# --- SERVICE URL ------------------------------------------------------------
case "$SERVICE" in
  admin)
    case "$ENVIRONMENT" in
      preview) SERVICE_URL="https://admin.preview.v1.irai.yoga" ;;
      stage) SERVICE_URL="https://admin.stage.v1.irai.yoga" ;;
      live) SERVICE_URL="https://admin.live.v1.irai.yoga" ;;
    esac
    ;;
  server)
    case "$ENVIRONMENT" in
      preview) SERVICE_URL="https://server.preview.v1.irai.yoga" ;;
      stage) SERVICE_URL="https://server.stage.v1.irai.yoga" ;;
      live) SERVICE_URL="https://server.live.v1.irai.yoga" ;;
    esac
    ;;
  website)
    case "$ENVIRONMENT" in
      preview) SERVICE_URL="https://website.preview.v1.irai.yoga" ;;
      stage) SERVICE_URL="https://website.stage.v1.irai.yoga" ;;
      live) SERVICE_URL="https://irai.yoga" ;;
    esac
    ;;
  *)
    echo "❌ Unknown service: $SERVICE"
    exit 1
    ;;
esac

# --- GIT INFO ---------------------------------------------------------------
AUTHOR=$(git log -1 --pretty=format:'%an' 2>/dev/null || echo "unknown")
COMMIT_MESSAGE=$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "no message")
COMMIT_BRANCH=$(echo "${GITHUB_REF_NAME:-unknown}")
COMMIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# --- DURATION ---------------------------------------------------------------
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

# --- TIME & DATE ------------------------------------------------------------
CURRENT_TIME=$(date '+%I:%M %p')
CURRENT_DATE=$(date '+%b %d, %Y')

# --- GITHUB ACTIONS RUN LINK ------------------------------------------------
RUN_URL="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# --- CARD PAYLOAD -----------------------------------------------------------
PAYLOAD=$(jq -n \
  --arg title "$STATUS_ICON $STATUS_TEXT" \
  --arg env "$ENV_DISPLAY" \
  --arg author "$AUTHOR" \
  --arg commit "$COMMIT_BRANCH – $COMMIT_MESSAGE" \
  --arg sha "$COMMIT_SHA" \
  --arg duration "$DURATION" \
  --arg service "$SERVICE_URL" \
  --arg time "$CURRENT_TIME" \
  --arg date "$CURRENT_DATE" \
  --arg run_url "$RUN_URL" \
  --arg theme "$THEME" \
  '{
    card: {
      title: $title,
      theme: $theme,
      thumbnail: "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
      sections: [
        {
          title: $env,
          subtitle: "GitHub Actions Deployment Notification"
        },
        {
          fields: [
            { label: "Author", value: $author, type: "text" },
            { label: "Commit", value: $commit, type: "text" },
            { label: "SHA", value: $sha, type: "text" },
            { label: "Duration", value: $duration, type: "text" },
            { label: "Service URL", value: $service, type: "link" },
            { label: "Time", value: $time, type: "text" },
            { label: "Date", value: $date, type: "text" }
          ]
        }
      ],
      buttons: [
        {
          label: "View Run on GitHub",
          type: "link",
          value: $run_url
        }
      ]
    }
  }'
)

# --- SEND TO ZOHO CLIQ ------------------------------------------------------
echo "📤 Sending Zoho Cliq card to $ENV_DISPLAY..."

RESPONSE=$(curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  -w "\nHTTP_STATUS:%{http_code}")

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d':' -f2)

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "✅ Notification card sent successfully to Zoho Cliq for $ENV_DISPLAY ($SERVICE - $STATUS)"
else
  echo "❌ Failed to send card notification (HTTP $HTTP_STATUS)"
  echo "$RESPONSE"
fi
