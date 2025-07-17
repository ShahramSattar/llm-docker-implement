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
