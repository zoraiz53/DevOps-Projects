#!/bin/sh
set -eu

cat >/usr/share/nginx/html/env.js <<EOF
window.__APP_CONFIG__ = {
  API_BASE_URL: "${API_BASE_URL:-http://localhost:8000}",
  COGNITO_REGION: "${COGNITO_REGION:-}",
  COGNITO_USER_POOL_ID: "${COGNITO_USER_POOL_ID:-}",
  COGNITO_APP_CLIENT_ID: "${COGNITO_APP_CLIENT_ID:-}"
};
EOF

exec "$@"
