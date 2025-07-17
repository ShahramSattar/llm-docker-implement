#!/bin/bash
# Quick start script for first-time setup

echo "🚀 LLM Docker Implementation Quick Start"
echo "======================================="

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed."
    exit 1
fi

echo "✅ Prerequisites checked"

# Setup environment files
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
        echo "⚠️  Please edit .env with your values"
    else
        echo "❌ .env.example not found!"
        exit 1
    fi
fi

if [ ! -f supabase-db/.env ]; then
    if [ -f supabase-db/.env.example ]; then
        echo "Creating supabase-db/.env from template..."
        cp supabase-db/.env.example supabase-db/.env
        echo "⚠️  Please edit supabase-db/.env with your values"
    else
        echo "❌ supabase-db/.env.example not found!"
        exit 1
    fi
fi

# Check if JWT keys need to be generated
if grep -q "your-generated-anon-key" supabase-db/.env; then
    echo ""
    echo "⚠️  You need to generate JWT keys for Supabase:"
    echo "  1. cd supabase-db"
    echo "  2. npm install"
    echo "  3. node generate-keys.js"
    echo "  4. Copy the generated keys to supabase-db/.env"
    echo ""
    read -p "Press Enter when you have completed this step..."
fi

# Start services
echo ""
echo "Starting all services..."
./start-all.sh

echo ""
echo "🎉 Quick start complete!"
echo ""
echo "Next steps:"
echo "1. Pull some AI models: ./pull-models.sh"
echo "2. Access Open WebUI: http://localhost:3000"
echo "3. Access n8n: http://localhost:5678"
echo "4. Access Supabase Studio: http://localhost:3000 (different port needed if running both)"
echo ""
echo "Run ./health-check.sh to verify all services are running correctly."
