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
