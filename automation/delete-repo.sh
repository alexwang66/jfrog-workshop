#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
STUDENT_ID="${1:-${STUDENT_ID:-}}"
REPO_KIND="${2:-all}"

normalize_student_id() {
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    ""|*[!a-z0-9-]*)
      echo "Invalid student id: $1. Use 3-20 lowercase letters, numbers, and hyphens only. Examples: alex, mary-chen, john2." >&2
      exit 1
      ;;
  esac

  length="$(printf '%s' "$value" | wc -c | tr -d ' ')"
  if [ "$length" -lt 3 ] || [ "$length" -gt 20 ] || ! printf '%s' "$value" | grep -Eq '^[a-z0-9].*[a-z0-9]$'; then
    echo "Invalid student id: $1. Use 3-20 lowercase letters, numbers, and hyphens only. Examples: alex, mary-chen, john2." >&2
    exit 1
  fi

  printf '%s' "$value"
}

if [ -z "$STUDENT_ID" ]; then
  echo "Usage: $0 <student-id> [all|local|remote|virtual]" >&2
  echo "Example: $0 alex all" >&2
  exit 1
fi

STUDENT_ID="$(normalize_student_id "$STUDENT_ID")"

build_key_lines() {
  python3 - "$1" "$STUDENT_ID" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

prefix = sys.argv[2]

def student_repo_name(key):
    base = key
    if base.startswith("workshop-"):
        base = base[len("workshop-"):]
    return f"{prefix}-{base}"

for item in data:
    print(student_repo_name(item.get("key", "")))
PY
}

delete_repos() {
  values_file="$1"

  build_key_lines "$values_file" | while IFS= read -r repo_key; do
    [ -n "$repo_key" ] || continue
    jf rt repo-delete "$repo_key" --quiet
  done
}

case "$REPO_KIND" in
  all)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    ;;
  local)
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    ;;
  remote)
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    ;;
  virtual)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  *)
    echo "Usage: $0 <student-id> [all|local|remote|virtual]" >&2
    exit 1
    ;;
esac
