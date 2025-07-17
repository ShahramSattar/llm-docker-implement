# LLM Docker Implementation

A comprehensive AI development environment with two integrated stacks: Ollama/WebUI/n8n for AI capabilities and Supabase for backend services.

## 📁 Project Structure

```
llm-docker-implement/
├── README.md                       # This file
├── docker-compose.yml              # Ollama + WebUI + n8n stack
├── supabase-db/
│   ├── docker-compose.yml          # Supabase stack
│   ├── .env                        # Supabase environment variables
│   ├── .env.example                # Environment template
│   ├── kong.yml                    # Kong API gateway config
│   ├── package.json                # For JWT generation
│   └── generate-keys.js            # JWT key generator
├── .env                            # Main stack environment variables
├── .env.example                    # Main environment template
├── .gitignore                      # Git ignore rules
├── node_modules/                   # Node dependencies
└── package.json                    # Node package file
```

## 🚀 Quick Start

### Prerequisites
- Docker Desktop 4.0+ with Docker Compose v2.0+
- Node.js 16+ (for Supabase JWT generation)
- 16GB RAM minimum (32GB recommended)
- 50GB+ free disk space

### 1. Clone the Repository

```bash
git clone <repository-url>
cd llm-docker-implement
```

### 2. Setup Environment Variables

```bash
# Copy environment templates
cp .env.example .env
cp supabase-db/.env.example supabase-db/.env
```

### 3. Generate Security Keys

#### Generate n8n Encryption Key

**PowerShell (Windows):**
```powershell
# Generate a 32-character random string
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

**Linux/Mac/Git Bash:**
```bash
# Generate using OpenSSL
openssl rand -base64 32
```

Add the generated key to your `.env` file:
```env
N8N_ENCRYPTION_KEY=your-generated-32-character-key-here
```

#### Generate Supabase JWT Keys

```bash
cd supabase-db
npm install
node generate-keys.js
# Copy the generated keys to supabase-db/.env
cd ..
```

### 4. Start the Stacks

You can run the stacks independently or together:

```bash
# Option 1: Start both stacks
docker-compose up -d
cd supabase-db && docker-compose up -d && cd ..

# Option 2: Start only Ollama/WebUI/n8n
docker-compose up -d

# Option 3: Start only Supabase
cd supabase-db && docker-compose up -d && cd ..
```

## 🏗️ Architecture Overview

### Stack 1: Ollama + WebUI + n8n
```
┌─────────────────────────────────────────────────────┐
│                   Open WebUI                         │
│                 (Port 3000)                          │
├─────────────────────────────────────────────────────┤
│        n8n                    │      Ollama          │
│    (Port 5678)                │   (Port 11434)       │
├───────────────────────────────┴──────────────────────┤
│                  PostgreSQL                          │
│                 (Port 5432)                          │
└─────────────────────────────────────────────────────┘
```

### Stack 2: Supabase
```
┌─────────────────────────────────────────────────────┐
│               Supabase Studio                        │
│                 (Port 3000)                          │
├─────────────────────────────────────────────────────┤
│              Kong API Gateway                        │
│                (Port 8000)                           │
├──────────┬──────────┬──────────┬────────────────────┤
│   Auth   │ Realtime │ Storage  │    PostgREST       │
│  (9999)  │  (4000)  │  (5000)  │     (3001)         │
├──────────┴──────────┴──────────┴────────────────────┤
│                PostgreSQL                            │
│               (Port 54324)                           │
└─────────────────────────────────────────────────────┘
```

## 🌐 Service Access Points

### Ollama/WebUI/n8n Stack
| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Open WebUI | http://localhost:3000 | Create on first visit |
| n8n | http://localhost:5678 | admin / (from .env) |
| Ollama API | http://localhost:11434 | No authentication |
| PostgreSQL | localhost:5432 | postgres / (from .env) |

### Supabase Stack
| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Supabase Studio | http://localhost:3000 | No auth (uses service key) |
| Kong API | http://localhost:8000 | API keys from .env |
| Auth API | http://localhost:8000/auth/v1 | - |
| REST API | http://localhost:8000/rest/v1 | - |
| Realtime | ws://localhost:8000/realtime/v1 | - |
| PostgreSQL | localhost:54324 | postgres / (from .env) |

**⚠️ Port Conflict Note**: Both stacks use port 3000. Run them separately or modify the ports in docker-compose.yml files.

## 📖 Usage Guide

### Managing Ollama Models

```bash
# List available models
docker exec -it ollama ollama list

# Pull recommended models
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama

# Remove unused models
docker exec -it ollama ollama rm model-name
```

### Creating n8n Workflows with AI

1. Access n8n at http://localhost:5678
2. Create HTTP Request node:
   - URL: `http://ollama:11434/api/generate`
   - Method: POST
   - Body:
     ```json
     {
       "model": "llama2",
       "prompt": "{{$json.prompt}}",
       "stream": false
     }
     ```

### Integrating with Supabase

```javascript
// Initialize Supabase client
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  'your-anon-key-from-env'
)

// Example: Store AI conversation
async function storeConversation(userPrompt, aiResponse) {
  const { data, error } = await supabase
    .from('conversations')
    .insert({
      user_prompt: userPrompt,
      ai_response: aiResponse,
      model: 'llama2',
      timestamp: new Date()
    })
}
```

## 🛠️ Common Operations

### Starting Services

```bash
# Start Ollama/WebUI/n8n stack
docker-compose up -d

# Start Supabase stack
cd supabase-db && docker-compose up -d && cd ..

# Start specific service
docker-compose up -d ollama
```

### Stopping Services

```bash
# Stop Ollama/WebUI/n8n stack
docker-compose down

# Stop Supabase stack  
cd supabase-db && docker-compose down && cd ..

# Stop everything and remove volumes (careful!)
docker-compose down -v
cd supabase-db && docker-compose down -v && cd ..
```

### Viewing Logs

```bash
# Ollama/WebUI/n8n logs
docker-compose logs -f
docker-compose logs -f ollama
docker-compose logs -f n8n

# Supabase logs
cd supabase-db
docker-compose logs -f
docker-compose logs -f postgres
```

### Health Checks

```bash
# Check Ollama
curl http://localhost:11434/api/tags

# Check n8n
curl http://localhost:5678

# Check Supabase
curl http://localhost:8000/auth/v1/health

# Check all running containers
docker ps
```

## 🔧 Configuration

### Environment Variables

Main stack (`.env`):
```env
# PostgreSQL for n8n
POSTGRES_PASSWORD=your-secure-password

# n8n
N8N_BASIC_AUTH_PASSWORD=your-n8n-password
N8N_ENCRYPTION_KEY=your-32-character-encryption-key

# Open WebUI
WEBUI_SECRET_KEY=your-webui-secret
```

**Generating N8N_ENCRYPTION_KEY:**

PowerShell:
```powershell
# Generate and display a key
Write-Host "N8N_ENCRYPTION_KEY=$(-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_}))" -ForegroundColor Green
```

Bash:
```bash
echo "N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)"
```

**Important**: Once set, don't change the N8N_ENCRYPTION_KEY or you'll lose access to encrypted workflow data!

Supabase stack (`supabase-db/.env`):
```env
# PostgreSQL
POSTGRES_PASSWORD=your-postgres-password

# JWT
JWT_SECRET=your-jwt-secret
ANON_KEY=generated-anon-key
SERVICE_ROLE_KEY=generated-service-role-key
```

### Port Configuration

To avoid port conflicts when running both stacks:

**Option 1**: Run stacks on different ports
```yaml
# In main docker-compose.yml
services:
  open-webui:
    ports:
      - "3001:8080"  # Change from 3000 to 3001
```

**Option 2**: Use different interfaces
```yaml
# In supabase-db/docker-compose.yml
services:
  studio:
    ports:
      - "127.0.0.1:3000:3000"  # Bind to localhost only
```

## 🚨 Troubleshooting

### Port Conflicts

If you get "port already allocated" errors:

```bash
# Find what's using a port (Windows PowerShell)
netstat -ano | findstr :3000

# Kill the process using the port
taskkill /PID <process-id> /F

# Or change the port in docker-compose.yml
```

### Memory Issues

If services are slow or crashing:

1. Increase Docker Desktop memory (Settings → Resources)
2. Limit Ollama models loaded:
   ```bash
   docker exec -it ollama ollama rm large-model
   ```

### Connection Issues Between Stacks

Since the stacks use different networks, to connect them:

1. Create a shared network:
   ```bash
   docker network create shared-network
   ```

2. Add to both docker-compose files:
   ```yaml
   networks:
     shared-network:
       external: true
   ```

3. Add services to the shared network:
   ```yaml
   services:
     ollama:
       networks:
         - app-network
         - shared-network
   ```

## 🔒 Security Recommendations

1. **Change all default passwords** before using in production
2. **Generate new JWT keys** for Supabase
3. **Use environment variables** for all sensitive data
4. **Don't commit .env files** to version control
5. **Enable firewalls** to restrict port access
6. **Use HTTPS** in production with a reverse proxy

## 📦 Backup and Restore

### Backup All Data

```bash
#!/bin/bash
# backup-all.sh

# Create backup directory
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

# Backup Ollama models
docker run --rm -v ollama_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine tar czf /backup/ollama-models.tar.gz -C /data .

# Backup n8n data
docker exec postgres pg_dump -U postgres > $BACKUP_DIR/n8n-postgres.sql

# Backup Supabase
cd supabase-db
docker exec supabase-postgres pg_dump -U postgres > ../$BACKUP_DIR/supabase-postgres.sql
cd ..

echo "Backup completed to $BACKUP_DIR"
```

### Restore Data

```bash
#!/bin/bash
# restore.sh

BACKUP_DIR=$1

# Restore n8n database
docker exec -i postgres psql -U postgres < $BACKUP_DIR/n8n-postgres.sql

# Restore Supabase database
cd supabase-db
docker exec -i supabase-postgres psql -U postgres < ../$BACKUP_DIR/supabase-postgres.sql
cd ..

echo "Restore completed from $BACKUP_DIR"
```

## 🚀 Production Deployment

For production deployment:

1. Use separate servers for each stack
2. Implement proper SSL/TLS with reverse proxy
3. Use managed databases instead of Docker PostgreSQL
4. Enable monitoring and alerting
5. Implement backup automation
6. Use container orchestration (Kubernetes/Swarm)

## 📚 Additional Resources

- [Ollama Documentation](https://ollama.ai/docs)
- [n8n Documentation](https://docs.n8n.io)
- [Supabase Documentation](https://supabase.io/docs)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

Built with ❤️ using Ollama, n8n, Supabase, and Open WebUI