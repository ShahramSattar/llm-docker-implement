#!/bin/bash
echo "Which setup do you want?"
echo "1) Basic Nginx (HTTP only)"
echo "2) Nginx with SSL"
read -p "Enter choice [1-2]: " choice

case $choice in
    1)
        cd nginx-docker
        docker-compose up -d
        echo "✅ Basic Nginx running at http://localhost:8080"
        ;;
    2)
        cd nginx-ssl-docker
        ./setup-dev.sh
        docker-compose up -d
        echo "✅ SSL Nginx running at https://localhost"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac