#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Config file missing: ${ENV_FILE}"
  exit 1
fi

if ! grep -q "^APP_ENV=" "${ENV_FILE}"; then
  echo "Missing key in .env: APP_ENV"
  exit 1
fi

app_env="$(grep '^APP_ENV=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | tr '[:upper:]' '[:lower:]' | xargs)"
proxy_url="$(grep '^LLM_PROXY_URL=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | xargs || true)"
proxy_provider="$(grep '^LLM_PROXY_PROVIDER=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | xargs || true)"

openai_key="$(grep '^OPENAI_API_KEY=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | xargs || true)"
anthropic_key="$(grep '^ANTHROPIC_API_KEY=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | xargs || true)"
gemini_key="$(grep '^GEMINI_API_KEY=' "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- | xargs || true)"

has_proxy=0
if [[ -n "${proxy_url}" ]]; then
  has_proxy=1
  if [[ -z "${proxy_provider}" ]]; then
    echo "LLM_PROXY_URL is set but LLM_PROXY_PROVIDER is empty."
    exit 1
  fi
fi

has_direct=0
if [[ -n "${openai_key}" || -n "${anthropic_key}" || -n "${gemini_key}" ]]; then
  has_direct=1
fi

if [[ "${has_proxy}" -eq 0 && "${has_direct}" -eq 0 ]]; then
  if [[ "${app_env}" == "production" ]]; then
    echo "Missing production LLM config: set LLM_PROXY_URL or at least one direct provider API key."
    exit 1
  fi
  echo "Warning: no remote LLM config found. Development can still run with local Ollama."
fi

echo "Runtime config check passed for APP_ENV=${app_env}."
