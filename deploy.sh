#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --skip-build)
      SKIP_BUILD=true
      ;;
    *)
      echo "Uso: ./deploy.sh [--skip-build]"
      exit 1
      ;;
  esac
done

if [ "$SKIP_BUILD" = false ]; then
  echo "==> Buildando Flutter Web..."
  flutter build web
fi

echo "==> Publicando no Firebase Hosting..."
firebase deploy --only hosting

echo "==> Deploy concluido."
echo "Hosting URL: https://saas-manu-project.web.app"
