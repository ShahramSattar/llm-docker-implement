#!/bin/bash
# Reset everything - WARNING: This will delete all data!

echo "⚠️  WARNING: This will delete ALL data including:"
echo "  - All Ollama models"
echo "  - All n8n workflows"
echo "  - All WebUI conversations"
echo "  - All Supabase data"
echo ""
read -p "Are you absolutely sure? Type YES to continue: " -r
echo

if [[ $REPLY != "YES" ]]; then
    echo "Reset cancelled"
    exit 1
fi

echo "🔄 Resetting everything..."

# Stop all services
./stop-all.sh

# Remove volumes
echo "Removing main stack volumes..."
docker-compose down -v

echo "Removing Supabase volumes..."
cd supabase-db && docker-compose down -v && cd ..

# Remove any dangling volumes
docker volume prune -f

echo "✅ Reset complete. All data has been removed."
echo "Run ./start-all.sh to start fresh."
