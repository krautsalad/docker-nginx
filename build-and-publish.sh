#!/bin/sh
set -ex

ENABLED_MODULES="brotli headers-more"
NGINX_VERSION=1.28.2
MODSEC3_VERSION=3.0.14
OWASP_VERSION=4-nginx-alpine-202603150103

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VERSION=$(git describe --tags "$(git rev-list --tags --max-count=1)")

BUILD_CONTEXT="${SCRIPT_DIR}/"

docker buildx build \
--build-arg ENABLED_MODULES="${ENABLED_MODULES}" \
--build-arg NGINX_FROM_IMAGE=nginx:${NGINX_VERSION}-alpine \
--no-cache \
--platform linux/amd64,linux/arm64 \
--progress=plain \
--target builder \
-t krautsalad/nginx-build \
https://raw.githubusercontent.com/nginx/docker-nginx/refs/tags/${NGINX_VERSION}/modules/Dockerfile.alpine

docker buildx build \
--build-arg MODSEC3_VERSION=${MODSEC3_VERSION} \
--build-arg NGINX_VERSION=${NGINX_VERSION} \
--build-arg OWASP_VERSION=${OWASP_VERSION} \
--no-cache \
--platform linux/amd64,linux/arm64 \
--progress=plain \
-f "${SCRIPT_DIR}/docker/Dockerfile" \
-t krautsalad/nginx:latest \
-t krautsalad/nginx:${VERSION} \
"${BUILD_CONTEXT}"

until docker buildx build \
    --build-arg MODSEC3_VERSION=${MODSEC3_VERSION} \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --build-arg OWASP_VERSION=${OWASP_VERSION} \
    --platform linux/amd64,linux/arm64 \
    --push \
    -f "${SCRIPT_DIR}/docker/Dockerfile" \
    -t krautsalad/nginx:latest \
    -t krautsalad/nginx:${VERSION} \
    "${BUILD_CONTEXT}"; do
    echo "Retrying push for krautsalad/nginx" ; sleep 2
done
