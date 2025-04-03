# We are using the official Nginx image as the builder image to build additional modules.
# We then use the official OWASP ModSecurity Core Rule Set image as the base image and add the compiled modules to it.
# Ensure both images use the same version of Alpine and Nginx to avoid compatibility issues!
# see https://github.com/nginxinc/docker-nginx/tree/master/modules
# see https://github.com/coreruleset/modsecurity-crs-docker

# It may also be possible to compile ModSecurity from source inside the builder image.
# see https://github.com/andrewnk/docker-alpine-nginx-modsec/blob/main/Dockerfile

ARG NGINX_VERSION=1.26.3
ARG MODSEC3_VERSION=3.0.14
ARG OWASP_VERSION=4-nginx-alpine-202503230103

FROM nginx:${NGINX_VERSION}-alpine AS builder

ARG ENABLED_MODULES="brotli headers-more"

SHELL ["/bin/ash", "-exo", "pipefail", "-c"]

RUN apk update \
    && apk add --no-cache linux-headers openssl-dev pcre2-dev zlib-dev openssl abuild \
               musl-dev libxslt libxml2-utils make mercurial gcc unzip git \
               xz g++ coreutils curl \
    # allow abuild as a root user \
    && printf "#!/bin/sh\\nSETFATTR=true /usr/bin/abuild -F \"\$@\"\\n" > /usr/local/bin/abuild \
    && chmod +x /usr/local/bin/abuild \
    && git clone -b ${NGINX_VERSION}-${PKG_RELEASE} https://github.com/nginx/pkg-oss/ \
    && cd pkg-oss \
    && mkdir /tmp/packages \
    && for module in $ENABLED_MODULES; do \
        echo "Building $module for nginx-$NGINX_VERSION"; \
        if [ -d /modules/$module ]; then \
            echo "Building $module from user-supplied sources"; \
            # check if module sources file is there and not empty
            if [ ! -s /modules/$module/source ]; then \
                echo "No source file for $module in modules/$module/source, exiting"; \
                exit 1; \
            fi; \
            # some modules require build dependencies
            if [ -f /modules/$module/build-deps ]; then \
                echo "Installing $module build dependencies"; \
                apk add --no-cache $(cat /modules/$module/build-deps | xargs); \
            fi; \
            # if a module has a build dependency that is not in a distro, provide a
            # shell script to fetch/build/install those
            # note that shared libraries produced as a result of this script will
            # not be copied from the builder image to the main one so build static
            if [ -x /modules/$module/prebuild ]; then \
                echo "Running prebuild script for $module"; \
                /modules/$module/prebuild; \
            fi; \
            /pkg-oss/build_module.sh -v $NGINX_VERSION -f -y -o /tmp/packages -n $module $(cat /modules/$module/source); \
            BUILT_MODULES="$BUILT_MODULES $(echo $module | tr '[A-Z]' '[a-z]' | tr -d '[/_\-\.\t ]')"; \
        elif make -C /pkg-oss/alpine list | grep -E "^$module\s+\d+" > /dev/null; then \
            echo "Building $module from pkg-oss sources"; \
            cd /pkg-oss/alpine; \
            make abuild-module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
            apk add --no-cache $(. ./abuild-module-$module/APKBUILD; echo $makedepends;); \
            make module-$module BASE_VERSION=$NGINX_VERSION NGINX_VERSION=$NGINX_VERSION; \
            find ~/packages -type f -name "*.apk" -exec mv -v {} /tmp/packages/ \;; \
            BUILT_MODULES="$BUILT_MODULES $module"; \
        else \
            echo "Don't know how to build $module module, exiting"; \
            exit 1; \
        fi; \
    done \
    && echo "BUILT_MODULES=\"$BUILT_MODULES\"" > /tmp/packages/modules.env

FROM owasp/modsecurity-crs:${OWASP_VERSION}

ARG MODSEC3_VERSION
ENV MODSEC3_VERSION=${MODSEC3_VERSION}

HEALTHCHECK NONE
USER root

RUN --mount=type=bind,target=/tmp/packages/,source=/tmp/packages/,from=builder \
    . /tmp/packages/modules.env && \
    for module in $BUILT_MODULES; do \
        apk add --no-cache --allow-untrusted /tmp/packages/nginx-module-${module}-${NGINX_VERSION}*.apk; \
    done

RUN apk update && \
    apk add --no-cache tzdata && \
    openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/ssl/private/snakeoil.key -out /etc/ssl/private/snakeoil.pem -days 36500 -subj "/CN=localhost" && \
    sed -i 's/SecDefaultAction "phase:1,log,auditlog,pass"/SecDefaultAction "phase:1,nolog,auditlog,pass"/' /opt/owasp-crs/crs-setup.conf && \
    sed -i 's/SecDefaultAction "phase:2,log,auditlog,pass"/SecDefaultAction "phase:2,nolog,auditlog,pass"/' /opt/owasp-crs/crs-setup.conf && \
    rm -rf /docker-entrypoint.d /etc/nginx/* /root/.cache /tmp/* /var/cache/apk/* /var/tmp/*

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY nginx /etc/nginx

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
