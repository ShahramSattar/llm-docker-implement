# LLM Docker Implementation — Quick Reference

## 🚀 Starting Services

```bash
# Start everything (recommended — creates shared network automatically)
./start-all.sh

# Start only Ollama/WebUI/n8n
docker network create shared-llm-network 2>/dev/null || true
docker compose up -d

# Start only Supabase
docker network create shared-llm-network 2>/dev/null || true
cd supabase-db && docker compose up -d && cd ..
```

## 🛑 Stopping Services

```bash
# Stop everything
./stop-all.sh

# Stop only main stack
docker compose down

# Stop only Supabase
cd supabase-db && docker compose down && cd ..
```

## 🩺 Service Management

```bash
# Check health
./health-check.sh

# View logs
./logs.sh all              # All services
./logs.sh ollama           # Specific service
./logs.sh supabase         # All Supabase services

# Restart a single service
docker compose restart n8n
cd supabase-db && docker compose restart studio && cd ..
```

## 🤖 Ollama Commands

```bash
docker exec -it ollama ollama list             # List installed models
docker exec -it ollama ollama pull mistral     # Download a model
docker exec -it ollama ollama rm llama2        # Remove a model
docker exec -it ollama ollama run mistral      # Interactive chat
./pull-models.sh                               # Pull several recommended models
```

## 🔗 API Quick Tests

### Ollama
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama2", "prompt": "Hello", "stream": false}'
```

### Supabase
```bash
curl http://localhost:8000/rest/v1/ \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY"

curl http://localhost:8000/auth/v1/health
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `.env` | Main stack secrets (n8n, WebUI keys) |
| `supabase-db/.env` | Supabase secrets (Postgres, JWT keys) |
| `docker-compose.yml` | Ollama + WebUI + n8n services |
| `supabase-db/docker-compose.yml` | Supabase services |
| `supabase-db/kong.yml` | Kong API gateway routes |

## 💾 Data Volumes

| Volume | Contains |
|--------|---------|
| `ollama_data` | Downloaded LLM models |
| `open_webui_data` | Conversations, WebUI config |
| `n8n_data` | n8n workflows, SQLite database |
| `supabase-db_postgres-data` | Supabase PostgreSQL data |
| `supabase-db_storage-data` | Supabase uploaded files |

## 🌐 Service URLs

| Service | URL | Port |
|---------|-----|------|
| Open WebUI | http://localhost:3002 | 3002 |
| n8n | http://localhost:5678 | 5678 |
| Ollama API | http://localhost:11434 | 11434 |
| Supabase Studio | http://localhost:3000 | 3000 |
| Supabase API (Kong) | http://localhost:8000 | 8000 |

> No port conflicts — Open WebUI runs on **3002**, Supabase Studio on **3000**.

## 🔐 Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| Open WebUI | — | Create on first visit (first = admin) |
| n8n | `admin` | Value of `N8N_BASIC_AUTH_PASSWORD` in `.env` |
| Supabase Studio | — | No login (internal service key) |
| Supabase Postgres | `postgres` | Value of `POSTGRES_PASSWORD` in `supabase-db/.env` |

## 🛠️ Troubleshooting

### Shared network missing
```bash
docker network create shared-llm-network
```

### Port already in use
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <pid> /F

# Mac/Linux
lsof -i :3000 && kill <pid>
```

### n8n can't reach Ollama
```bash
docker exec n8n wget -qO- http://ollama:11434/api/tags
docker network inspect shared-llm-network
```

### Memory issues / containers crashing
```bash
docker stats                                      # Live resource usage
docker exec -it ollama ollama rm llama2:70b       # Remove large models
# Increase RAM in Docker Desktop → Settings → Resources
```

### Connect to Supabase PostgreSQL
```bash
docker exec -it supabase-postgres psql -U postgres
# \l    list databases
# \dt   list tables
# \q    quit
```

## 💾 Backup & Restore

```bash
./backup.sh                                    # Create timestamped backup
ls -la backups/                                # List backups
./restore.sh backups/20260416_120000           # Restore specific backup
```

## 📊 Resource Monitoring

```bash
docker stats                     # Live CPU/memory per container
docker system df                 # Disk usage by images/volumes
docker system prune -a           # Remove unused images and containers (careful!)
```

## 🆘 Emergency Commands

```bash
# Stop all running containers
docker stop $(docker ps -q)

# Full reset (WARNING: deletes all data)
./reset-all.sh

# View container logs
docker logs <container_name> --tail 50 -f

# Open a shell inside a container
docker exec -it <container_name> bash
```

---

For full documentation see:
- [ReadMe.md](ReadMe.md) — Main guide
- [Readme-Ollama.md](Readme-Ollama.md) — Ollama/WebUI/n8n details
- [ReadMe-Supabase.md](ReadMe-Supabase.md) — Supabase details
- [nginx-docker/ReadME-Nginx.md](nginx-docker/ReadME-Nginx.md) — Nginx/SSL setup
