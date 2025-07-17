#!/bin/bash
# Stop all services

echo "🛑 Stopping all services..."

# Stop Ollama/WebUI/n8n stack
echo "Stopping Ollama, WebUI, and n8n..."
docker-compose down

# Stop Supabase stack
echo "Stopping Supabase..."
cd supabase-db && docker-compose down && cd ..

echo "✅ All services stopped"
