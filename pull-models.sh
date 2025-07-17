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
