# Ollama + Open WebUI + n8n Stack

A powerful AI development stack combining local LLM inference (Ollama), a modern chat interface (Open WebUI), and workflow automation (n8n) with PostgreSQL database.

## 🎯 What This Stack Provides

- **Run LLMs locally** without cloud dependencies
- **ChatGPT-like interface** for interacting with models
- **Automate AI workflows** with visual programming
- **Persistent storage** for conversations and workflows
- **API access** for custom integrations

## 📋 Prerequisites

- Docker Desktop 4.0+ with Docker Compose
- 16GB RAM minimum (32GB recommended for larger models)
- 20GB+ free disk space for models
- NVIDIA GPU (optional, for acceleration)

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd ollama-webui-n8n

# Create environment file
cp .env.example .env
```

### 2. Configure Environment

Edit `.env` file:

```env
# PostgreSQL
POSTGRES_PASSWORD=your-secure-password

# n8n
N8N_BASIC_AUTH_PASSWORD=your-n8n-password
N8N_ENCRYPTION_KEY=your-32-character-encryption-key

# Open WebUI
WEBUI_SECRET_KEY=your-webui-secret
```

**Generating Secure Keys:**

For `N8N_ENCRYPTION_KEY` (must be at least 32 characters):

PowerShell:
```powershell
# Generate a 32-character key
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

Linux/Mac/Git Bash:
```bash
# Generate using OpenSSL
openssl rand -base64 32
```

**Important**: The N8N_ENCRYPTION_KEY is used to encrypt sensitive data in workflows (credentials, etc.). Once set, don't change it or you'll lose access to encrypted data!

### 3. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Pull AI Models

```bash
# Pull recommended models
docker exec -it ollama ollama pull llama2
docker exec -it ollama ollama pull mistral
docker exec -it ollama ollama pull codellama

# List available models
docker exec -it ollama ollama list
```

## 🌐 Access Points

| Service | URL | Credentials | Purpose |
|---------|-----|------------|---------|
| Open WebUI | http://localhost:3000 | Create on first visit | Chat with AI models |
| n8n | http://localhost:5678 | admin / (your password) | Workflow automation |
| Ollama API | http://localhost:11434 | No auth | Direct API access |
| PostgreSQL | localhost:5432 | postgres / (your password) | Database access |

## 📖 Service Guide

### Ollama - LLM Backend

Ollama provides the AI inference engine for running large language models locally.

#### Available Models

| Model | Size | Use Case | Pull Command |
|-------|------|----------|--------------|
| llama2 | 7B | General purpose | `ollama pull llama2` |
| mistral | 7B | Fast, efficient | `ollama pull mistral` |
| codellama | 7B | Code generation | `ollama pull codellama` |
| phi | 2.7B | Lightweight | `ollama pull phi` |
| neural-chat | 7B | Conversational | `ollama pull neural-chat` |
| llama2:13b | 13B | Better quality | `ollama pull llama2:13b` |
| llama2:70b | 70B | Best quality | `ollama pull llama2:70b` |

#### API Usage

```bash
# Generate text
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "prompt": "Write a haiku about Docker",
    "stream": false
  }'

# Chat completion
curl -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama2",
    "messages": [
      {"role": "user", "content": "Hello!"}
    ]
  }'
```

#### Python Example

```python
import requests
import json

def query_ollama(prompt, model="llama2"):
    response = requests.post(
        "http://localhost:11434/api/generate",
        json={
            "model": model,
            "prompt": prompt,
            "stream": False
        }
    )
    return response.json()["response"]

# Example usage
result = query_ollama("Explain Docker in simple terms")
print(result)
```

### Open WebUI - Chat Interface

A feature-rich web interface for interacting with Ollama models.

#### Features

- 💬 **Multiple Conversations**: Organize chats in folders
- 🎨 **Custom Prompts**: Save and reuse system prompts
- 📎 **File Upload**: Process documents and images (with compatible models)
- 🔍 **Search**: Find past conversations
- 👥 **Multi-user**: Support for multiple users
- 🌙 **Dark Mode**: Easy on the eyes
- 📱 **Responsive**: Works on mobile devices

#### First Time Setup

1. Navigate to http://localhost:3000
2. Click "Sign Up" to create admin account
3. First user automatically becomes admin
4. Configure available models in Settings

#### Advanced Configuration

```yaml
# docker-compose.yml
environment:
  - ENABLE_SIGNUP=false  # Disable after creating accounts
  - DEFAULT_MODELS=llama2,mistral  # Set default models
  - WEBUI_AUTH=true  # Enable authentication
```

### n8n - Workflow Automation

Create powerful AI-powered automation workflows with visual programming.

#### Ollama Integration in n8n

1. **HTTP Request Node Configuration**:
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

2. **Example Workflows**:

##### Email Assistant
```
[Gmail Trigger] → [Ollama: Analyze] → [Ollama: Generate Response] → [Gmail: Send]
```

##### Content Generator
```
[Schedule Trigger] → [RSS Feed] → [Ollama: Summarize] → [Wordpress: Post]
```

##### Code Review Bot
```
[GitHub Webhook] → [Ollama: Review Code] → [GitHub: Comment]
```

#### n8n Workflow Examples

##### Customer Support Bot
```json
{
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "support",
        "responseMode": "onReceived"
      }
    },
    {
      "name": "Analyze Intent",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://ollama:11434/api/generate",
        "method": "POST",
        "body": {
          "model": "llama2",
          "prompt": "Classify this support ticket: {{$json.message}}",
          "system": "You are a support ticket classifier. Respond with one of: technical, billing, general"
        }
      }
    }
  ]
}
```

### PostgreSQL Database

Stores data for n8n workflows and Open WebUI conversations.

#### Access Database

```bash
# Connect via CLI
docker exec -it postgres psql -U postgres

# Common queries
\l  # List databases
\dt # List tables
\q  # Quit
```

#### Backup & Restore

```bash
# Backup
docker exec postgres pg_dump -U postgres n8n > backup.sql

# Restore
docker exec -i postgres psql -U postgres n8n < backup.sql
```

## 🛠️ Configuration

### GPU Support (NVIDIA)

Enable GPU acceleration for faster inference:

```yaml
# docker-compose.yml
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

### Memory Optimization

```yaml
# Adjust based on your system
services:
  ollama:
    environment:
      - OLLAMA_NUM_PARALLEL=2  # Parallel requests
      - OLLAMA_MAX_LOADED_MODELS=2  # Models in memory
      - OLLAMA_MEMORY_LIMIT=8GB  # Memory per model
```

### Custom Models

```bash
# Import GGUF models
docker cp ./my-model.gguf ollama:/root/.ollama/models/

# Create from Modelfile
docker exec -it ollama bash
cat > Modelfile << EOF
FROM llama2
SYSTEM You are a helpful coding assistant.
PARAMETER temperature 0.2
EOF
ollama create code-assistant -f Modelfile
```

## 📊 Monitoring & Performance

### Resource Usage

```bash
# Monitor container resources
docker stats

# Check model memory usage
docker exec ollama ps aux | grep ollama
```

### Performance Tuning

1. **Model Selection**:
   - Smaller models (phi, mistral) for speed
   - Larger models (llama2:13b) for quality

2. **Batch Processing**:
   ```javascript
   // Process multiple prompts efficiently
   const batchProcess = async (prompts) => {
     return Promise.all(prompts.map(p => queryOllama(p)))
   }
   ```

3. **Caching**:
   - n8n caches workflow results
   - Implement Redis for custom caching

## 🚨 Troubleshooting

### Common Issues

#### 1. Model Won't Load
```bash
# Check available space
docker exec ollama df -h

# Clear unused models
docker exec ollama ollama rm unused-model

# Restart Ollama
docker-compose restart ollama
```

#### 2. Slow Response Times
- Reduce model size (use 7B instead of 13B)
- Enable GPU acceleration
- Increase memory allocation
- Use quantized models

#### 3. n8n Can't Connect to Ollama
```bash
# Test connection
docker exec n8n curl http://ollama:11434/api/tags

# Check network
docker network ls
docker network inspect ollama-webui-n8n_app-network
```

#### 4. Database Issues
```bash
# Reset n8n database
docker-compose stop n8n
docker exec postgres psql -U postgres -c "DROP DATABASE n8n;"
docker exec postgres psql -U postgres -c "CREATE DATABASE n8n;"
docker-compose start n8n
```

### Debug Commands

```bash
# Ollama logs
docker logs ollama --tail 100 -f

# Test model
docker exec -it ollama ollama run llama2 "test"

# n8n logs
docker logs n8n --tail 100 -f

# WebUI logs
docker logs open-webui --tail 100 -f
```

## 🔧 Advanced Usage

### Custom API Endpoints

Create a simple API server that uses Ollama:

```python
# api_server.py
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

@app.route('/api/complete', methods=['POST'])
def complete():
    data = request.json
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': data.get('model', 'llama2'),
            'prompt': data['prompt'],
            'stream': False
        }
    )
    return jsonify(response.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Integrate with Your Application

```javascript
// Node.js example
const axios = require('axios');

class OllamaClient {
  constructor(baseURL = 'http://localhost:11434') {
    this.baseURL = baseURL;
  }

  async generate(prompt, model = 'llama2') {
    const response = await axios.post(`${this.baseURL}/api/generate`, {
      model,
      prompt,
      stream: false
    });
    return response.data.response;
  }

  async chat(messages, model = 'llama2') {
    const response = await axios.post(`${this.baseURL}/api/chat`, {
      model,
      messages,
      stream: false
    });
    return response.data.message;
  }
}

// Usage
const ollama = new OllamaClient();
const response = await ollama.generate('Write a function to sort an array');
```

## 📚 Best Practices

1. **Model Selection**:
   - Use smaller models for real-time applications
   - Use larger models for quality-critical tasks
   - Test different models for your use case

2. **Prompt Engineering**:
   - Be specific and clear
   - Use system prompts for consistent behavior
   - Include examples for better results

3. **Resource Management**:
   - Unload models when not in use
   - Monitor memory usage
   - Use model quantization for efficiency

4. **Security**:
   - Don't expose Ollama directly to internet
   - Use API keys for n8n webhooks
   - Sanitize user inputs

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Additional Resources

- [Ollama Documentation](https://github.com/jmorganca/ollama/blob/main/docs/README.md)
- [Ollama Model Library](https://ollama.ai/library)
- [n8n Documentation](https://docs.n8n.io)
- [n8n Community Workflows](https://n8n.io/workflows)
- [Open WebUI GitHub](https://github.com/open-webui/open-webui)

---

Happy AI Development! 🚀