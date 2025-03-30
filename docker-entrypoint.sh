#!/bin/sh
set -e
mkdir -p /etc/nginx/acme-challenge
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so;
[ -n "$TZ" ] && [ -f /usr/share/zoneinfo/"$TZ" ] && { cp /usr/share/zoneinfo/"$TZ" /etc/localtime; echo "$TZ" > /etc/timezone; }
exec "$@"
