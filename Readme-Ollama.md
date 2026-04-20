# Ollama + Open WebUI + n8n Stack

A powerful AI development stack combining local LLM inference (Ollama), a modern chat interface (Open WebUI), and workflow automation (n8n).

## 🎯 What This Stack Provides

- **Run LLMs locally** without cloud dependencies
- **ChatGPT-like interface** for interacting with models
- **Automate AI workflows** with visual programming
- **API access** for custom integrations
- **Cross-stack connectivity** to Supabase via shared Docker network

## 📋 Prerequisites

- Docker Desktop 4.0+ with Docker Compose v2.0+
- 16 GB RAM minimum (32 GB recommended for larger models)
- 20 GB+ free disk space for models
- NVIDIA GPU (optional, for acceleration)

## 📦 Image Versions

| Service | Image | Version |
|---------|-------|---------|
| Ollama | `ollama/ollama` | `0.20.7` |
| Open WebUI | `ghcr.io/open-webui/open-webui` | `v0.8.6` |
| n8n | `n8nio/n8n` | `2.14.1` |

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd llm-docker-implement
cp .env.example .env
```

### 2. Configure Environment

Edit `.env`:

```env
# IMPORTANT: Generate once and never change — losing this breaks encrypted workflow data
N8N_ENCRYPTION_KEY=your-32-char-key

# n8n web UI login (username: admin)
N8N_BASIC_AUTH_PASSWORD=choose-a-strong-password

# Open WebUI session secret
WEBUI_SECRET_KEY=your-webui-secret
```

**Generate `N8N_ENCRYPTION_KEY`:**

PowerShell:
```powershell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

Bash / Git Bash:
```bash
openssl rand -base64 32
```

### 3. Start Services

```bash
# From the project root (creates shared network automatically):
./start-all.sh

# Or start only this stack:
docker network create shared-llm-network 2>/dev/null || true
docker compose up -d
```

### 4. Pull AI Models

```bash
# Individual models
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama

# Or use the helper script (pulls several at once)
./pull-models.sh

# List installed models
docker exec -it ollama ollama list
```

## 🌐 Access Points

| Service | URL | Credentials |
|---------|-----|-------------|
| Open WebUI | http://localhost:3002 | Create on first visit (first user = admin) |
| n8n | http://localhost:5678 | admin / (from `.env`) |
| Ollama API | http://localhost:11434 | No auth |

## 📖 Service Guide

### Ollama — LLM Backend

Ollama manages model downloads, quantization, and inference. It exposes an OpenAI-compatible HTTP API.

#### Recommended Models

| Model | Size | Best For |
|-------|------|----------|
| `llama2` | 7B | General purpose |
| `mistral` | 7B | Fast, efficient |
| `codellama` | 7B | Code generation |
| `phi` | 2.7B | Lightweight / low RAM |
| `llama2:13b` | 13B | Higher quality output |

#### API Usage

```bash
# Generate text
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama2", "prompt": "Write a haiku about Docker", "stream": false}'

# Chat completion
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

#### Python Example

```python
import requests

def query_ollama(prompt, model="llama2"):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={"model": model, "prompt": prompt, "stream": False}
    )
    return response.json()["response"]

print(query_ollama("Explain Docker in simple terms"))
```

### Open WebUI — Chat Interface

A full-featured chat UI accessible at http://localhost:3002.

**First-time setup:**
1. Navigate to http://localhost:3002
2. Click "Sign Up" — the first account automatically becomes admin
3. Select a model from the model dropdown

**Useful environment variables (in `docker-compose.yml`):**
```yaml
- ENABLE_SIGNUP=false      # Disable after creating your admin account
- DEFAULT_MODELS=llama2    # Pre-select a model
```

### n8n — Workflow Automation

Visual workflow editor for AI-powered automation at http://localhost:5678.

n8n uses **SQLite by default** for its database (stored in the `n8n_data` volume). For production, uncomment the `postgres` service in `docker-compose.yml` and set `DB_TYPE=postgresdb`.

#### Call Ollama from n8n

Add an **HTTP Request** node:
- URL: `http://ollama:11434/api/generate`
- Method: `POST`
- Body:
  ```json
  {
    "model": "llama2",
    "prompt": "{{ $json.prompt }}",
    "stream": false
  }
  ```

#### Example Workflows

```
Email Assistant:
[Gmail Trigger] → [Ollama: Analyze] → [Ollama: Draft Reply] → [Gmail: Send]

Content Generator:
[Schedule] → [RSS Feed] → [Ollama: Summarize] → [Wordpress: Post]

Code Review Bot:
[GitHub Webhook] → [Ollama: Review Code] → [GitHub: Comment]
```

## 🛠️ Configuration

### GPU Support (NVIDIA)

Uncomment the `deploy` block in `docker-compose.yml` for the `ollama` service:

```yaml
services:
  ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

Also ensure the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) is installed.

### Memory Tuning

```yaml
# In docker-compose.yml, under ollama environment:
- OLLAMA_NUM_PARALLEL=2        # Parallel inference requests
- OLLAMA_MAX_LOADED_MODELS=2   # Models kept in VRAM simultaneously
```

The `ollama` container has a `mem_limit: 8g` by default. Adjust in `docker-compose.yml` to match your system.

### Custom / Imported Models

```bash
# Create a custom model from a Modelfile
docker exec -it ollama bash
cat > Modelfile << 'EOF'
FROM mistral
SYSTEM You are a helpful coding assistant specializing in Python.
PARAMETER temperature 0.2
EOF
ollama create python-assistant -f Modelfile
```

### Switching n8n to PostgreSQL

1. Uncomment the `postgres` service in `docker-compose.yml`
2. Set `N8N_POSTGRES_PASSWORD` in `.env`
3. Update n8n environment variables:
   ```yaml
   - DB_TYPE=postgresdb
   - DB_POSTGRESDB_HOST=postgres
   - DB_POSTGRESDB_DATABASE=n8n
   - DB_POSTGRESDB_USER=n8n
   - DB_POSTGRESDB_PASSWORD=${N8N_POSTGRES_PASSWORD}
   ```

## 📊 Monitoring & Performance

```bash
# Live resource usage for all containers
docker stats

# Check Ollama model memory
docker exec ollama ps aux | grep ollama

# Check available disk space inside Ollama
docker exec ollama df -h
```

## 🚨 Troubleshooting

### Model Won't Load
```bash
# Check disk space
docker exec ollama df -h

# Remove unused models to free space
docker exec ollama ollama rm large-model

# Restart Ollama
docker compose restart ollama
```

### Slow Response Times
- Use a smaller model (7B instead of 13B)
- Enable GPU acceleration
- Increase Docker Desktop memory in Settings → Resources
- Use a quantized model variant (e.g. `mistral:7b-q4_0`)

### n8n Can't Reach Ollama
```bash
# Test from inside the n8n container
docker exec n8n wget -qO- http://ollama:11434/api/tags

# Verify the shared network exists and both containers are on it
docker network inspect shared-llm-network
```

### Reset n8n Data (SQLite)
```bash
docker compose stop n8n
docker volume rm llm-docker-implement_n8n_data
docker compose start n8n
```

### Debug Logs
```bash
docker logs ollama --tail 100 -f
docker logs n8n --tail 100 -f
docker logs open-webui --tail 100 -f
```

## 🔧 Advanced Usage

### Node.js Client

```javascript
const axios = require('axios')

class OllamaClient {
  constructor(baseURL = 'http://localhost:11434') {
    this.baseURL = baseURL
  }

  async generate(prompt, model = 'llama2') {
    const { data } = await axios.post(`${this.baseURL}/api/generate`, {
      model, prompt, stream: false
    })
    return data.response
  }

  async chat(messages, model = 'llama2') {
    const { data } = await axios.post(`${this.baseURL}/api/chat`, {
      model, messages, stream: false
    })
    return data.message
  }
}

const ollama = new OllamaClient()
const result = await ollama.generate('Write a function to sort an array in Python')
```

## 📚 Resources

- [Ollama Documentation](https://github.com/ollama/ollama/blob/main/docs/README.md)
- [Ollama Model Library](https://ollama.ai/library)
- [Ollama API Reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [n8n Documentation](https://docs.n8n.io)
- [n8n Community Workflows](https://n8n.io/workflows)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)

---

Happy AI Development!
