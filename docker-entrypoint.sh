#!/bin/sh
set -e
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3.0;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so.3;
ln -sf /usr/local/modsecurity/lib/libmodsecurity.so.${MODSEC3_VERSION} /usr/local/modsecurity/lib/libmodsecurity.so;
exec "$@"
