#!/bin/bash
# Development setup script

echo "🔧 Setting up development environment..."

# Create directories
mkdir -p nginx ssl/self-signed html

# Generate self-signed certificate
if [ ! -f ssl/self-signed/cert.pem ]; then
    echo "🔐 Generating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/self-signed/key.pem \
        -out ssl/self-signed/cert.pem \
        -subj "/C=US/ST=Dev/L=Local/O=DevTeam/CN=localhost"
    chmod 644 ssl/self-signed/cert.pem
    chmod 600 ssl/self-signed/key.pem
fi

echo "✅ Development setup complete!"
echo "Run: docker-compose up -d"