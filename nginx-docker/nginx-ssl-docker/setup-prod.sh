#!/bin/bash
# Production setup script

echo "🚀 Setting up production environment..."

# Create directories
mkdir -p nginx ssl/production certbot/conf certbot/www html

# Generate Diffie-Hellman parameters
if [ ! -f ssl/production/dhparam.pem ]; then
    echo "🔐 Generating DH parameters (this may take a while)..."
    openssl dhparam -out ssl/production/dhparam.pem 2048
fi

# Initial Let's Encrypt setup
echo "📝 Remember to:"
echo "1. Update yourdomain.com in nginx/ssl.conf"
echo "2. Point your domain to this server"
echo "3. Run: ./init-letsencrypt.sh yourdomain.com"

echo "✅ Production setup complete!"