# Supabase Local Development Stack

A complete local Supabase setup with PostgreSQL, authentication, realtime subscriptions, storage, and management studio.

## 🎯 What is Supabase?

Supabase is an open-source Firebase alternative that provides:
- **PostgreSQL Database** - Full Postgres with extensions
- **Authentication** - Email/password, OAuth, magic links
- **Realtime** - WebSocket-based subscriptions
- **Storage** - S3-compatible object storage
- **Auto-generated APIs** - Instant REST and GraphQL APIs
- **Edge Functions** - Deploy serverless functions

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
│                    (Port 54324)                          │
└─────────────────────────────────────────────────────────┘
```

## 📋 Prerequisites

- Docker Desktop 4.0+
- Docker Compose v2.0+
- Node.js 16+ (for JWT generation)
- 4GB RAM minimum
- 5GB free disk space

## 🚀 Quick Start

### 1. Setup Directory

```bash
cd supabase
```

### 2. Generate JWT Keys

```bash
# Install dependencies
npm install

# Generate keys (make sure JWT_SECRET in .env matches)
node generate-keys.js
```

### 3. Configure Environment

Edit `.env` file with generated keys:

```env
# Database
POSTGRES_PASSWORD=your-secure-password

# JWT Configuration  
JWT_SECRET=your-64-character-secret

# Keys from generate-keys.js output
ANON_KEY=generated-anon-key
SERVICE_ROLE_KEY=generated-service-role-key
```

### 4. Start Supabase

```bash
# Start all services
docker-compose up -d

# Check health
docker-compose ps

# View logs
docker-compose logs -f
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

Access Supabase Studio at http://localhost:3000

#### Create Tables via UI:
1. Navigate to Table Editor
2. Click "New Table"
3. Define columns and relationships
4. Enable Row Level Security (RLS)

#### Create Tables via SQL:
```sql
-- Create a posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT,
  user_id UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Create policy
CREATE POLICY "Users can view all posts" 
  ON posts FOR SELECT 
  USING (true);

CREATE POLICY "Users can create their own posts" 
  ON posts FOR INSERT 
  WITH CHECK (auth.uid() = user_id);
```

### 2. Authentication

#### JavaScript/TypeScript Setup:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  'your-anon-key'
)
```

#### Sign Up:
```javascript
const { user, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password'
})
```

#### Sign In:
```javascript
const { user, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'secure-password'
})
```

#### OAuth (Google):
```javascript
const { user, error } = await supabase.auth.signInWithOAuth({
  provider: 'google'
})
```

#### Magic Link:
```javascript
const { error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com'
})
```

### 3. Database Operations

#### Insert Data:
```javascript
const { data, error } = await supabase
  .from('posts')
  .insert([
    { title: 'Hello World', content: 'My first post' }
  ])
  .select()
```

#### Query Data:
```javascript
// Simple query
const { data, error } = await supabase
  .from('posts')
  .select('*')

// With filters
const { data, error } = await supabase
  .from('posts')
  .select('title, content')
  .eq('user_id', userId)
  .order('created_at', { ascending: false })
  .limit(10)

// With joins
const { data, error } = await supabase
  .from('posts')
  .select(`
    *,
    author:user_id (
      id,
      email,
      profile (
        username,
        avatar_url
      )
    )
  `)
```

#### Update Data:
```javascript
const { data, error } = await supabase
  .from('posts')
  .update({ title: 'Updated Title' })
  .eq('id', postId)
  .select()
```

#### Delete Data:
```javascript
const { error } = await supabase
  .from('posts')
  .delete()
  .eq('id', postId)
```

### 4. Realtime Subscriptions

#### Subscribe to Changes:
```javascript
// Subscribe to all changes
const subscription = supabase
  .from('posts')
  .on('*', payload => {
    console.log('Change received!', payload)
  })
  .subscribe()

// Subscribe to specific events
const insertSubscription = supabase
  .from('posts')
  .on('INSERT', payload => {
    console.log('New post:', payload.new)
  })
  .subscribe()

// Subscribe with filters
const userPostsSubscription = supabase
  .from('posts:user_id=eq.${userId}')
  .on('UPDATE', payload => {
    console.log('Post updated:', payload.new)
  })
  .subscribe()

// Unsubscribe
subscription.unsubscribe()
```

### 5. Storage

#### Create Buckets:
```javascript
const { data, error } = await supabase
  .storage
  .createBucket('avatars', {
    public: true,
    fileSizeLimit: 1024 * 1024 * 2 // 2MB
  })
```

#### Upload Files:
```javascript
const { data, error } = await supabase
  .storage
  .from('avatars')
  .upload(`public/${userId}/avatar.jpg`, file, {
    cacheControl: '3600',
    upsert: true
  })
```

#### Download Files:
```javascript
const { data, error } = await supabase
  .storage
  .from('avatars')
  .download(`public/${userId}/avatar.jpg`)
```

#### Get Public URL:
```javascript
const { data } = supabase
  .storage
  .from('avatars')
  .getPublicUrl(`public/${userId}/avatar.jpg`)
```

### 6. Row Level Security (RLS)

#### Enable RLS:
```sql
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
```

#### Create Policies:
```sql
-- Public read access
CREATE POLICY "Public posts are viewable by everyone"
  ON posts FOR SELECT
  USING (is_public = true);

-- Authenticated user access
CREATE POLICY "Users can CRUD their own posts"
  ON posts FOR ALL
  USING (auth.uid() = user_id);

-- Role-based access
CREATE POLICY "Admins can do anything"
  ON posts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'admin'
    )
  );
```

## 🛠️ Advanced Configuration

### Custom PostgreSQL Extensions

Add extensions via SQL:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "vector";
```

### Email Configuration

Configure SMTP in `.env`:
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
SMTP_ADMIN_EMAIL=admin@example.com
ENABLE_EMAIL_AUTOCONFIRM=false
```

### OAuth Configuration

Enable OAuth providers:
```env
# Google OAuth
ENABLE_GOOGLE_OAUTH=true
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret

# GitHub OAuth
ENABLE_GITHUB_OAUTH=true
GITHUB_CLIENT_ID=your-client-id
GITHUB_CLIENT_SECRET=your-client-secret
```

### Storage Backends

Configure S3 storage:
```env
STORAGE_BACKEND=s3
AWS_ACCESS_KEY_ID=your-key
AWS_SECRET_ACCESS_KEY=your-secret
AWS_DEFAULT_REGION=us-east-1
AWS_S3_BUCKET=your-bucket
```

## 📊 Monitoring & Maintenance

### Database Monitoring

```sql
-- Check database size
SELECT pg_database_size('postgres');

-- Active connections
SELECT count(*) FROM pg_stat_activity;

-- Table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Slow queries
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### Service Health Checks

```bash
# Check all services
docker-compose ps

# Test endpoints
curl http://localhost:8000/auth/v1/health
curl http://localhost:8000/rest/v1/
curl http://localhost:3001/ # Direct PostgREST
```

### Backup & Restore

```bash
# Backup database
docker exec supabase-postgres pg_dump -U postgres > backup_$(date +%Y%m%d).sql

# Backup with data only
docker exec supabase-postgres pg_dump -U postgres --data-only > data_backup.sql

# Backup specific schema
docker exec supabase-postgres pg_dump -U postgres --schema=public > public_schema.sql

# Restore
docker exec -i supabase-postgres psql -U postgres < backup.sql
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Studio Can't Connect
```bash
# Check Meta service
docker logs supabase-postgres-meta

# Restart services
docker-compose restart postgres postgres-meta studio
```

#### 2. Auth Service Errors
```bash
# Check JWT configuration
docker exec supabase-auth env | grep JWT

# Verify database connection
docker exec supabase-auth nc -zv postgres 5432
```

#### 3. Realtime Not Working
```bash
# Check realtime logs
docker logs supabase-realtime

# Verify replication slot
docker exec supabase-postgres psql -U postgres -c "SELECT * FROM pg_replication_slots;"
```

#### 4. Storage Issues
```bash
# Check storage logs
docker logs supabase-storage

# Verify storage directory
docker exec supabase-storage ls -la /var/lib/storage
```

### Reset Everything

```bash
# Complete reset (WARNING: Deletes all data)
docker-compose down -v
docker-compose up -d
```

## 🔒 Security Best Practices

1. **Change Default Keys**: Always generate new JWT keys for production
2. **Enable RLS**: Use Row Level Security on all tables
3. **API Keys**: Use service role key only server-side
4. **SSL/TLS**: Enable HTTPS in production
5. **Firewall**: Restrict database port access
6. **Updates**: Regularly update all Docker images

## 🚀 Production Deployment

### 1. Use Production Configuration

```yaml
# docker-compose.prod.yml
services:
  postgres:
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - /data/postgres:/var/lib/postgresql/data
    restart: always
```

### 2. Enable SSL

Add reverse proxy with SSL:
```yaml
nginx:
  image: nginx
  volumes:
    - ./nginx.conf:/etc/nginx/nginx.conf
    - ./ssl:/etc/nginx/ssl
  ports:
    - "443:443"
```

### 3. Monitoring Stack

Add Prometheus and Grafana for monitoring.

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgREST Documentation](https://postgrest.org/)
- [Supabase GitHub](https://github.com/supabase/supabase)

## 🤝 Contributing

Contributions welcome! Please read our contributing guidelines.

## 📄 License

MIT License - see LICENSE file for details.

---

Built with ❤️ using Supabase