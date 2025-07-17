#!/bin/bash
# Check health of all services

echo "🏥 LLM Docker Implementation Health Check"
echo "========================================"

# Function to check if a service is running
check_service() {
    local container_name=$1
    if docker ps | grep -q $container_name; then
        echo "✅ $container_name is running"
    else
        echo "❌ $container_name is not running"
    fi
}

# Function to check HTTP endpoint
check_endpoint() {
    local url=$1
    local name=$2
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|401\|404"; then
        echo "✅ $name is accessible at $url"
    else
        echo "❌ $name is not accessible at $url"
    fi
}

echo ""
echo "📦 Ollama/WebUI/n8n Stack:"
echo "--------------------------"
check_service "ollama"
check_service "open-webui"
check_service "n8n"

echo ""
echo "🌐 Ollama/WebUI/n8n Endpoints:"
check_endpoint "http://localhost:11434/api/tags" "Ollama API"
check_endpoint "http://localhost:3002" "Open WebUI (port 3002)"
check_endpoint "http://localhost:5678" "n8n"

echo ""
echo "📦 Supabase Stack:"
echo "------------------"
check_service "supabase-postgres"
check_service "supabase-studio"
check_service "supabase-kong"
check_service "supabase-auth"
check_service "supabase-rest"
check_service "supabase-realtime"
check_service "supabase-storage"

echo ""
echo "🌐 Supabase Endpoints:"
check_endpoint "http://localhost:8000" "Kong API Gateway"
check_endpoint "http://localhost:8000/auth/v1/health" "Auth Service"

echo ""
echo "💾 Database Status:"
echo "- n8n is using SQLite (no PostgreSQL needed)"
docker exec supabase-postgres pg_isready -U postgres >/dev/null 2>&1 && echo "✅ PostgreSQL (Supabase) is ready" || echo "❌ PostgreSQL (Supabase) is not ready"

echo ""
echo "📝 Notes:"
echo "- Open WebUI is running on port 3001 (not 3000)"
echo "- n8n is using SQLite, not PostgreSQL"
echo "- Supabase Studio runs on port 3000"
