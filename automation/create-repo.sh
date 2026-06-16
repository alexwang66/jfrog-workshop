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

build_vars_lines() {
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
    repo_type = item.get("rclass", "")
    xray_enable = str(item.get("xrayIndex", "false")).lower()
    parts = [
        f"repo-name={student_repo_name(item.get('key', ''))}",
        f"package-type={item.get('packageType', '')}",
        f"repo-type={repo_type}",
        f"repo-layout={item.get('repoLayoutRef', '')}",
        f"xray-enable={xray_enable}",
    ]

    if repo_type == "remote":
        parts.append(f"repo-url={item.get('url', '')}")
    elif repo_type == "virtual":
        parts.append(f"deploy-repo-name={student_repo_name(item.get('defaultDeploymentRepo', ''))}")
        parts.append(f"external-remote-repo-name={student_repo_name(item.get('externalDependenciesRemoteRepo', ''))}")
        repos = ",".join(student_repo_name(repo.strip()) for repo in item.get("repositories", "").split(",") if repo.strip())
        parts.append(f"repos={repos}")

    print(";".join(parts))
PY
}

create_repos() {
  template_file="$1"
  values_file="$2"

  build_vars_lines "$values_file" | while IFS= read -r vars_string; do
    [ -n "$vars_string" ] || continue
    jf rt repo-create "$template_file" --vars "$vars_string"
  done
}

case "$REPO_KIND" in
  all)
    create_repos "$SCRIPT_DIR/local-repo-template.json" "$SCRIPT_DIR/local-repo-values.json"
    create_repos "$SCRIPT_DIR/remote-repo-template.json" "$SCRIPT_DIR/remote-repo-values.json"
    create_repos "$SCRIPT_DIR/virtual-repo-template.json" "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  local)
    create_repos "$SCRIPT_DIR/local-repo-template.json" "$SCRIPT_DIR/local-repo-values.json"
    ;;
  remote)
    create_repos "$SCRIPT_DIR/remote-repo-template.json" "$SCRIPT_DIR/remote-repo-values.json"
    ;;
  virtual)
    create_repos "$SCRIPT_DIR/virtual-repo-template.json" "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  *)
    echo "Usage: $0 <student-id> [all|local|remote|virtual]" >&2
    exit 1
    ;;
esac
