#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Config file missing: ${ENV_FILE}"
  exit 1
fi

required_keys=(
  "APP_ENV"
  "LLM_PROXY_URL"
  "LLM_PROXY_PROVIDER"
)

missing=0
for key in "${required_keys[@]}"; do
  if ! grep -q "^${key}=" "${ENV_FILE}"; then
    echo "Missing key in .env: ${key}"
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  exit 1
fi

echo "Runtime config check passed."
