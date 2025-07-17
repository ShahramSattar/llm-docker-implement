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
