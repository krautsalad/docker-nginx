#!/bin/sh
set -e
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so;
[ -n "$DEFAULT_DOMAIN" ] && sed -i 's|ssl_certificate /etc/ssl/private/snakeoil.pem;|ssl_certificate /etc/nginx/ssl/'"$DEFAULT_DOMAIN"'.pem;|' /etc/nginx/sites-default/no-default.conf
[ -n "$DEFAULT_DOMAIN" ] && sed -i 's|ssl_certificate_key /etc/ssl/private/snakeoil.key;|ssl_certificate_key /etc/nginx/ssl/'"$DEFAULT_DOMAIN"'.key;|' /etc/nginx/sites-default/no-default.conf
[ "$DISABLE_IPV6" = "true" ] && sed -i 's/listen \[\:\:\]:443/listen 443/g' /etc/nginx/sites-default/no-default.conf
[ "$DISABLE_IPV6" = "true" ] && sed -i 's/listen \[\:\:\]:80/listen 80/g' /etc/nginx/sites-default/no-default.conf
[ -n "$TZ" ] && [ -f /usr/share/zoneinfo/"$TZ" ] && { cp /usr/share/zoneinfo/"$TZ" /etc/localtime; echo "$TZ" > /etc/timezone; }
exec "$@"
