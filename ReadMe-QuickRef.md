# LLM Docker Implementation - Quick Reference

## 🚀 Quick Commands

### Starting Services
```bash
# Start everything
./start-all.sh

# Start only Ollama/WebUI/n8n
docker-compose up -d

# Start only Supabase
cd supabase-db && docker-compose up -d && cd ..
```

### Stopping Services
```bash
# Stop everything
./stop-all.sh

# Stop only main stack
docker-compose down

# Stop only Supabase
cd supabase-db && docker-compose down && cd ..
```

### Service Management
```bash
# Check health
./health-check.sh

# View logs
./logs.sh all              # All services
./logs.sh ollama           # Specific service
./logs.sh supabase         # All Supabase services

# Restart a service
docker-compose restart n8n
cd supabase-db && docker-compose restart studio && cd ..
```

## 🤖 Ollama Commands

```bash
# List models
docker exec -it ollama ollama list

# Pull a model
docker exec -it ollama ollama pull llama2

# Remove a model
docker exec -it ollama ollama rm llama2

# Run a model (interactive)
docker exec -it ollama ollama run llama2

# Get all available models
./pull-models.sh
```

## 🔗 API Examples

### Ollama API
```bash
# Generate text
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "llama2", "prompt": "Hello world", "stream": false}'

# Chat
curl -X POST http://localhost:11434/api/chat \
  -d '{"model": "llama2", "messages": [{"role": "user", "content": "Hello"}]}'
```

### Supabase API
```bash
# Test connection
curl http://localhost:8000/rest/v1/ \
  -H "apikey: your-anon-key" \
  -H "Authorization: Bearer your-anon-key"
```

## 📁 File Locations

### Configuration Files
- Main environment: `.env`
- Supabase environment: `supabase-db/.env`
- Kong config: `supabase-db/kong.yml`

### Docker Compose Files
- Main stack: `docker-compose.yml`
- Supabase: `supabase-db/docker-compose.yml`

### Data Volumes
- Ollama models: `ollama_data`
- WebUI data: `open_webui_data`
- n8n data: `n8n_data`
- n8n PostgreSQL: `postgres_data`
- Supabase PostgreSQL: `supabase-db_postgres-data`
- Supabase storage: `supabase-db_storage-data`

## 🛠️ Troubleshooting

### Port Conflicts
```bash
# Check what's using a port
netstat -ano | findstr :3000        # Windows
lsof -i :3000                       # Mac/Linux

# Change ports in docker-compose.yml
# Example: Change Open WebUI to port 3001
ports:
  - "3001:8080"
```

### Memory Issues
```bash
# Check container stats
docker stats

# Increase Docker memory in Docker Desktop settings
# Remove large models
docker exec -it ollama ollama rm llama2:70b
```

### Connection Issues
```bash
# Test Ollama
docker exec n8n wget -qO- http://ollama:11434/api/tags

# Test Supabase from main stack
docker exec n8n wget -qO- http://host.docker.internal:8000

# Check networks
docker network ls
```

### Database Access
```bash
# Connect to n8n PostgreSQL
docker exec -it postgres psql -U postgres

# Connect to Supabase PostgreSQL
docker exec -it supabase-postgres psql -U postgres

# Common PostgreSQL commands
\l          # List databases
\dt         # List tables
\d table    # Describe table
\q          # Quit
```

## 🔐 Default Credentials

### Main Stack
- Open WebUI: Create on first visit (first user is admin)
- n8n: `admin` / password from `.env`
- PostgreSQL: `postgres` / password from `.env`

### Supabase
- Studio: No login (uses service key)
- PostgreSQL: `postgres` / password from `supabase-db/.env`
- API Keys: In `supabase-db/.env`

## 📊 Monitoring

### Check Resource Usage
```bash
# Container stats
docker stats

# Disk usage
docker system df

# Clean up unused resources
docker system prune -a
```

### Service Endpoints
- Open WebUI: http://localhost:3000
- n8n: http://localhost:5678
- Ollama API: http://localhost:11434
- Supabase Studio: http://localhost:3000 (conflicts with WebUI)
- Supabase API: http://localhost:8000

## 💾 Backup & Restore

```bash
# Create backup
./backup.sh

# List backups
ls -la backups/

# Restore from backup
./restore.sh backups/20240115_120000
```

## 🆘 Emergency Commands

```bash
# Stop everything immediately
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -a -q)

# Reset everything (WARNING: Deletes all data!)
./reset-all.sh

# Check Docker logs
docker logs container_name --tail 50

# Enter a container
docker exec -it container_name bash
```

## 📝 Notes

1. **Port 3000 Conflict**: Both Open WebUI and Supabase Studio use port 3000. Run them separately or change ports.

2. **Network Isolation**: The two stacks use different Docker networks. To connect them, create a shared network.

3. **GPU Support**: Uncomment GPU sections in docker-compose.yml for NVIDIA GPU acceleration.

4. **Production Use**: Always change default passwords, use HTTPS, and implement proper security measures.

---

For detailed documentation, see the main README.md