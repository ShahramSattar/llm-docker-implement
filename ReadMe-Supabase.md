# Supabase Local Development Stack

A complete self-hosted Supabase setup with PostgreSQL, authentication, realtime subscriptions, storage, and management studio.

## 🎯 What is Supabase?

Supabase is an open-source Firebase alternative providing:
- **PostgreSQL Database** — Full Postgres with extensions
- **Authentication** — Email/password, OAuth, magic links
- **Realtime** — WebSocket-based change subscriptions
- **Storage** — S3-compatible object storage
- **Auto-generated APIs** — Instant REST API via PostgREST
- **Management Studio** — Web UI for database and auth management

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Supabase Studio                        │
│                    (Port 3000)                           │
├─────────────────────────────────────────────────────────┤
│                   Kong API Gateway                       │
│                    (Port 8000)                           │
├────────────┬─────────────┬──────────────┬───────────────┤
│    Auth    │   Storage   │   Realtime   │   PostgREST   │
│   (9999)   │   (5000)    │    (4000)    │    (3001)     │
├────────────┴─────────────┴──────────────┴───────────────┤
│                     PostgreSQL                           │
│                    (Port 5432)                           │
└─────────────────────────────────────────────────────────┘
          ↕ shared-llm-network ↕
```

The stack joins `shared-llm-network` so n8n and other services in the main LLM stack can reach Supabase APIs by container hostname.

## 📦 Image Versions

| Service | Image | Version |
|---------|-------|---------|
| PostgreSQL | `supabase/postgres` | `15.8.1.085` |
| Studio | `supabase/studio` | `2026.04.08-sha-205cbe7` |
| Kong | `kong` | `3.9.1` |
| Auth (GoTrue) | `supabase/gotrue` | `v2.186.0` |
| Realtime | `supabase/realtime` | `v2.76.5` |
| Storage API | `supabase/storage-api` | `v1.37.8` |
| Postgres Meta | `supabase/postgres-meta` | `v0.95.2` |
| PostgREST | `postgrest/postgrest` | `v12.2.0` |

## 📋 Prerequisites

- Docker Desktop 4.0+
- Docker Compose v2.0+
- Node.js 18+ (for JWT generation)
- 4 GB RAM minimum
- 5 GB free disk space

## 🚀 Quick Start

### 1. Setup Directory

```bash
cd supabase-db
```

### 2. Generate JWT Keys

```bash
npm install
node generate-keys.js
```

Copy the output into `.env`.

### 3. Configure Environment

Edit `supabase-db/.env`:

```env
# Use: openssl rand -base64 16
POSTGRES_PASSWORD=your-strong-password

# Use: openssl rand -base64 64
JWT_SECRET=your-64-char-secret

# From generate-keys.js output
ANON_KEY=generated-anon-key
SERVICE_ROLE_KEY=generated-service-role-key
```

### 4. Start Supabase

```bash
# If using start-all.sh from the root (recommended — creates shared network automatically):
cd .. && ./start-all.sh

# Or start just Supabase (create the shared network first):
docker network create shared-llm-network 2>/dev/null || true
docker compose up -d
```

## 🌐 Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| Studio | http://localhost:3000 | Database management UI |
| API Gateway | http://localhost:8000 | Client API endpoint |
| Auth API | http://localhost:8000/auth/v1 | Authentication endpoints |
| REST API | http://localhost:8000/rest/v1 | Database REST API |
| Realtime | ws://localhost:8000/realtime/v1 | WebSocket subscriptions |
| Storage | http://localhost:8000/storage/v1 | File storage API |

## 📖 Core Features Guide

### 1. Database Management

Access Supabase Studio at http://localhost:3000.

#### Create Tables via SQL:
```sql
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read" ON posts FOR SELECT USING (true);

CREATE POLICY "Owner write" ON posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 2. Authentication

#### Client Setup (JavaScript/TypeScript):

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  process.env.ANON_KEY
)
```

#### Sign Up / Sign In:
```javascript
// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password'
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'secure-password'
})

// OAuth (Google)
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google'
})

// Magic link
const { error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com'
})
```

### 3. Database Operations

```javascript
// Insert
const { data, error } = await supabase
  .from('posts')
  .insert([{ title: 'Hello World', content: 'My first post' }])
  .select()

// Query with filters
const { data, error } = await supabase
  .from('posts')
  .select('title, content')
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
  .limit(10)

// Update
const { data, error } = await supabase
  .from('posts')
  .update({ title: 'Updated Title' })
  .eq('id', postId)
  .select()

// Delete
const { error } = await supabase
  .from('posts')
  .delete()
  .eq('id', postId)
```

### 4. Realtime Subscriptions

```javascript
// Subscribe to all changes on a table (Supabase v2 API)
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => console.log('Change received:', payload)
  )
  .subscribe()

// Subscribe to inserts only
const insertChannel = supabase
  .channel('posts-inserts')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'posts' },
    (payload) => console.log('New post:', payload.new)
  )
  .subscribe()

// Unsubscribe
await supabase.removeChannel(channel)
```

### 5. Storage

```javascript
// Create a bucket
await supabase.storage.createBucket('avatars', {
  public: true,
  fileSizeLimit: 2 * 1024 * 1024  // 2 MB
})

// Upload a file
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`public/${userId}/avatar.jpg`, file, { upsert: true })

// Get public URL
const { data } = supabase.storage
  .from('avatars')
  .getPublicUrl(`public/${userId}/avatar.jpg`)
```

### 6. Row Level Security (RLS)

```sql
-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Public posts are viewable by everyone"
  ON posts FOR SELECT USING (is_public = true);

-- Authenticated users manage their own rows
CREATE POLICY "Users can CRUD their own posts"
  ON posts FOR ALL USING (auth.uid() = user_id);

-- Role-based access
CREATE POLICY "Admins can do anything"
  ON posts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid() AND role = 'admin'
    )
  );
```

## 🛠️ Advanced Configuration

### PostgreSQL Extensions

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "vector";  -- for AI embeddings
```

### Email (SMTP) Configuration

Add to `supabase-db/.env`:
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
SMTP_ADMIN_EMAIL=admin@example.com
ENABLE_EMAIL_AUTOCONFIRM=false
```

### OAuth Providers

```env
# Google
ENABLE_GOOGLE_OAUTH=true
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret

# GitHub
ENABLE_GITHUB_OAUTH=true
GITHUB_CLIENT_ID=your-client-id
GITHUB_CLIENT_SECRET=your-client-secret
```

### S3 Storage Backend

```env
STORAGE_BACKEND=s3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_S3_BUCKET=your-bucket
```

## 📊 Monitoring & Maintenance

### Useful Database Queries

```sql
-- Database size
SELECT pg_size_pretty(pg_database_size('postgres'));

-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Largest tables
SELECT schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;

-- Slow queries (requires pg_stat_statements)
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### Service Health Checks

```bash
# All services status
docker compose ps

# API health
curl http://localhost:8000/auth/v1/health
curl http://localhost:8000/rest/v1/
```

### Backup & Restore

```bash
# Backup database
docker exec supabase-postgres pg_dump -U postgres > backup_$(date +%Y%m%d).sql

# Backup specific schema
docker exec supabase-postgres pg_dump -U postgres --schema=public > public_schema.sql

# Restore
docker exec -i supabase-postgres psql -U postgres < backup.sql
```

## 🚨 Troubleshooting

### Studio Can't Connect
```bash
docker logs supabase-postgres-meta
docker compose restart postgres postgres-meta studio
```

### Auth Service Errors
```bash
# Check JWT config
docker exec supabase-auth env | grep JWT

# Regenerate keys if JWT_SECRET was changed
cd supabase-db && node generate-keys.js
```

### Realtime Not Working
```bash
docker logs supabase-realtime

# Check replication slot exists
docker exec supabase-postgres psql -U postgres \
  -c "SELECT * FROM pg_replication_slots;"
```

### Kong Config Not Loading
```bash
docker logs supabase-kong

# Validate declarative config
docker exec supabase-kong kong config parse /var/lib/kong/kong.yml
```

### Full Reset (deletes all data)
```bash
docker compose down -v
docker compose up -d
```

## 🔒 Security Best Practices

1. **Generate fresh JWT keys** — never use the default demo keys in `.env.example`
2. **Strong Postgres password** — `openssl rand -base64 16`
3. **Enable RLS** on all tables that store user data
4. **Use service role key only server-side** — never expose it in frontend code
5. **Enable HTTPS** via the Nginx SSL stack for any non-localhost deployment
6. **Restrict port 5432** — PostgreSQL should not be exposed publicly

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase JS Client (v2)](https://supabase.com/docs/reference/javascript)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgREST Documentation](https://postgrest.org/)
- [Kong 3.x Documentation](https://docs.konghq.com/gateway/3.9.x/)

---

Built with Supabase, PostgreSQL, Kong, and PostgREST.
