#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPECTED_PACKAGE="it.dallacog.mimir"
RELAXED=0
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-package)
      EXPECTED_PACKAGE="${2:-}"
      shift 2
      ;;
    --relaxed)
      RELAXED=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

trim() {
  echo "$1" | xargs
}

env_val() {
  local key="$1"
  local val
  val="$(grep "^${key}=" "${ENV_FILE}" | tail -n 1 | cut -d '=' -f2- || true)"
  trim "${val}"
}

GRADLE_FILE="${ROOT_DIR}/android/app/build.gradle.kts"
PUBSPEC_FILE="${ROOT_DIR}/pubspec.yaml"
GOOGLE_SERVICES_FILE="${ROOT_DIR}/android/app/google-services.json"

[[ -f "${GRADLE_FILE}" ]] || fail "Missing file: ${GRADLE_FILE}"
[[ -f "${PUBSPEC_FILE}" ]] || fail "Missing file: ${PUBSPEC_FILE}"
[[ -f "${GOOGLE_SERVICES_FILE}" ]] || fail "Missing file: ${GOOGLE_SERVICES_FILE}"

namespace="$(grep -E '^\s*namespace\s*=' "${GRADLE_FILE}" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')"
application_id="$(grep -E '^\s*applicationId\s*=' "${GRADLE_FILE}" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')"

[[ -n "${namespace}" ]] || fail "Cannot parse namespace from android/app/build.gradle.kts"
[[ -n "${application_id}" ]] || fail "Cannot parse applicationId from android/app/build.gradle.kts"
[[ "${namespace}" == "${EXPECTED_PACKAGE}" ]] || fail "namespace mismatch: expected '${EXPECTED_PACKAGE}', found '${namespace}'"
[[ "${application_id}" == "${EXPECTED_PACKAGE}" ]] || fail "applicationId mismatch: expected '${EXPECTED_PACKAGE}', found '${application_id}'"

version_name="$(grep '^version:' "${PUBSPEC_FILE}" | head -n 1 | awk '{print $2}')"
[[ "${version_name}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] || fail "Invalid or missing version in pubspec.yaml. Expected format x.y.z+build."

if [[ "${RELAXED}" -eq 0 ]]; then
  [[ -f "${ENV_FILE}" ]] || fail "Missing file: ${ENV_FILE}"

  app_env="$(env_val APP_ENV | tr '[:upper:]' '[:lower:]')"
  dev_bypass_auth="$(env_val DEV_BYPASS_AUTH | tr '[:upper:]' '[:lower:]')"
  allow_client_side_llm_in_prod="$(env_val ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION | tr '[:upper:]' '[:lower:]')"
  proxy_url="$(env_val LLM_PROXY_URL)"
  proxy_provider="$(env_val LLM_PROXY_PROVIDER)"
  proxy_auth_token="$(env_val LLM_PROXY_AUTH_TOKEN)"
  openai_key="$(env_val OPENAI_API_KEY)"
  anthropic_key="$(env_val ANTHROPIC_API_KEY)"
  gemini_key="$(env_val GEMINI_API_KEY)"

  [[ "${app_env}" == "production" ]] || fail "APP_ENV must be production for release. Current: '${app_env}'"
  [[ "${dev_bypass_auth}" == "false" ]] || fail "DEV_BYPASS_AUTH must be false for release. Current: '${dev_bypass_auth}'"
  [[ "${allow_client_side_llm_in_prod}" == "false" ]] || fail "ALLOW_CLIENT_SIDE_LLM_IN_PRODUCTION must be false for release. Current: '${allow_client_side_llm_in_prod}'"
  [[ -n "${proxy_url}" ]] || fail "LLM_PROXY_URL is required for release."
  [[ -n "${proxy_provider}" ]] || fail "LLM_PROXY_PROVIDER is required when LLM_PROXY_URL is set."
  [[ "${proxy_url}" =~ ^https:// ]] || fail "LLM_PROXY_URL must use https:// in release. Current: '${proxy_url}'"

  if [[ "${proxy_url}" =~ localhost|127\.0\.0\.1|0\.0\.0\.0|10\.0\.2\.2 ]]; then
    fail "LLM_PROXY_URL cannot point to local host in release. Current: '${proxy_url}'"
  fi

  [[ -z "${openai_key}" ]] || fail "OPENAI_API_KEY must be empty in client .env for release."
  [[ -z "${anthropic_key}" ]] || fail "ANTHROPIC_API_KEY must be empty in client .env for release."
  [[ -z "${gemini_key}" ]] || fail "GEMINI_API_KEY must be empty in client .env for release."

  if [[ -z "${proxy_auth_token}" ]]; then
    warn "LLM_PROXY_AUTH_TOKEN is empty. Keep it empty only if your proxy does not require bearer auth."
  fi

  if [[ ! -f "${ROOT_DIR}/keystore.properties" && ! -f "${ROOT_DIR}/android/keystore.properties" ]]; then
    fail "Missing keystore.properties. Create it from keystore.properties.example (root or android folder)."
  fi
fi

echo "Release gate passed. Package=${EXPECTED_PACKAGE} Version=${version_name} Relaxed=${RELAXED}"
