#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"
[[ -f .env ]] || cp .env.example .env

# Keep localhost websocket/protocol traffic out of corporate proxies.
unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
export NO_PROXY="localhost,127.0.0.1,::1"

./scripts/check_runtime_config.sh
./scripts/release_gate.sh --expected-package it.dallacog.mimir --relaxed
flutter pub get
flutter analyze
flutter test

cd "${ROOT_DIR}/proxy-server"
node --check server.mjs

echo "Local smoke checks passed."
