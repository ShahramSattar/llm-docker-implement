#!/bin/bash
# Start all services in the LLM Docker Implementation

echo "🚀 Starting LLM Docker Implementation..."

# Check if .env files exist
if [ ! -f .env ]; then
    echo "❌ .env file not found in root directory!"
    exit 1
fi

if [ ! -f supabase-db/.env ]; then
    echo "❌ supabase-db/.env file not found!"
    exit 1
fi

# Start Ollama/WebUI/n8n stack
echo "📦 Starting Ollama, WebUI, and n8n..."
docker-compose up -d

# Start Supabase stack
echo "📦 Starting Supabase..."
cd supabase-db && docker-compose up -d && cd ..

# Wait for services to initialize
echo "⏳ Waiting for services to be healthy (30 seconds)..."
sleep 30

# Check service status
echo ""
echo "✅ Services started! Checking status..."
./health-check.sh
