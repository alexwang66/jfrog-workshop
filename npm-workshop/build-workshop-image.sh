#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-jfrog-workshop:node20}"
DOCKERFILE="${DOCKERFILE:-npm-workshop/Dockerfile.npm-jf-git}"
JFROG_CLI_VERSION="${JFROG_CLI_VERSION:-2.72.3}"
OUT_TAR_GZ="${OUT_TAR_GZ:-jfrog-workshop_node20.tar.gz}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not found in PATH. Please run this on a machine with Docker Desktop / docker engine installed." >&2
  exit 127
fi

echo "Building image: ${IMAGE_NAME}"
docker build -f "${DOCKERFILE}" -t "${IMAGE_NAME}" --build-arg "JFROG_CLI_VERSION=${JFROG_CLI_VERSION}" .

echo
echo "Image size:"
docker images "${IMAGE_NAME}"
echo "Bytes:"
docker image inspect "${IMAGE_NAME}" --format '{{.Size}}'

echo
echo "Saving to: ${OUT_TAR_GZ}"
docker save "${IMAGE_NAME}" | gzip > "${OUT_TAR_GZ}"
echo "Done."

