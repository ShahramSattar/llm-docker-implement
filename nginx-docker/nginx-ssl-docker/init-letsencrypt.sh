#!/bin/bash
# Initialize Let's Encrypt certificates

if [ -z "$1" ]; then
    echo "Usage: ./init-letsencrypt.sh vdimtech.com"
    exit 1
fi

DOMAIN=$1

echo "🔐 Initializing Let's Encrypt for $DOMAIN..."

# Start nginx temporarily for challenge
docker-compose -f docker-compose.prod.yml up -d nginx

# Get certificate
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot --webroot-path /var/www/certbot \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN

# Restart everything
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

echo "✅ Let's Encrypt setup complete!"