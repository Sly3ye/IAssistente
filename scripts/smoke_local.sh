#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"
[[ -f .env ]] || cp .env.example .env

flutter pub get
flutter analyze
flutter test

cd "${ROOT_DIR}/proxy-server"
node --check server.mjs

echo "Local smoke checks passed."
