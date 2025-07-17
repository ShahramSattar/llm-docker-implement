#!/bin/bash

# Create start-all.sh
cat > start-all.sh << 'EOF'
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
EOF

# Create stop-all.sh
cat > stop-all.sh << 'EOF'
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
EOF

# Create health-check.sh
cat > health-check.sh << 'EOF'
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
check_endpoint "http://localhost:3001" "Open WebUI (port 3001)"
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
EOF

# Create pull-models.sh
cat > pull-models.sh << 'EOF'
#!/bin/bash
# Pull recommended Ollama models

echo "📥 Pulling recommended Ollama models..."

models=("llama2" "mistral" "codellama" "phi" "neural-chat")

for model in "${models[@]}"; do
    echo ""
    echo "Pulling $model..."
    docker exec -it ollama ollama pull $model
done

echo ""
echo "✅ Model download complete!"
docker exec -it ollama ollama list
EOF

# Create backup.sh
cat > backup.sh << 'EOF'
#!/bin/bash
# Backup all data

BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "📦 Creating backup in $BACKUP_DIR..."

# Backup Ollama models
echo "Backing up Ollama models..."
docker run --rm -v ollama_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/ollama-models.tar.gz -C /data .

# Backup Open WebUI data
echo "Backing up Open WebUI data..."
docker run --rm -v open_webui_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/webui-data.tar.gz -C /data .

# Backup n8n data
echo "Backing up n8n data..."
docker exec postgres pg_dump -U postgres > $BACKUP_DIR/n8n-postgres.sql
docker run --rm -v n8n_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/n8n-data.tar.gz -C /data .

# Backup Supabase
echo "Backing up Supabase..."
cd supabase-db
docker exec supabase-postgres pg_dumpall -U postgres > ../$BACKUP_DIR/supabase-postgres.sql
docker run --rm -v supabase-db_postgres-data:/data -v $(pwd)/../$BACKUP_DIR:/backup alpine tar czf /backup/supabase-postgres-data.tar.gz -C /data .
docker run --rm -v supabase-db_storage-data:/data -v $(pwd)/../$BACKUP_DIR:/backup alpine tar czf /backup/supabase-storage-data.tar.gz -C /data .
cd ..

echo "✅ Backup completed!"
echo "📁 Backup location: $BACKUP_DIR"
ls -la $BACKUP_DIR
EOF

# Create restore.sh
cat > restore.sh << 'EOF'
#!/bin/bash
# Restore from backup

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup-directory>"
    echo "Example: ./restore.sh backups/20240115_120000"
    exit 1
fi

BACKUP_DIR=$1

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

echo "📦 Restoring from $BACKUP_DIR..."

read -p "⚠️  This will overwrite existing data. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled"
    exit 1
fi

# Restore n8n database
if [ -f "$BACKUP_DIR/n8n-postgres.sql" ]; then
    echo "Restoring n8n database..."
    docker exec -i postgres psql -U postgres < $BACKUP_DIR/n8n-postgres.sql
fi

# Restore Supabase database
if [ -f "$BACKUP_DIR/supabase-postgres.sql" ]; then
    echo "Restoring Supabase database..."
    cd supabase-db
    docker exec -i supabase-postgres psql -U postgres < ../$BACKUP_DIR/supabase-postgres.sql
    cd ..
fi

# Restore volumes
if [ -f "$BACKUP_DIR/ollama-models.tar.gz" ]; then
    echo "Restoring Ollama models..."
    docker run --rm -v ollama_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/ollama-models.tar.gz -C /data
fi

if [ -f "$BACKUP_DIR/webui-data.tar.gz" ]; then
    echo "Restoring WebUI data..."
    docker run --rm -v open_webui_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar xzf /backup/webui-data.tar.gz -C /data
fi

echo "✅ Restore completed!"
EOF

# Create logs.sh
cat > logs.sh << 'EOF'
#!/bin/bash
# View logs for services

if [ -z "$1" ]; then
    echo "Usage: ./logs.sh <service-name|all>"
    echo ""
    echo "Available services:"
    echo "  Main stack: ollama, open-webui, n8n, postgres"
    echo "  Supabase: supabase-postgres, supabase-studio, supabase-kong, supabase-auth"
    echo "  Special: all, main, supabase"
    exit 1
fi

case $1 in
    all)
        echo "📜 Showing logs for all services..."
        docker-compose logs -f --tail=50 &
        cd supabase-db && docker-compose logs -f --tail=50 &
        wait
        ;;
    main)
        echo "📜 Showing logs for main stack..."
        docker-compose logs -f --tail=100
        ;;
    supabase)
        echo "📜 Showing logs for Supabase stack..."
        cd supabase-db && docker-compose logs -f --tail=100
        ;;
    supabase-*)
        echo "📜 Showing logs for $1..."
        cd supabase-db && docker-compose logs -f --tail=100 ${1#supabase-}
        ;;
    *)
        echo "📜 Showing logs for $1..."
        docker-compose logs -f --tail=100 $1
        ;;
esac
EOF

# Create reset-all.sh
cat > reset-all.sh << 'EOF'
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
EOF

# Create quick-start.sh
cat > quick-start.sh << 'EOF'
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
EOF

# Make all scripts executable
chmod +x start-all.sh stop-all.sh health-check.sh pull-models.sh backup.sh restore.sh logs.sh reset-all.sh quick-start.sh

echo "✅ All scripts created successfully!"
echo ""
echo "Available scripts:"
echo "  ./quick-start.sh  - First-time setup guide"
echo "  ./start-all.sh    - Start all services"
echo "  ./stop-all.sh     - Stop all services"
echo "  ./health-check.sh - Check service health"
echo "  ./pull-models.sh  - Download AI models"
echo "  ./backup.sh       - Backup all data"
echo "  ./restore.sh      - Restore from backup"
echo "  ./logs.sh         - View service logs"
echo "  ./reset-all.sh    - Reset everything (WARNING: deletes data)"