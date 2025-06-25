#!/bin/sh
set -ex

ENABLED_MODULES="brotli headers-more"
NGINX_VERSION=1.28.0
MODSEC3_VERSION=3.0.14
OWASP_VERSION=4-nginx-alpine-202506050606

docker build \
    --build-arg ENABLED_MODULES="${ENABLED_MODULES}" \
    --build-arg NGINX_FROM_IMAGE=nginx:${NGINX_VERSION}-alpine \
    --no-cache --progress=plain --target builder -t krautsalad/nginx-builder \
    https://raw.githubusercontent.com/nginx/docker-nginx/refs/tags/${NGINX_VERSION}/modules/Dockerfile.alpine
docker build \
    --build-arg MODSEC3_VERSION=${MODSEC3_VERSION} \
    --build-arg NGINX_VERSION=${NGINX_VERSION} \
    --build-arg OWASP_VERSION=${OWASP_VERSION} \
    --no-cache --progress=plain -t krautsalad/nginx:latest -f docker/Dockerfile .
docker push krautsalad/nginx:latest

VERSION=$(git describe --tags "$(git rev-list --tags --max-count=1)")

docker tag krautsalad/nginx:latest krautsalad/nginx:${VERSION}
docker push krautsalad/nginx:${VERSION}
