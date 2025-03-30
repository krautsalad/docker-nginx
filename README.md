# docker-nginx

Optimized Nginx Build with Brotli, Headers-More, and ModSecurity.

**docker-nginx** is an Alpine-based Docker container running the [nginx webserver](https://nginx.org/). It comes preconfigured with:

- An optimized configuration based on [h5bp](https://github.com/h5bp/server-configs-nginx)
- The [brotli module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/brotli) for improved compression
- The [headers-more module](https://docs.nginx.com/nginx/admin-guide/dynamic-modules/headers-more) for advanced header management
- ModSecurity integrated with the [OWASP CRS](https://owasp.org/www-project-modsecurity-core-rule-set/) for enhanced security

## Configuration

### Docker Compose Example

```yml
# docker-compose.yml
services:
  nginx:
    container_name: nginx
    environment:
      TZ: Europe/Berlin
    image: krautsalad/nginx
    # needed for getting real client ips
    network_mode: "host"
    # needed for http3/quic
    privileged: true
    restart: unless-stopped
    volumes:
      - ./config/nginx:/etc/nginx/sites:ro
      - ./data/ssl:/etc/nginx/ssl:ro
      - ./logs:/var/log/nginx
```

### Environment Variables

- `TZ`: Timezone setting (default: UTC).

## How it works

A default server configuration is provided that:

- Redirects all HTTP traffic to HTTPS
- Handles ACME challenges for Let's Encrypt

For ACME challenges, mount the folder `./data/acme-challenge` to `/etc/nginx/acme-challenge:ro`. For more details on using Let's Encrypt with this setup, see [krautsalad/dehydrated](https://hub.docker.com/r/krautsalad/dehydrated).

### Sites Configuration

Place your individual site configuration files in the `./config/nginx` directory. For example, the configuration below sets up log files, enables ModSecurity, and acts as a reverse proxy for a Docker container named `server1.example.com-web` (which listens on port 8080):

```txt
# server1.example.com.conf
server {
  listen [::]:443 quic;
  listen [::]:443 ssl;

  server_name seafile.ro14.sh;

  include custom/defaults_https.conf;
  ssl_certificate /etc/nginx/ssl/server1.example.com.pem;
  ssl_certificate_key /etc/nginx/ssl/server1.example.com.key;

  access_log /var/log/nginx/access_server1.example.com_log main;
  error_log /var/log/nginx/error_server1.example.com_log notice;

  modsecurity_rules '
    SecAuditEngine RelevantOnly
    SecAuditLog /var/log/nginx/modsecurity_server1.example.com_log
    SecAuditLogParts ABIJDEFHZ
  ';

  location / {
    set $upstream server1.example.com-web:8080;

    include custom/defaults_proxy.conf;
    include custom/dns_localhost.conf;
  }
}
```

*Note*: For proper name resolution of Docker containers, ensure you have a DNS server running. See [krautsalad/dnsmasq](https://hub.docker.com/r/krautsalad/dnsmasq) for more details on setting up a DNS service.

## Source Code

You can find the full source code on [GitHub](https://github.com/krautsalad/docker-nginx).
