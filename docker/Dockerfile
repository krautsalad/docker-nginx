# We are using the official Nginx image as the builder image to build additional modules.
# We then use the official OWASP ModSecurity Core Rule Set image as the base image and add the compiled modules to it.
# Ensure both images use the same version of Alpine and Nginx to avoid compatibility issues!
# see https://github.com/nginxinc/docker-nginx/tree/master/modules
# see https://github.com/coreruleset/modsecurity-crs-docker

ARG NGINX_VERSION
ARG MODSEC3_VERSION
ARG OWASP_VERSION

FROM krautsalad/nginx-builder AS builder

FROM owasp/modsecurity-crs:${OWASP_VERSION:-latest}

ARG MODSEC3_VERSION
ENV MODSEC3_VERSION=${MODSEC3_VERSION}

HEALTHCHECK NONE
USER root

RUN --mount=type=bind,target=/tmp/packages/,source=/tmp/packages/,from=builder . /tmp/packages/modules.env && \
    for module in $BUILT_MODULES; do \
        apk add --no-cache --allow-untrusted /tmp/packages/nginx-module-${module}-${NGINX_VERSION}*.apk; \
    done

RUN apk update && \
    apk add --no-cache tzdata && \
    openssl req -x509 -newkey rsa:4096 -nodes -keyout /etc/ssl/private/snakeoil.key -out /etc/ssl/private/snakeoil.pem -days 36500 -subj "/CN=localhost" && \
    sed -i 's/SecDefaultAction "phase:1,log,auditlog,pass"/SecDefaultAction "phase:1,nolog,auditlog,pass"/' /opt/owasp-crs/crs-setup.conf && \
    sed -i 's/SecDefaultAction "phase:2,log,auditlog,pass"/SecDefaultAction "phase:2,nolog,auditlog,pass"/' /opt/owasp-crs/crs-setup.conf && \
    rm -rf /docker-entrypoint.d /etc/nginx/* /root/.cache /tmp/* /var/cache/apk/* /var/tmp/*

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY nginx /etc/nginx

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
