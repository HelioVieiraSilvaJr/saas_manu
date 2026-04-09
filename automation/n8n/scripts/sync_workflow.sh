#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
API_SCRIPT="${SCRIPT_DIR}/n8n_api.sh"

APPLY_CHANGES=0
ALLOW_ACTIVE=0
METHOD="${N8N_SYNC_METHOD:-PUT}"
WORKFLOW_KEY=""
REMOTE_ID=""
LOCAL_FILE=""

usage() {
  cat <<'EOF'
Uso:
  automation/n8n/scripts/sync_workflow.sh <workflow-key>
  automation/n8n/scripts/sync_workflow.sh --workflow <workflow-key> [--apply --allow-active]
  automation/n8n/scripts/sync_workflow.sh --id <remote-id> --file <local-file> [--apply --allow-active]

Workflows conhecidos:
  main                     whatsapp-sales-agent
  search-products          subworkflow de busca de catalogo
  update-whatsapp-status   subworkflow interno de status do WhatsApp

Opcoes:
  --apply         publica o payload no n8n remoto
  --allow-active  permite publicar mesmo com workflow remoto ativo
  --method        metodo HTTP para update. Padrao: PUT
  --id            ID remoto do workflow no n8n
  --file          arquivo JSON local correspondente
EOF
}

resolve_known_workflow() {
  case "$1" in
    main|principal|whatsapp-sales-agent)
      REMOTE_ID="${REMOTE_ID:-1xc2B25iFU6J8BIs}"
      LOCAL_FILE="${LOCAL_FILE:-${REPO_ROOT}/automation/n8n/workflows/production/entrypoints/whatsapp-sales-agent.json}"
      ;;
    search-products|buscar-produtos)
      REMOTE_ID="${REMOTE_ID:-SIXIOZ0NM0w1Kp1s}"
      LOCAL_FILE="${LOCAL_FILE:-${REPO_ROOT}/automation/n8n/workflows/production/subworkflows/catalog/search-products.json}"
      ;;
    update-whatsapp-status|status|whatsapp-status)
      REMOTE_ID="${REMOTE_ID:-dq34Nu1lmyMdp1rb}"
      LOCAL_FILE="${LOCAL_FILE:-${REPO_ROOT}/automation/n8n/workflows/production/subworkflows/channel/update-whatsapp-status.json}"
      ;;
    "")
      ;;
    *)
      echo "Workflow desconhecido: ${1}" >&2
      echo "Use um dos aliases conhecidos ou informe --id e --file." >&2
      exit 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY_CHANGES=1
      ;;
    --allow-active)
      ALLOW_ACTIVE=1
      ;;
    --method)
      METHOD="$(printf '%s' "${2:-}" | tr '[:lower:]' '[:upper:]')"
      shift
      ;;
    --workflow)
      WORKFLOW_KEY="${2:-}"
      shift
      ;;
    --id)
      REMOTE_ID="${2:-}"
      shift
      ;;
    --file)
      LOCAL_FILE="${2:-}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${WORKFLOW_KEY}" ]]; then
        WORKFLOW_KEY="$1"
      else
        echo "Argumento inesperado: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
  shift
done

resolve_known_workflow "${WORKFLOW_KEY}"

if [[ -z "${REMOTE_ID}" || -z "${LOCAL_FILE}" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -f "${LOCAL_FILE}" ]]; then
  echo "Arquivo local nao encontrado: ${LOCAL_FILE}" >&2
  exit 1
fi

if [[ "${METHOD}" != "PUT" && "${METHOD}" != "PATCH" ]]; then
  echo "Metodo invalido: ${METHOD}. Use PUT ou PATCH." >&2
  exit 1
fi

REMOTE_FILE="$(mktemp -t n8n-remote-workflow)"
REMOTE_NORMALIZED_FILE="$(mktemp -t n8n-remote-normalized)"
PAYLOAD_FILE="$(mktemp -t n8n-workflow-payload)"
RESPONSE_FILE="$(mktemp -t n8n-workflow-response)"

cleanup() {
  rm -f "${REMOTE_FILE}" "${REMOTE_NORMALIZED_FILE}" "${PAYLOAD_FILE}" "${RESPONSE_FILE}"
}

trap cleanup EXIT

"${API_SCRIPT}" GET "/api/v1/workflows/${REMOTE_ID}" > "${REMOTE_FILE}"
jq empty "${REMOTE_FILE}" >/dev/null
jq empty "${LOCAL_FILE}" >/dev/null

jq -n \
  --slurpfile remote "${REMOTE_FILE}" \
  --slurpfile local "${LOCAL_FILE}" \
  '{
    name: ($local[0].name // $remote[0].name),
    nodes: ($local[0].nodes // $remote[0].nodes),
    connections: ($local[0].connections // $remote[0].connections),
    settings: (($local[0].settings // $remote[0].settings // {}) | {
      executionOrder,
      callerPolicy
    } | with_entries(select(.value != null))),
  } | with_entries(select(.value != null))' > "${PAYLOAD_FILE}"

jq -n \
  --slurpfile remote "${REMOTE_FILE}" \
  '{
    name: ($remote[0].name),
    nodes: ($remote[0].nodes),
    connections: ($remote[0].connections),
    settings: (($remote[0].settings // {}) | {
      executionOrder,
      callerPolicy
    } | with_entries(select(.value != null)))
  } | with_entries(select(.value != null))' > "${REMOTE_NORMALIZED_FILE}"

REMOTE_NAME="$(jq -r '.name' "${REMOTE_FILE}")"
LOCAL_NAME="$(jq -r '.name // empty' "${LOCAL_FILE}")"
REMOTE_ACTIVE="$(jq -r '.active' "${REMOTE_FILE}")"
REMOTE_VERSION_ID="$(jq -r '.versionId' "${REMOTE_FILE}")"
REMOTE_NODE_COUNT="$(jq '.nodes | length' "${REMOTE_FILE}")"
LOCAL_NODE_COUNT="$(jq '.nodes | length' "${LOCAL_FILE}")"
PAYLOAD_SHA="$(shasum -a 256 "${PAYLOAD_FILE}" | awk '{print $1}')"
REMOTE_PAYLOAD_SHA="$(shasum -a 256 "${REMOTE_NORMALIZED_FILE}" | awk '{print $1}')"
LOCAL_ONLY_NODES="$(jq -r -n --slurpfile remote "${REMOTE_FILE}" --slurpfile local "${LOCAL_FILE}" '(((($local[0].nodes // []) | map(.name))) - ((($remote[0].nodes // []) | map(.name)))) | if length == 0 then "-" else join(", ") end')"
REMOTE_ONLY_NODES="$(jq -r -n --slurpfile remote "${REMOTE_FILE}" --slurpfile local "${LOCAL_FILE}" '(((($remote[0].nodes // []) | map(.name))) - ((($local[0].nodes // []) | map(.name)))) | if length == 0 then "-" else join(", ") end')"
CONTENT_CHANGED="sim"
if cmp -s "${REMOTE_NORMALIZED_FILE}" "${PAYLOAD_FILE}"; then
  CONTENT_CHANGED="nao"
fi

cat <<EOF
Workflow remoto: ${REMOTE_NAME}
Workflow local:  ${LOCAL_NAME:-<sem name>}
Remote ID:       ${REMOTE_ID}
Metodo update:   ${METHOD}
Ativo remoto:    ${REMOTE_ACTIVE}
Version ID:      ${REMOTE_VERSION_ID}
Nos remoto/local:${REMOTE_NODE_COUNT}/${LOCAL_NODE_COUNT}
Somente local:   ${LOCAL_ONLY_NODES}
Somente remoto:  ${REMOTE_ONLY_NODES}
Mudancas:        ${CONTENT_CHANGED}
SHA remoto:      ${REMOTE_PAYLOAD_SHA}
Payload SHA256:  ${PAYLOAD_SHA}
Arquivo local:   ${LOCAL_FILE}
EOF

if [[ "${APPLY_CHANGES}" -ne 1 ]]; then
  echo
  echo "Dry-run concluido. Nenhuma alteracao foi publicada."
  echo "Use --apply --allow-active para enviar o payload ao n8n remoto."
  exit 0
fi

if [[ "${REMOTE_ACTIVE}" == "true" && "${ALLOW_ACTIVE}" -ne 1 ]]; then
  echo
  echo "Workflow remoto esta ativo. Reexecute com --allow-active para publicar conscientemente." >&2
  exit 1
fi

"${API_SCRIPT}" "${METHOD}" "/api/v1/workflows/${REMOTE_ID}" "${PAYLOAD_FILE}" > "${RESPONSE_FILE}"

jq -r '{
  id,
  name,
  active,
  versionId,
  updatedAt,
  nodeCount: (.nodes | length)
}' "${RESPONSE_FILE}"
