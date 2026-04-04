#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${N8N_BASE_URL:-https://n8n.htech-servidor.space}"
METHOD="${1:-GET}"
PATH_SUFFIX="${2:-/api/v1/workflows}"
BODY_FILE="${3:-}"

if [[ -z "${N8N_API_KEY:-}" ]]; then
  read -rsp "N8N API Key: " N8N_API_KEY
  printf '\n' >&2
fi

curl_args=(
  -sS
  -X "$METHOD"
  "${BASE_URL}${PATH_SUFFIX}"
  -H "X-N8N-API-KEY: ${N8N_API_KEY}"
  -H "Accept: application/json"
)

if [[ -n "$BODY_FILE" ]]; then
  curl_args+=(
    -H "Content-Type: application/json"
    --data-binary "@${BODY_FILE}"
  )
fi

curl "${curl_args[@]}"
