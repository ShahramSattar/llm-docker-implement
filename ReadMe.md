# LLM Docker Implementation

A comprehensive AI development environment with two integrated stacks: Ollama/WebUI/n8n for AI capabilities and Supabase for backend services.

## 📁 Project Structure

```
llm-docker-implement/
├── ReadMe.md                       # This file
├── docker-compose.yml              # Ollama + WebUI + n8n stack
├── .env                            # Main stack environment variables
├── .env.example                    # Environment template
├── .gitignore
├── start-all.sh                    # Start both stacks + shared network
├── stop-all.sh
├── health-check.sh
├── backup.sh / restore.sh
├── pull-models.sh
├── .github/workflows/ci.yml        # GitHub Actions CI
├── supabase-db/
│   ├── docker-compose.yml          # Supabase stack
│   ├── .env                        # Supabase environment variables
│   ├── .env.example                # Supabase environment template
│   ├── kong.yml                    # Kong API gateway config (v3.x format)
│   ├── package.json
│   └── generate-keys.js            # JWT key generator
└── nginx-docker/                   # Nginx (HTTP + SSL variants)
```

## 🚀 Quick Start

### Prerequisites
- Docker Desktop 4.0+ with Docker Compose v2.0+
- Node.js 18+ (for Supabase JWT generation)
- 16 GB RAM minimum (32 GB recommended for LLM inference)
- 50 GB+ free disk space

### 1. Clone the Repository

```bash
git clone <repository-url>
cd llm-docker-implement
```

### 2. Setup Environment Variables

```bash
cp .env.example .env
cp supabase-db/.env.example supabase-db/.env
```

### 3. Generate Security Keys

#### n8n Encryption Key (required — do not change once set)

**PowerShell:**
```powershell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

**Bash / Git Bash:**
```bash
openssl rand -base64 32
```

Add the result to `.env`:
```env
N8N_ENCRYPTION_KEY=your-generated-key
N8N_BASIC_AUTH_PASSWORD=choose-a-strong-password
```

#### Supabase JWT Keys

```bash
cd supabase-db
npm install
node generate-keys.js
# Copy the output into supabase-db/.env
cd ..
```

Also set a strong Postgres password in `supabase-db/.env`:
```bash
# Generate one with:
openssl rand -base64 16
```

### 4. Start Both Stacks

```bash
# Recommended: start everything at once (creates shared network automatically)
./start-all.sh

# Or start stacks individually (create the shared network first):
docker network create shared-llm-network
docker compose up -d
cd supabase-db && docker compose up -d && cd ..
```

---

## 🏗️ Architecture Overview

### Stack 1: Ollama + Open WebUI + n8n
```
┌──────────────────────────────────────────────────┐
│              Open WebUI  (Port 3002)              │
├──────────────────────────────┬───────────────────┤
│     n8n  (Port 5678)         │  Ollama (11434)   │
└──────────────────────────────┴───────────────────┘
          ↕ shared-llm-network ↕
```

### Stack 2: Supabase
```
┌─────────────────────────────────────────────────────┐
│               Supabase Studio  (Port 3000)           │
├─────────────────────────────────────────────────────┤
│               Kong API Gateway  (Port 8000)          │
├──────────┬──────────┬──────────┬────────────────────┤
│   Auth   │ Realtime │ Storage  │    PostgREST        │
│  (9999)  │  (4000)  │  (5000)  │     (3001)          │
├──────────┴──────────┴──────────┴────────────────────┤
│                  PostgreSQL  (Port 5432)              │
└─────────────────────────────────────────────────────┘
          ↕ shared-llm-network ↕
```

Both stacks join `shared-llm-network` so n8n can call Supabase APIs directly using container hostnames (e.g. `http://kong:8000`).

---

## 🌐 Service Access Points

### Ollama / WebUI / n8n Stack
| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Open WebUI | http://localhost:3002 | Create on first visit |
| n8n | http://localhost:5678 | admin / (from `.env`) |
| Ollama API | http://localhost:11434 | No authentication |

### Supabase Stack
| Service | URL | Notes |
|---------|-----|-------|
| Supabase Studio | http://localhost:3000 | Uses service key internally |
| Kong API | http://localhost:8000 | API keys from `supabase-db/.env` |
| Auth API | http://localhost:8000/auth/v1 | |
| REST API | http://localhost:8000/rest/v1 | |
| Realtime | ws://localhost:8000/realtime/v1 | |
| PostgreSQL | localhost:5432 | postgres / (from `supabase-db/.env`) |

> **Port conflict note**: Supabase Studio (3000) and Open WebUI (3002) are on different ports — no conflict when running both stacks simultaneously.

---

## 📦 Image Versions (pinned)

| Service | Image | Version |
|---------|-------|---------|
| Ollama | `ollama/ollama` | `0.20.7` |
| Open WebUI | `ghcr.io/open-webui/open-webui` | `v0.8.6` |
| n8n | `n8nio/n8n` | `2.14.1` |
| Supabase Postgres | `supabase/postgres` | `15.8.1.085` |
| Supabase Studio | `supabase/studio` | `2026.04.08-sha-205cbe7` |
| Kong | `kong` | `3.9.1` |
| GoTrue (Auth) | `supabase/gotrue` | `v2.186.0` |
| Realtime | `supabase/realtime` | `v2.76.5` |
| Storage API | `supabase/storage-api` | `v1.37.8` |
| Postgres Meta | `supabase/postgres-meta` | `v0.95.2` |
| PostgREST | `postgrest/postgrest` | `v12.2.0` |

---

## 📖 Usage Guide

### Managing Ollama Models

```bash
# List available models
docker exec -it ollama ollama list

# Pull recommended models
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama

# Or use the helper script
./pull-models.sh

# Remove a model
docker exec -it ollama ollama rm model-name
```

### n8n: Call Ollama from a Workflow

1. Access n8n at http://localhost:5678
2. Add an **HTTP Request** node:
   - URL: `http://ollama:11434/api/generate`
   - Method: POST
   - Body:
     ```json
     {
       "model": "llama2",
       "prompt": "{{ $json.prompt }}",
       "stream": false
     }
     ```

### Integrating with Supabase

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  process.env.ANON_KEY
)

// Store an AI conversation
const { error } = await supabase.from('conversations').insert({
  user_prompt: userPrompt,
  ai_response: aiResponse,
  model: 'llama2'
})
```

---

## 🛠️ Common Operations

```bash
# Start everything (recommended)
./start-all.sh

# Stop everything
./stop-all.sh

# Health check all services
./health-check.sh

# View logs
./logs.sh all          # all services
./logs.sh ollama       # single service
./logs.sh supabase     # all Supabase services

# Restart a single service
docker compose restart n8n
cd supabase-db && docker compose restart studio && cd ..

# Backup all data
./backup.sh

# Restore from backup
./restore.sh backups/20260416_120000
```

---

## 🔧 Configuration

### Main Stack `.env`
```env
N8N_ENCRYPTION_KEY=your-32-char-key        # Never change after first run
N8N_BASIC_AUTH_PASSWORD=strong-password
WEBUI_SECRET_KEY=your-webui-secret

# Optional: enable PostgreSQL for n8n (see docker-compose.yml)
# N8N_POSTGRES_PASSWORD=your-postgres-password
```

### Supabase `supabase-db/.env`
```env
POSTGRES_PASSWORD=your-strong-password    # Use: openssl rand -base64 16
JWT_SECRET=your-64-char-secret            # Use: openssl rand -base64 64
ANON_KEY=generated-anon-key               # Use: node generate-keys.js
SERVICE_ROLE_KEY=generated-service-key
```

### Port Configuration

Open WebUI is already on `3002` to avoid conflicting with Supabase Studio on `3000`. To change any port, edit the `ports:` mapping in the relevant `docker-compose.yml` and update the corresponding variable in `.env`.

---

## 🚨 Troubleshooting

### Shared Network Missing
```bash
# Both stacks require this network — start-all.sh creates it automatically.
# If running stacks manually:
docker network create shared-llm-network
```

### Port Already Allocated
```bash
# Windows PowerShell
netstat -ano | findstr :3000
taskkill /PID <pid> /F

# Mac/Linux
lsof -i :3000
kill <pid>
```

### Memory Issues
If containers crash or models are slow:
1. Open Docker Desktop → Settings → Resources → increase RAM
2. Remove large models: `docker exec -it ollama ollama rm llama2:70b`
3. Check resource usage: `docker stats`

### n8n Can't Reach Ollama
```bash
# Verify the shared network exists
docker network inspect shared-llm-network

# Test connectivity from inside n8n
docker exec n8n wget -qO- http://ollama:11434/api/tags
```

### Auth / JWT Errors in Supabase
```bash
# Verify keys match the JWT_SECRET
docker exec supabase-auth env | grep JWT

# Regenerate keys if needed
cd supabase-db && node generate-keys.js
```

---

## 🔒 Security Checklist

- [ ] Change `POSTGRES_PASSWORD` in `supabase-db/.env` from the default
- [ ] Change `N8N_BASIC_AUTH_PASSWORD` in `.env` from `changeme`
- [ ] Generate a fresh `JWT_SECRET` and re-run `generate-keys.js`
- [ ] Do not commit `.env` files to version control
- [ ] Use HTTPS (Nginx SSL stack) for any non-localhost deployment
- [ ] Restrict Ollama port `11434` with a firewall in production

---

## 📦 Backup and Restore

```bash
# Backup (creates timestamped folder in ./backups/)
./backup.sh

# List backups
ls -la backups/

# Restore
./restore.sh backups/20260416_120000
```

---

## 🚀 Production Notes

1. Switch n8n from SQLite to PostgreSQL (uncomment the `postgres` service in `docker-compose.yml`)
2. Use the Nginx SSL stack as a reverse proxy with Let's Encrypt certificates
3. Set `ENABLE_SIGNUP=false` in Open WebUI after creating your admin account
4. Implement automated backup scheduling (use `crontab` or a CI/CD pipeline to call `./backup.sh`)
5. Add Prometheus + Grafana for monitoring container health and resource usage

---

## 📚 Resources

- [Ollama Documentation](https://ollama.ai/docs)
- [Ollama Model Library](https://ollama.ai/library)
- [n8n Documentation](https://docs.n8n.io)
- [Supabase Documentation](https://supabase.com/docs)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)
- [Kong Documentation](https://docs.konghq.com)

---

Built with Ollama, n8n, Supabase, Open WebUI, and Kong.
