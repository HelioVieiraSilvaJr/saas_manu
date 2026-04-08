#!/usr/bin/env bash

set -euo pipefail

BASE_URL="${N8N_BASE_URL:-https://n8n.htech-servidor.space}"
METHOD="${1:-GET}"
PATH_SUFFIX="${2:-/api/v1/workflows}"
BODY_FILE="${3:-}"
KEYCHAIN_SERVICE="${N8N_KEYCHAIN_SERVICE:-saas_manu.n8n_api_key}"

read_n8n_api_key() {
  if [[ -n "${N8N_API_KEY:-}" ]]; then
    printf '%s' "${N8N_API_KEY}"
    return 0
  fi

  if command -v security >/dev/null 2>&1; then
    local keychain_value=""
    if keychain_value="$(security find-generic-password -w -s "${KEYCHAIN_SERVICE}" 2>/dev/null)"; then
      printf '%s' "${keychain_value}"
      return 0
    fi
  fi

  return 1
}

if ! N8N_API_KEY="$(read_n8n_api_key)"; then
  read -rsp "N8N API Key: " N8N_API_KEY
  printf '\n' >&2
fi

export N8N_API_KEY

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
