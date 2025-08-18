#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$ROOT_DIR/.venv"
CONFIG="$ROOT_DIR/mkdocs.local.yml"

if [ ! -d "$VENV" ]; then
  echo "Virtualenv not found at $VENV"
  echo "Create it with: uv venv  (or python -m venv .venv)"
  exit 1
fi

echo "Activating virtualenv: $VENV"
# shellcheck disable=SC1090
source "$VENV/bin/activate"

if [ ! -f "$CONFIG" ]; then
  echo "Local mkdocs config not found: $CONFIG"
  exit 1
fi

echo "Serving docs using $CONFIG"
# Use the venv mkdocs executable explicitly
# Old invocation used -f which some mkdocs builds do not accept. Use the CLI form:
#   mkdocs serve --config-file <config> --strict
"$VENV/bin/mkdocs" serve --config-file "$CONFIG" --strict
