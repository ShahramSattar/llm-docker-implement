# Nginx Docker Projects

This repository contains two Nginx configurations for different use cases:

## 📁 Project Structure

```
.
├── nginx-docker/                    # Basic Nginx setup (HTTP only)
│   ├── docker-compose.yml          # Port 8080
│   ├── Dockerfile
│   ├── nginx.conf
│   └── index.html
│
└── nginx-ssl-docker/               # Nginx with SSL/TLS
    ├── docker-compose.yml          # Development setup
    ├── docker-compose.prod.yml     # Production setup
    ├── Dockerfile                  # Development build
    ├── Dockerfile.prod             # Production build
    ├── nginx/
    │   ├── nginx.conf             # Main Nginx config
    │   ├── ssl_self.conf          # Self-signed SSL config
    │   └── ssl.conf               # Production SSL config
    ├── ssl/
    │   └── self-signed/           # Development certificates
    ├── certbot/                   # Let's Encrypt certificates
    ├── html/                      # Website content
    ├── init-letsencrypt.sh        # Let's Encrypt initializer
    ├── setup-dev.sh               # Development setup
    └── setup-prod.sh              # Production setup
```

## 🚀 Quick Start

### Option 1: Basic Nginx (HTTP Only)
```bash
cd nginx-docker
docker-compose up -d
# Access: http://localhost:8080
```

### Option 2: Nginx with SSL/TLS
```bash
cd nginx-ssl-docker
./setup-dev.sh
docker-compose up -d
# Access: https://localhost
```

## 📋 Detailed Setup Instructions

### 1. Basic Nginx Setup (nginx-docker)

Simple HTTP server for basic web serving needs.

**Start the server:**
```bash
cd nginx-docker
docker-compose up -d
```

**Access:** http://localhost:8080

**Features:**
- Simple static file serving
- Port 8080 (avoiding conflicts)
- Volume mounts for live updates
- Alpine-based (lightweight)

### 2. SSL-Enabled Nginx (nginx-ssl-docker)

Full-featured Nginx with SSL/TLS support for development and production.

#### Development Setup

**First-time setup:**
```bash
cd nginx-ssl-docker
chmod +x setup-dev.sh
./setup-dev.sh
```

**Start development server:**
```bash
docker-compose up -d
```

**Access:** 
- HTTP: http://localhost (redirects to HTTPS)
- HTTPS: https://localhost

**Note:** Browser will show security warning for self-signed certificate. This is normal for development.

#### Production Setup

**Prepare for production:**
```bash
chmod +x setup-prod.sh init-letsencrypt.sh
./setup-prod.sh
```

**Configure your domain:**
1. Edit `nginx/ssl.conf` - replace `yourdomain.com` with your actual domain
2. Ensure DNS A records point to your server
3. Update email in `init-letsencrypt.sh`

**Initialize Let's Encrypt:**
```bash
./init-letsencrypt.sh yourdomain.com
```

**Start production server:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

## 🔧 Configuration Details

### Port Mappings

| Service | Environment | HTTP Port | HTTPS Port |
|---------|------------|-----------|------------|
| nginx-docker | Basic | 8080 | N/A |
| nginx-ssl-docker | Development | 80 | 443 |
| nginx-ssl-docker | Production | 80 | 443 |

### SSL Certificates

**Development:** Self-signed certificates (auto-generated)
- Location: `ssl/self-signed/`
- Valid for: 365 days
- CN: localhost

**Production:** Let's Encrypt certificates
- Location: `certbot/conf/`
- Auto-renewal: Every 12 hours check
- Valid for: 90 days

## 🛠️ Common Commands

### Docker Commands
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Rebuild images
docker-compose build --no-cache
```

### SSL Certificate Commands
```bash
# Check certificate expiry
docker-compose exec nginx-dev openssl x509 -in /etc/nginx/ssl/self-signed/cert.pem -noout -dates

# Test SSL connection
openssl s_client -connect localhost:443 -servername localhost

# Force certificate renewal (production)
docker-compose -f docker-compose.prod.yml run --rm certbot renew --force-renewal
```

## 🐛 Troubleshooting

### Certificate Issues

**Error: Cannot find certificates**
```bash
cd nginx-ssl-docker
ls -la ssl/self-signed/

# If empty, regenerate:
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/self-signed/key.pem \
    -out ssl/self-signed/cert.pem \
    -subj "/C=US/ST=Dev/L=Local/O=DevTeam/CN=localhost"

# Set permissions
chmod 644 ssl/self-signed/cert.pem
chmod 600 ssl/self-signed/key.pem
```

### Port Conflicts
```bash
# Check what's using ports
sudo lsof -i :80
sudo lsof -i :443
sudo lsof -i :8080

# Change ports in docker-compose.yml if needed
```

### Container Won't Start
```bash
# Check logs
docker-compose logs nginx-dev

# Validate Nginx config
docker-compose exec nginx-dev nginx -t

# Check file permissions
ls -la nginx/
ls -la ssl/
```

## 💡 Improvements & Suggestions

Based on your current setup, here are some recommended improvements:

### 1. Add Health Checks
Add to your docker-compose files:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

### 2. Create a Unified Setup Script
Create `setup-all.sh` in the root:
```bash
#!/bin/bash
echo "🚀 Setting up all Nginx environments..."

# Setup basic nginx
cd nginx-docker
docker-compose build

# Setup SSL nginx
cd ../nginx-ssl-docker
./setup-dev.sh

echo "✅ All environments ready!"
echo "Basic Nginx: cd nginx-docker && docker-compose up -d"
echo "SSL Nginx: cd nginx-ssl-docker && docker-compose up -d"
```

### 3. Add .env Files for Configuration
Create `.env` files for easier configuration:

**nginx-docker/.env:**
```env
HTTP_PORT=8080
CONTAINER_NAME=nginx-basic
```

**nginx-ssl-docker/.env:**
```env
HTTP_PORT=80
HTTPS_PORT=443
DOMAIN=localhost
EMAIL=admin@example.com
```

### 4. Add Logging Configuration
Create `nginx/logging.conf`:
```nginx
log_format detailed '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" '
                    '$request_time $upstream_response_time';

access_log /var/log/nginx/access.log detailed;
error_log /var/log/nginx/error.log warn;
```

### 5. Add Security Headers
Update your SSL configs with enhanced security:
```nginx
# Security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

### 6. Create a Makefile
Add a `Makefile` in the root for easier management:
```makefile
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make basic-up    - Start basic Nginx"
	@echo "  make basic-down  - Stop basic Nginx"
	@echo "  make ssl-up      - Start SSL Nginx"
	@echo "  make ssl-down    - Stop SSL Nginx"
	@echo "  make logs        - Show all logs"
	@echo "  make clean       - Clean all containers"

basic-up:
	cd nginx-docker && docker-compose up -d

basic-down:
	cd nginx-docker && docker-compose down

ssl-up:
	cd nginx-ssl-docker && docker-compose up -d

ssl-down:
	cd nginx-ssl-docker && docker-compose down

logs:
	cd nginx-docker && docker-compose logs -f &
	cd nginx-ssl-docker && docker-compose logs -f

clean:
	cd nginx-docker && docker-compose down -v
	cd nginx-ssl-docker && docker-compose down -v
```

### 7. Add .gitignore
Create `.gitignore` in the root:
```gitignore
# Certificates
*.pem
*.key
*.crt
*.csr

# Let's Encrypt
certbot/

# Logs
*.log

# Environment files with secrets
.env.local
.env.production

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
```

## 📚 Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)

## 🔒 Security Best Practices

1. **Never commit private keys or certificates to version control**
2. **Use strong Diffie-Hellman parameters in production**
3. **Keep Nginx and Docker images updated**
4. **Monitor certificate expiration dates**
5. **Use rate limiting in production**
6. **Enable OCSP stapling for better performance**

## 📈 Performance Tips

1. **Enable gzip compression**
2. **Use HTTP/2 (already enabled in SSL configs)**
3. **Configure proper cache headers**
4. **Use CDN for static assets in production**
5. **Monitor resource usage with `docker stats`**

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Author:** Shahram with help of AI  
**License:** MIT  
**Last Updated:** July 2025